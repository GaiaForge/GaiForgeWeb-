// lib/services/env_control_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/environmental_control.dart';
import '../models/aeration_schedule.dart';
// import '../models/lighting_schedule.dart'; // Unused
import '../models/astral_simulation_settings.dart';
import '../services/astral_simulation_service.dart';
import '../services/database_helper.dart';
import '../services/hardware_service.dart';
import '../services/astral_service.dart';

/// Environmental Control Service manages automated environmental controls
/// based on schedules, sensor readings, and astral events
class EnvironmentalControlService {
  static EnvironmentalControlService? _instance;
  static EnvironmentalControlService get instance =>
      _instance ??= EnvironmentalControlService._internal();

  EnvironmentalControlService._internal();

  // Services
  final DatabaseHelper _db = DatabaseHelper();
  final HardwareService _hardware = HardwareService.instance;
  final AstralService _astral = AstralService.instance;
  
  // Constants
  static const Duration _sensorLogInterval = Duration(minutes: 5);

  // State
  final Map<int, Timer> _scheduleTimers = {};
  final Map<int, Timer> _sensorTimers = {};
  Timer? _sensorLogTimer;
  bool _isInitialized = false;

  // Active state tracking
  final _activeControlsController = StreamController<Map<int, bool>>.broadcast();
  final Map<int, bool> _activeControls = {};

  /// Stream of active control states (controlId -> isActive)
  Stream<Map<int, bool>> get activeControlsStream => _activeControlsController.stream;

  /// Check if a specific control is currently active
  bool isControlActive(int controlId) => _activeControls[controlId] ?? false;

  /// Initialize the environmental control service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Start schedule monitoring
      await _startScheduleMonitoring();

      // Start sensor-based control monitoring
      await _startSensorMonitoring();

      // Start sensor logging
      _startSensorLogging();

      // Start aeration monitoring (Integrated into schedule monitoring)
      // await _startAerationMonitoring();

      _isInitialized = true;
      debugPrint('EnvironmentalControlService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing EnvironmentalControlService: $e');
      rethrow;
    }
  }

  /// Dispose the environmental control service
  void dispose() {
    // Cancel all timers
    for (final timer in _scheduleTimers.values) {
      timer.cancel();
    }
    for (final timer in _sensorTimers.values) {
      timer.cancel();
    }
    _scheduleTimers.clear();
    _sensorTimers.clear();
    _sensorLogTimer?.cancel();
    _activeControlsController.close();
    _isInitialized = false;
  }

  /// Manually control an environmental device
  Future<void> setControl(int controlId, bool state) async {
    try {
      await _hardware.setEnvironmentalControl(controlId, state);
      await _db.toggleZoneControl(controlId, state);
      
      // Update active state and notify listeners
      _activeControls[controlId] = state;
      _activeControlsController.add(Map.from(_activeControls));
      
      debugPrint('Environmental control $controlId set to $state');
    } catch (e) {
      throw Exception('Failed to set control $controlId: $e');
    }
  }

  /// Set PWM value for a control (dimming, speed, etc.)
  Future<void> setPwmValue(int controlId, String function, int value) async {
    try {
      await _hardware.setPwmValue(controlId, function, value);
      debugPrint('PWM value set for control $controlId ($function): $value');
    } catch (e) {
      throw Exception('Failed to set PWM value for control $controlId: $e');
    }
  }

  /// Get all environmental controls for a zone
  Future<List<EnvironmentalControl>> getZoneControls(int zoneId) async {
    return await _db.getZoneControls(zoneId);
  }

  /// Create a new environmental control
  Future<int> createControl(int zoneId, int controlTypeId, String name) async {
    return await _db.createZoneControl(zoneId, controlTypeId, name);
  }

  /// Update control settings
  Future<void> updateControlSetting(
    int controlId,
    String settingName,
    String value, {
    String? unit,
  }) async {
    await _db.updateControlSetting(controlId, settingName, value, unit: unit);
  }

  /// Get control settings
  Future<List<ControlSetting>> getControlSettings(int controlId) async {
    return await _db.getControlSettings(controlId);
  }

  /// Start monitoring schedules for all controls
  Future<void> _startScheduleMonitoring() async {
    try {
      // Get all zones
      final zones = await _db.getZones();

      for (final zone in zones) {
        if (!zone.enabled) continue;

        // Get controls for this zone
        final controls = await getZoneControls(zone.id);
        
        // Get zone-wide lighting schedules
        final lightingSchedules = await _db.getLightingSchedules(zone.id);

        for (final control in controls) {
          if (!control.enabled) continue;

          // Get schedules for this control
          final schedules = await _db.getControlSchedules(control.id);
          
          // If this is a light (Control Type 1), also check zone lighting schedules
          if (control.controlTypeId == 1) { // 1 = Grow Light
             for (final lightSchedule in lightingSchedules) {
               if (!lightSchedule.isEnabled) continue;
               
               // Convert LightingSchedule to ControlSchedule for processing
               // Note: LightingSchedule uses TimeOfDay, ControlSchedule uses "HH:MM" string
               final convertedSchedule = ControlSchedule(
                 id: -1, // Temporary ID
                 zoneControlId: control.id,
                 scheduleType: 'time', // Lighting schedules are time-based
                 startTime: '${lightSchedule.startTime.hour.toString().padLeft(2, '0')}:${lightSchedule.startTime.minute.toString().padLeft(2, '0')}',
                 endTime: '${lightSchedule.endTime.hour.toString().padLeft(2, '0')}:${lightSchedule.endTime.minute.toString().padLeft(2, '0')}',
                 daysOfWeek: lightSchedule.days.toString(), // Needs parsing in check logic if used, but currently checkTimeSchedule doesn't use daysOfWeek?
                 // Actually, checkTimeSchedule DOES NOT check days of week yet. 
                 // But let's map it anyway.
                 enabled: true,
                 createdAt: 0,
                 updatedAt: 0,
               );
               
               // Add to list of schedules to process
               schedules.add(convertedSchedule);
             }
          }

          // Check Aeration Schedules
          final aerationSchedules = await _db.getAerationSchedules(zone.id);
          for (final aerMap in aerationSchedules) {
            final aerSchedule = AerationSchedule.fromMap(aerMap);
            if (!aerSchedule.enabled) continue;
            
            if (aerSchedule.pumpId == control.id) {
               // Calculate end time from duration (seconds)
               final startParts = aerSchedule.startTime.split(':');
               final startH = int.parse(startParts[0]);
               final startM = int.parse(startParts[1]);
               final startDt = DateTime(2024, 1, 1, startH, startM);
               final endDt = startDt.add(Duration(seconds: aerSchedule.durationSeconds));
               
               final convertedSchedule = ControlSchedule(
                 id: -100 - int.parse(aerSchedule.id.hashCode.toString().substring(0, 5)), // Temp ID
                 zoneControlId: control.id,
                 scheduleType: 'time',
                 startTime: aerSchedule.startTime,
                 endTime: '${endDt.hour.toString().padLeft(2, '0')}:${endDt.minute.toString().padLeft(2, '0')}',
                 daysOfWeek: aerSchedule.days.toString(),
                 enabled: true,
                 createdAt: 0,
                 updatedAt: 0,
               );
               schedules.add(convertedSchedule);
            }
          }

          for (final schedule in schedules) {
            if (!schedule.enabled) continue;

            // Start monitoring this schedule
            await _startScheduleTimer(control, schedule);
          }
        }
      }
    } catch (e) {
      debugPrint('Error starting schedule monitoring: $e');
    }
  }

  /// Start a timer for a specific schedule
  Future<void> _startScheduleTimer(
    EnvironmentalControl control,
    ControlSchedule schedule,
  ) async {
    try {
      // Cancel existing timer
      _scheduleTimers[schedule.id]?.cancel();

      // Run immediately to check state
      await _processSchedule(control, schedule);

      // Then run periodically
      final scheduleTimer = Timer.periodic(const Duration(minutes: 1), (
        timer,
      ) async {
        await _processSchedule(control, schedule);
        
        // Also check astral lighting if this is a grow light
        if (control.controlTypeId == 1) {
          await _checkAstralLighting(control.zoneId);
        }
      });

      _scheduleTimers[schedule.id] = scheduleTimer;
    } catch (e) {
      debugPrint('Error starting schedule timer: $e');
    }
  }

  /// Process a single schedule check
  Future<void> _processSchedule(
    EnvironmentalControl control,
    ControlSchedule schedule,
  ) async {
    try {
      debugPrint('Processing schedule ${schedule.id} type=${schedule.scheduleType} for control ${control.name}');
      final shouldBeActive = await _checkScheduleCondition(schedule);
      final isCurrentlyActive = isControlActive(control.id);

      if (shouldBeActive && !isCurrentlyActive) {
        debugPrint(
          'Schedule ${schedule.id} activating control ${control.id} (${control.name})',
        );
        await setControl(control.id, true);
      } else if (!shouldBeActive && isCurrentlyActive) {
        debugPrint('Schedule ${schedule.id} condition not met. Checking other schedules...');
        // Check if any OTHER schedule wants this control to be active before turning it off
        // This prevents fighting between overlapping schedules
        final allSchedules = await _db.getControlSchedules(control.id);
        bool anyOtherActive = false;
        
        for (final otherSchedule in allSchedules) {
          if (otherSchedule.id == schedule.id) continue;
          if (!otherSchedule.enabled) continue;
          
          if (await _checkScheduleCondition(otherSchedule)) {
            anyOtherActive = true;
            break;
          }
        }

        if (!anyOtherActive) {
           debugPrint(
            'Schedule ${schedule.id} deactivating control ${control.id} (${control.name})',
          );
          await setControl(control.id, false);
        }
      }
    } catch (e) {
      debugPrint('Error processing schedule ${schedule.id}: $e');
    }
  }

  /// Check if a schedule condition is met
  Future<bool> _checkScheduleCondition(ControlSchedule schedule) async {
    final now = DateTime.now();

    switch (schedule.scheduleType) {
      case 'time':
        return _checkTimeSchedule(schedule, now);

      case 'astral':
        return await _checkAstralSchedule(schedule, now);

      case 'sensor':
        return await _checkSensorSchedule(schedule);

      case 'interval':
        return _checkIntervalSchedule(schedule, now);

      default:
        return false;
    }
  }

  /// Check time-based schedule
  bool _checkTimeSchedule(ControlSchedule schedule, DateTime now) {
    if (schedule.startTime == null) return false;

    try {
      // Parse Start Time
      final startParts = schedule.startTime!.split(':');
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      
      var startTime = DateTime(
        now.year,
        now.month,
        now.day,
        startHour,
        startMinute,
      );

      // Determine End Time
      DateTime endTime;
      if (schedule.endTime != null) {
        final endParts = schedule.endTime!.split(':');
        final endHour = int.parse(endParts[0]);
        final endMinute = int.parse(endParts[1]);
        endTime = DateTime(
          now.year,
          now.month,
          now.day,
          endHour,
          endMinute,
        );
      } else if (schedule.durationMinutes != null) {
        endTime = startTime.add(Duration(minutes: schedule.durationMinutes!));
      } else {
        // No end time or duration? Default to 1 minute trigger (legacy behavior)
        // But for "interval" logic, this usually means configuration error.
        // We'll treat it as a 1-minute trigger.
        final diff = now.difference(startTime).inMinutes.abs();
        return diff <= 1;
      }

      // Handle overnight schedules (e.g. 22:00 to 06:00)
      if (endTime.isBefore(startTime)) {
        // If now is after start (e.g. 23:00), end is tomorrow
        // If now is before end (e.g. 05:00), start was yesterday
        if (now.isAfter(startTime) || now.isAtSameMomentAs(startTime)) {
           endTime = endTime.add(const Duration(days: 1));
        } else if (now.isBefore(endTime)) {
           startTime = startTime.subtract(const Duration(days: 1));
        } else {
           // Not in the window (e.g. 12:00) - but we need to check if we are "between" the overnight span
           // Actually, the above logic covers it.
           // If 22:00 -> 06:00.
           // Now = 12:00. 
           // 12:00 is NOT after 22:00. 
           // 12:00 is NOT before 06:00.
           // So we treat start/end as today's values.
           // 22:00 today -> 06:00 today (which is backwards).
           // So we need to normalize.
           endTime = endTime.add(const Duration(days: 1)); 
        }
      }

      // Check if now is within the window
      final isActive = (now.isAfter(startTime) || now.isAtSameMomentAs(startTime)) && 
             now.isBefore(endTime);
      
      if (isActive) {
        debugPrint('Time Schedule MATCH: Now ($now) is between $startTime and $endTime');
      }
      
      return isActive;

    } catch (e) {
      debugPrint('Error parsing schedule time: $e');
      return false;
    }
  }

  /// Check astral-based schedule (sunrise/sunset)
  Future<bool> _checkAstralSchedule(
    ControlSchedule schedule,
    DateTime now,
  ) async {
    if (schedule.astralEvent == null) return false;

    try {
      final today = DateTime(now.year, now.month, now.day);
      final astralTime =
          schedule.astralEvent == 'sunrise'
              ? await _astral.getSunriseForDate(today)
              : await _astral.getSunsetForDate(today);

      // Apply offset if specified
      final adjustedTime = astralTime.add(
        Duration(minutes: schedule.offsetMinutes ?? 0),
      );

      // Check if we're within the astral time window (within 1 minute)
      final diff = now.difference(adjustedTime).inMinutes.abs();
      return diff <= 1;
    } catch (e) {
      debugPrint('Error checking astral schedule: $e');
      return false;
    }
  }

  /// Check sensor-based schedule
  Future<bool> _checkSensorSchedule(ControlSchedule schedule) async {
    if (schedule.triggerThreshold == null) return false;

    try {
      // This would need more implementation based on specific sensor requirements
      // For now, return false
      return false;
    } catch (e) {
      debugPrint('Error checking sensor schedule: $e');
      return false;
    }
  }

  /// Check interval-based schedule
  /// Check interval-based schedule
  bool _checkIntervalSchedule(ControlSchedule schedule, DateTime now) {
    if (schedule.intervalMinutes == null || 
        schedule.durationMinutes == null || 
        schedule.startTime == null) {
      return false;
    }

    try {
      final startParts = schedule.startTime!.split(':');
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      
      // Anchor to today's start time
      final anchor = DateTime(now.year, now.month, now.day, startHour, startMinute);
      
      // Calculate total minutes elapsed since anchor
      int elapsed = now.difference(anchor).inMinutes;
      
      // If now is before anchor (e.g. now 7am, start 8am), we treat it as part of previous day's cycle
      // assuming the schedule runs daily.
      if (elapsed < 0) {
         elapsed += 24 * 60; // Add 24 hours
      }
      
      final cycle = schedule.intervalMinutes!;
      if (cycle <= 0) return false;
      
      final position = elapsed % cycle;
      
      final isActive = position < schedule.durationMinutes!;
      
      if (isActive) {
        debugPrint('Interval Schedule MATCH: Position $position in cycle $cycle (Duration: ${schedule.durationMinutes})');
      }
      
      return isActive;
    } catch (e) {
      debugPrint('Error checking interval schedule: $e');
      return false;
    }
  }

  /// Start sensor monitoring for threshold-based controls
  Future<void> _startSensorMonitoring() async {
    try {
      // Get all zones
      final zones = await _db.getZones();

      for (final zone in zones) {
        if (!zone.enabled) continue;

        // Get sensors for this zone
        final sensors = await _db.getZoneSensors(zone.id);

        if (sensors.isNotEmpty) {
          // Start sensor monitoring timer for this zone
          _sensorTimers[zone.id] = Timer.periodic(
            const Duration(minutes: 5),
            (timer) => _checkSensorThresholds(zone.id),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting sensor monitoring: $e');
    }
  }

  /// Check sensor thresholds for a zone
  Future<void> _checkAstralLighting(int zoneId) async {
    final settings = await _db.getAstralSimulationSettings(zoneId);
    if (settings == null || !settings.enabled) return;
    
    final schedule = AstralSimulationService.instance.getTodaySchedule(settings);
    final now = TimeOfDay.now();
    
    final nowMinutes = now.hour * 60 + now.minute;
    final onMinutes = schedule.lightsOn.hour * 60 + schedule.lightsOn.minute;
    final offMinutes = schedule.lightsOff.hour * 60 + schedule.lightsOff.minute;
    
    bool isLightTime;
    if (onMinutes < offMinutes) {
      isLightTime = nowMinutes >= onMinutes && nowMinutes < offMinutes;
    } else {
      isLightTime = nowMinutes >= onMinutes || nowMinutes < offMinutes;
    }
    
    // Update state
    await _setLightingState(zoneId, isLightTime);
    
    // Handle intensity if enabled
    if (settings.useIntensityCurve) {
      final intensity = _calculateDawnDuskIntensity(now, schedule, settings);
      // Assuming we have a method to set intensity, otherwise this is a placeholder
      // await _setLightingIntensity(zoneId, intensity);
      debugPrint('Astral Intensity: $intensity');
    }
  }

  double _calculateDawnDuskIntensity(TimeOfDay now, AstralLightingSchedule schedule, AstralSimulationSettings settings) {
    final nowMinutes = now.hour * 60 + now.minute;
    final onMinutes = schedule.lightsOn.hour * 60 + schedule.lightsOn.minute;
    final offMinutes = schedule.lightsOff.hour * 60 + schedule.lightsOff.minute;
    
    final dawnEnd = onMinutes + settings.dawnDurationMinutes;
    final duskStart = offMinutes - settings.duskDurationMinutes;
    
    if (nowMinutes >= onMinutes && nowMinutes < dawnEnd) {
      return (nowMinutes - onMinutes) / settings.dawnDurationMinutes;
    } else if (nowMinutes >= duskStart && nowMinutes < offMinutes) {
      return 1.0 - ((nowMinutes - duskStart) / settings.duskDurationMinutes);
    } else if (nowMinutes >= dawnEnd && nowMinutes < duskStart) {
      return 1.0;
    }
    return 0.0;
  }
  Future<void> _checkSensorThresholds(int zoneId) async {
    try {
      // Get controls with sensor-based schedules
      final controls = await getZoneControls(zoneId);

      for (final control in controls) {
        if (!control.enabled) continue;

        final schedules = await _db.getControlSchedules(control.id);
        final sensorSchedules = schedules.where(
          (s) => s.scheduleType == 'sensor' && s.enabled,
        );

        for (final schedule in sensorSchedules) {
          final shouldActivate = await _checkSensorSchedule(schedule);
          if (shouldActivate) {
            await setControl(control.id, true);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking sensor thresholds for zone $zoneId: $e');
    }
  }


  /// Set lighting state for a zone
  Future<void> _setLightingState(int zoneId, bool state) async {
    try {
      final controls = await getZoneControls(zoneId);
      final lights = controls.where((c) => c.controlTypeId == 1); // 1 = Grow Light
      
      for (final light in lights) {
        if (!light.enabled) continue;
        
        // Only change if state is different to avoid spamming hardware
        if (isControlActive(light.id) != state) {
          await setControl(light.id, state);
        }
      }
    } catch (e) {
      debugPrint('Error setting lighting state for zone $zoneId: $e');
    }
  }

  /// Set lighting intensity for a zone
  Future<void> _setLightingIntensity(int zoneId, double intensity) async {
    try {
      final controls = await getZoneControls(zoneId);
      final lights = controls.where((c) => c.controlTypeId == 1); // 1 = Grow Light
      
      // Convert 0.0-1.0 to 0-255 or 0-100 based on hardware
      // Assuming 0-100 for now as it's common for dimmers
      final pwmValue = (intensity * 100).round();
      
      for (final light in lights) {
        if (!light.enabled) continue;
        
        // Only set if light is on
        if (isControlActive(light.id)) {
          await setPwmValue(light.id, 'dimmer', pwmValue);
        }
      }
    } catch (e) {
      debugPrint('Error setting lighting intensity for zone $zoneId: $e');
    }
  }

  /// Start sensor data logging
  void _startSensorLogging() {
    _sensorLogTimer?.cancel();
    _sensorLogTimer = Timer.periodic(_sensorLogInterval, (timer) async {
      await _logAllSensors();
    });
  }

  /// Log data from all enabled sensors
  Future<void> _logAllSensors() async {
    try {
      final zones = await _db.getZones();
      for (final zone in zones) {
        if (!zone.enabled) continue;

        final sensors = await _db.getZoneSensors(zone.id);
        for (final sensor in sensors) {
          if (!sensor.enabled) continue;

          // In a real implementation, we would read from hardware
          // For now, we simulate readings or read from last known state
          // This is a placeholder for actual hardware reading logic
          try {
            // Simulate reading based on sensor type
            // double value = 0.0;
            // TODO: Replace with actual hardware reading
            // value = await _hardware.readSensor(sensor.id); 
            
            // Log the reading
            // await _db.logSensorReading(sensor.id, sensor.sensorType, value);
          } catch (e) {
            debugPrint('Error reading/logging sensor ${sensor.name}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error in sensor logging loop: $e');
    }
  }
}
