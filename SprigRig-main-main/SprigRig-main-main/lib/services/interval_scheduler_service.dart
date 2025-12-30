import 'dart:async';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'modbus_service.dart';
import '../models/lighting_schedule.dart';
import '../models/irrigation_schedule.dart';
import '../models/hvac_schedule.dart'; // Ventilation
import '../models/environmental_control.dart';

class ScheduledEvent {
  final DateTime time;
  final int relayIndex;
  final bool turnOn;
  final String scheduleName;

  ScheduledEvent({
    required this.time,
    required this.relayIndex,
    required this.turnOn,
    required this.scheduleName,
  });
}

class IntervalSchedulerService {
  static final IntervalSchedulerService _instance = IntervalSchedulerService._internal();
  factory IntervalSchedulerService() => _instance;

  IntervalSchedulerService._internal();

  final DatabaseHelper _db = DatabaseHelper();
  final ModbusService _modbus = ModbusService();
  Timer? _eventTimer;
  Timer? _safetyPollTimer;
  bool _isRunning = false;
  ScheduledEvent? _nextEvent;

  // Cache to prevent spamming Modbus with same state
  final Map<int, bool> _lastKnownRelayState = {};

  Future<void> initialize() async {
    debugPrint('IntervalSchedulerService: Starting initialization...');
    try {
      if (_isRunning) {
        debugPrint('IntervalSchedulerService: Already running');
        return;
      }
      _isRunning = true;

      debugPrint('IntervalSchedulerService: Initialized successfully');

      // Initial full check and schedule next event
      await _fullStateCheck();
      await _scheduleNextEvent();

      // Safety poll every 5 minutes
      _safetyPollTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        debugPrint('IntervalSchedulerService: Running safety poll...');
        _fullStateCheck();
        // Also recalculate next event to be safe against drift
        _scheduleNextEvent();
      });

    } catch (e, stackTrace) {
      debugPrint('IntervalSchedulerService: Failed to initialize: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void stop() {
    _eventTimer?.cancel();
    _safetyPollTimer?.cancel();
    _isRunning = false;
  }

  // Public method to be called when schedules change
  Future<void> recalculate() async {
    debugPrint('IntervalSchedulerService: Recalculating events due to schedule change...');
    // Force an immediate check of the current state to ensure relays update instantly
    await _fullStateCheck();
    // Then schedule the next future event
    await _scheduleNextEvent();
  }

  Future<void> _scheduleNextEvent() async {
    _eventTimer?.cancel();
    _nextEvent = await _calculateNextEvent();

    if (_nextEvent != null) {
      final now = DateTime.now();
      final duration = _nextEvent!.time.difference(now);
      
      if (duration.isNegative) {
        // Event is in the past (shouldn't happen with correct logic, but handle it)
        debugPrint('IntervalSchedulerService: Found past event, executing immediately');
        _executeEvent(_nextEvent!);
      } else {
        debugPrint('IntervalSchedulerService: Next event in ${duration.inMinutes}m ${duration.inSeconds % 60}s - "${_nextEvent!.scheduleName}" ${_nextEvent!.turnOn ? "ON" : "OFF"} at ${_nextEvent!.time}');
        _eventTimer = Timer(duration, () => _executeEvent(_nextEvent!));
      }
    } else {
      debugPrint('IntervalSchedulerService: No upcoming events found');
    }
  }

  Future<void> _executeEvent(ScheduledEvent event) async {
    debugPrint('IntervalSchedulerService: Executing - "${event.scheduleName}" Relay ${event.relayIndex} ${event.turnOn ? "ON" : "OFF"}');
    
    if (event.turnOn) {
      // For ON, we can generally just enforce it (OR logic)
      await _enforceRelayState(event.relayIndex, true);
    } else {
      // For OFF, we must check if any OTHER schedule keeps it ON
      // A simple way is to re-run the check for this specific relay/zone
      // For now, running a full check is safest and simplest to ensure consistency
      // Optimization: We could have a _checkRelay(index) method
      await _fullStateCheck(); 
    }

    // Schedule the next one
    await _scheduleNextEvent();
  }

  Future<ScheduledEvent?> _calculateNextEvent() async {
    ScheduledEvent? earliestEvent;

    try {
      final zones = await _db.getZones();
      for (var zone in zones) {
        if (zone.id == null) continue;

        // 1. Lighting
        final lightingSchedules = await _db.getLightingSchedules(zone.id!);
        final lightControls = await _db.getZoneControls(zone.id!);
        final lights = lightControls.where((c) => c.controlTypeId == 1 || c.controlTypeId == 2).toList();

        for (var light in lights) {
          final assignments = await _db.getControlIoAssignments(light.id);
          if (assignments.isEmpty) continue;
          final assignment = assignments.first;
          final channel = await _db.getIoChannelById(assignment.ioChannelId);
          if (channel == null || channel.moduleNumber != 100) continue;

          for (var schedule in lightingSchedules) {
            if (!schedule.isEnabled) continue;
            _updateEarliestEvent(
              currentEarliest: earliestEvent,
              candidate: _getNextScheduleEvents(schedule.startTime, schedule.endTime, schedule.days, channel.channelNumber, schedule.name),
              onUpdate: (e) => earliestEvent = e
            );
          }
        }

        // 2. Irrigation
        final irrigationSchedules = await _db.getIrrigationSchedules(zone.id!);
        for (var schedule in irrigationSchedules) {
          if (!schedule.isEnabled || schedule.pumpId == null) continue;
          final channel = await _db.getIoChannelById(schedule.pumpId!);
          if (channel == null || channel.moduleNumber != 100) continue;

          // Calculate end time from duration
          // Note: Duration is in minutes in model? Model says 'duration' (int minutes) or Duration object?
          // Looking at model: 'final Duration duration;'
          // And helper _isTimeInDuration uses start + duration.
          // We need to handle the end time calculation carefully.
          
          // For the event calculation, we treat it as start and end times.
          // But end time depends on the specific start instance.
          // _getNextScheduleEvents needs to handle duration-based end times.
          
          _updateEarliestEvent(
             currentEarliest: earliestEvent,
             candidate: _getNextIrrigationEvents(schedule, channel.channelNumber),
             onUpdate: (e) => earliestEvent = e
          );
        }

        // 3. Ventilation
        final ventSchedules = await _db.getVentilationSchedules(zone.id!);
        final fanControls = await _db.getZoneControls(zone.id!);
        final fans = fanControls.where((c) => c.controlTypeId == 3 || c.controlTypeId == 4).toList();
        
        for (var fan in fans) {
          final assignments = await _db.getControlIoAssignments(fan.id);
          if (assignments.isEmpty) continue;
          final assignment = assignments.first;
          final channel = await _db.getIoChannelById(assignment.ioChannelId);
          if (channel == null || channel.moduleNumber != 100) continue;

          for (var schedule in ventSchedules) {
            if (!schedule.isEnabled) continue;
             _updateEarliestEvent(
              currentEarliest: earliestEvent,
              candidate: _getNextScheduleEvents(schedule.startTime, schedule.endTime, schedule.days, channel.channelNumber, schedule.name),
              onUpdate: (e) => earliestEvent = e
            );
          }
        }
      }
    } catch (e) {
      debugPrint('IntervalSchedulerService Error calculating next event: $e');
    }

    return earliestEvent;
  }

  void _updateEarliestEvent({
    required ScheduledEvent? currentEarliest,
    required ScheduledEvent? candidate,
    required Function(ScheduledEvent) onUpdate,
  }) {
    if (candidate == null) return;
    if (currentEarliest == null || candidate.time.isBefore(currentEarliest.time)) {
      onUpdate(candidate);
    }
  }

  ScheduledEvent? _getNextScheduleEvents(TimeOfDay start, TimeOfDay end, List<bool> days, int relayIndex, String name) {
    // Find next Start
    final nextStart = _getNextOccurrence(start, days);
    
    // Find next End
    // For end time, we need to be careful about overnight schedules.
    // If overnight, the end day is the day AFTER the start day.
    // But we are looking for the absolute next end event from NOW.
    // So we check if we are currently in a window, or if the next window is coming up.
    
    // Simplified: Find next occurrence of End time, respecting the day logic.
    // If overnight (end < start), the end day is (valid start day) + 1.
    // If normal, end day is (valid start day).
    
    final nextEnd = _getNextEndOccurrence(start, end, days);

    // Return the earliest of the two
    if (nextStart.isBefore(nextEnd)) {
      return ScheduledEvent(time: nextStart, relayIndex: relayIndex, turnOn: true, scheduleName: name);
    } else {
      return ScheduledEvent(time: nextEnd, relayIndex: relayIndex, turnOn: false, scheduleName: name);
    }
  }

  ScheduledEvent? _getNextIrrigationEvents(IrrigationSchedule schedule, int relayIndex) {
    final nextStart = _getNextOccurrence(schedule.startTime, schedule.days);
    
    // End time is strictly tied to start time + duration
    // But we might be IN the duration right now.
    // If we are in duration, next event is End.
    // If we are before start, next event is Start.
    
    // Let's check if we are currently running
    if (_isTimeInDuration(schedule.startTime, schedule.duration, schedule.days)) {
       // We are running. Find the end time of THIS run.
       // This run started today (or yesterday if overnight duration).
       // Assuming simplistic daily duration for now.
       final now = DateTime.now();
       final todayStart = DateTime(now.year, now.month, now.day, schedule.startTime.hour, schedule.startTime.minute);
       // If todayStart is in future, it must have started yesterday? 
       // _isTimeInDuration handles the logic.
       
       // Let's just calculate the specific end time for the current active run.
       // If now > todayStart, it started today. End is todayStart + duration.
       // If now < todayStart, it started yesterday. End is yesterdayStart + duration.
       
       DateTime runStart = todayStart;
       if (now.isBefore(todayStart)) {
         runStart = todayStart.subtract(const Duration(days: 1));
       }
       
       final runEnd = runStart.add(schedule.duration);
       if (runEnd.isAfter(now)) {
         return ScheduledEvent(time: runEnd, relayIndex: relayIndex, turnOn: false, scheduleName: schedule.name);
       }
    }
    
    // Not currently running, or end time passed.
    // Next event is the next Start.
    // Note: We also need to schedule the End corresponding to that Start?
    // No, _calculateNextEvent will be called again after Start fires.
    return ScheduledEvent(time: nextStart, relayIndex: relayIndex, turnOn: true, scheduleName: schedule.name);
  }

  DateTime _getNextOccurrence(TimeOfDay time, List<bool> days) {
    final now = DateTime.now();
    var d = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    
    // If time has passed for today, start checking from tomorrow
    if (d.isBefore(now)) {
      d = d.add(const Duration(days: 1));
    }

    // Look ahead up to 8 days to find enabled day
    for (int i = 0; i < 8; i++) {
      if (days[d.weekday - 1]) {
        return d;
      }
      d = d.add(const Duration(days: 1));
    }
    return d; // Should be found
  }

  DateTime _getNextEndOccurrence(TimeOfDay start, TimeOfDay end, List<bool> days) {
    final now = DateTime.now();
    final isOvernight = (end.hour * 60 + end.minute) < (start.hour * 60 + start.minute);
    
    var d = DateTime(now.year, now.month, now.day, end.hour, end.minute);
    
    // We need to find the first valid END time that is in the future.
    // An end time is valid if it corresponds to a valid start day.
    // If not overnight: valid end day = valid start day.
    // If overnight: valid end day = valid start day + 1.

    // Check today
    if (d.isAfter(now)) {
       // Is today a valid end day?
       // If not overnight, today must be in days.
       // If overnight, yesterday must be in days.
       bool isValid = false;
       if (!isOvernight) {
         isValid = days[d.weekday - 1];
       } else {
         final yesterday = d.subtract(const Duration(days: 1));
         isValid = days[yesterday.weekday - 1];
       }
       
       if (isValid) return d;
    }

    // Check future days
    // Start from tomorrow (or today if we didn't check it above? logic simplifies if we just loop)
    // Let's loop days.
    
    var checkDate = DateTime(now.year, now.month, now.day);
    // If the end time on checkDate is already past, move to next day
    if (DateTime(checkDate.year, checkDate.month, checkDate.day, end.hour, end.minute).isBefore(now)) {
      checkDate = checkDate.add(const Duration(days: 1));
    }

    for (int i = 0; i < 8; i++) {
      final potentialEnd = DateTime(checkDate.year, checkDate.month, checkDate.day, end.hour, end.minute);
      
      bool isValid = false;
      if (!isOvernight) {
        isValid = days[potentialEnd.weekday - 1];
      } else {
        final startDay = potentialEnd.subtract(const Duration(days: 1));
        isValid = days[startDay.weekday - 1];
      }

      if (isValid) return potentialEnd;
      
      checkDate = checkDate.add(const Duration(days: 1));
    }
    
    return checkDate; // Fallback
  }

  // Renamed from _checkSchedules to _fullStateCheck for clarity
  Future<void> _fullStateCheck() async {
    // debugPrint('IntervalSchedulerService: Performing full state check...');
    try {
      final zones = await _db.getZones();
      for (var zone in zones) {
        if (zone.id == null) continue;
        await _checkLighting(zone.id!);
        await _checkIrrigation(zone.id!);
        await _checkVentilation(zone.id!);
      }
    } catch (e, stackTrace) {
      debugPrint('IntervalSchedulerService Error in _fullStateCheck: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _checkLighting(int zoneId) async {
    // 1. Get Schedules
    final schedules = await _db.getLightingSchedules(zoneId);
    if (schedules.isEmpty) return;

    // 2. Get Controls (Lights)
    final controls = await _db.getZoneControls(zoneId);
    final lights = controls.where((c) => c.controlTypeId == 1 || c.controlTypeId == 2).toList(); 

    if (lights.isEmpty) return;

    for (var light in lights) {
      // 3. Get Assignment
      final assignments = await _db.getControlIoAssignments(light.id);
      if (assignments.isEmpty) continue;

      final assignment = assignments.first;
      final channel = await _db.getIoChannelById(assignment.ioChannelId);
      if (channel == null || channel.moduleNumber != 100) continue;

      bool shouldBeOn = false;
      
      // 4. Check Schedules
      for (var schedule in schedules) {
        if (!schedule.isEnabled) continue;
        if (_isTimeInWindow(schedule.startTime, schedule.endTime, schedule.days)) {
          shouldBeOn = true;
          break; 
        }
      }

      // 5. Enforce State
      await _enforceRelayState(channel.channelNumber, shouldBeOn);
    }
  }

  Future<void> _checkIrrigation(int zoneId) async {
    final schedules = await _db.getIrrigationSchedules(zoneId);
    
    for (var schedule in schedules) {
      if (!schedule.isEnabled || schedule.pumpId == null) continue;

      final channel = await _db.getIoChannelById(schedule.pumpId!);
      if (channel == null || channel.moduleNumber != 100) continue;

      bool shouldBeOn = _isTimeInDuration(schedule.startTime, schedule.duration, schedule.days);
      await _enforceRelayState(channel.channelNumber, shouldBeOn);
    }
  }

  Future<void> _checkVentilation(int zoneId) async {
    final schedules = await _db.getVentilationSchedules(zoneId);
    final controls = await _db.getZoneControls(zoneId);
    final fans = controls.where((c) => c.controlTypeId == 3 || c.controlTypeId == 4).toList(); 

    if (fans.isEmpty) return;

    bool zoneFanShouldBeOn = false;
    for (var schedule in schedules) {
      if (!schedule.isEnabled) continue;
      if (_isTimeInWindow(schedule.startTime, schedule.endTime, schedule.days)) {
        zoneFanShouldBeOn = true;
        break;
      }
    }

    for (var fan in fans) {
      final assignments = await _db.getControlIoAssignments(fan.id);
      if (assignments.isEmpty) continue;
      final assignment = assignments.first;
      final channel = await _db.getIoChannelById(assignment.ioChannelId);
      if (channel != null && channel.moduleNumber == 100) {
        await _enforceRelayState(channel.channelNumber, zoneFanShouldBeOn);
      }
    }
  }

  Future<void> _enforceRelayState(int relayIndex, bool shouldBeOn) async {
    // Only send command if state changed to reduce bus traffic
    if (_lastKnownRelayState[relayIndex] != shouldBeOn) {
      debugPrint('Scheduler: Enforcing Relay $relayIndex to $shouldBeOn (Previous: ${_lastKnownRelayState[relayIndex]})');
      await _modbus.setRelay(relayIndex, shouldBeOn);
      _lastKnownRelayState[relayIndex] = shouldBeOn;
    }
  }

  bool _isTimeInWindow(TimeOfDay start, TimeOfDay end, List<bool> days) {
    final now = DateTime.now();
    
    // Check Day
    // For overnight schedules, we need to check if we are in the "start day" window or "end day" window.
    // But simpler: 
    // If normal window: must be today and in time.
    // If overnight window: 
    //   If time > start: must be start day.
    //   If time < end: must be (start day + 1).
    
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes < endMinutes) {
      // Normal window
      if (!days[now.weekday - 1]) return false;
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      // Overnight window
      // Example: 22:00 to 06:00.
      // If now is 23:00. Start day must be enabled.
      // If now is 05:00. Previous day must be enabled.
      
      if (nowMinutes >= startMinutes) {
        // We are in the late night part. Today must be enabled.
        return days[now.weekday - 1];
      } else if (nowMinutes < endMinutes) {
        // We are in the early morning part. Yesterday must be enabled.
        final yesterday = now.subtract(const Duration(days: 1));
        return days[yesterday.weekday - 1];
      }
      return false;
    }
  }

  bool _isTimeInDuration(TimeOfDay start, Duration duration, List<bool> days) {
    final now = DateTime.now();
    // Similar logic to window, but we calculate end time
    // Duration could be long, but assuming < 24h for now
    
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = startMinutes + duration.inMinutes;
    final nowMinutes = now.hour * 60 + now.minute;
    
    // Convert to absolute minutes from start of week? No, too complex.
    // Use the same logic:
    // If duration doesn't cross midnight:
    if (endMinutes < 24 * 60) {
       if (!days[now.weekday - 1]) return false;
       return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
       // Crosses midnight
       final midnightCrossEnd = endMinutes - 24 * 60;
       
       if (nowMinutes >= startMinutes) {
         return days[now.weekday - 1];
       } else if (nowMinutes < midnightCrossEnd) {
         final yesterday = now.subtract(const Duration(days: 1));
         return days[yesterday.weekday - 1];
       }
       return false;
    }
  }
  /// Check if lights are currently ON for a specific zone
  Future<bool> isLightOnForZone(int zoneId) async {
    try {
      final schedules = await _db.getLightingSchedules(zoneId);
      if (schedules.isEmpty) return false;

      // Check if any schedule is currently active
      for (var schedule in schedules) {
        if (!schedule.isEnabled) continue;
        if (_isTimeInWindow(schedule.startTime, schedule.endTime, schedule.days)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error checking light status for zone $zoneId: $e');
      return false;
    }
  }
}
