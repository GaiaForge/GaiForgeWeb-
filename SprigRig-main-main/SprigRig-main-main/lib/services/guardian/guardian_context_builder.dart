import 'dart:math';
import '../database_helper.dart';
import '../../models/sensor.dart';
import '../../models/guardian/guardian_context.dart';
import '../../models/guardian/context_models.dart';
import '../../models/recipe_phase.dart';
import '../../models/irrigation_schedule.dart';
import '../../models/sensor_calibration.dart';
import '../../models/guardian/guardian_alert.dart';
import '../../services/secure_storage_service.dart';

class GuardianContextBuilder {
  final int zoneId;
  final DatabaseHelper _db = DatabaseHelper();

  GuardianContextBuilder(this.zoneId);

  Future<GuardianContext> build({int historyHours = 24}) async {
    final zone = await _db.getZone(zoneId);
    if (zone == null) throw Exception('Zone not found');

    // Get active crop and phase
    final crop = await _db.getActiveCropForZone(zoneId);
    RecipePhase? phase;
    if (crop != null && crop['current_phase_id'] != null) {
      // Assuming getRecipePhase exists or similar
      // phase = await _db.getRecipePhase(crop['current_phase_id']);
    }

    // Get sensors
    final sensors = await _db.getSensorsForZone(zoneId);
    
    final Map<String, double> currentReadings = {};
    final Map<String, List<SensorReading>> sensorHistory = {};
    final Map<String, SensorStatistics> statistics = {};
    final Map<int, SensorHealth> sensorHealth = {};

    final cutoff = DateTime.now().subtract(Duration(hours: historyHours));
    final cutoffEpoch = cutoff.millisecondsSinceEpoch ~/ 1000;

    for (var sensor in sensors) {
      // Check health
      // This is a simplified check. Real check would look at last reading time.
      sensorHealth[sensor.id] = SensorHealth(
        sensorName: sensor.name,
        status: 'online', // Placeholder
        minutesSinceSeen: 0, // Placeholder
      );

      // Get readings
      final supportedTypes = sensor.getSupportedReadingTypes();
      for (var type in supportedTypes) {
        // Latest reading
        final latest = await _db.getLatestSensorReading(sensor.id, type);
        if (latest != null) {
          currentReadings[type] = latest.value;
        }

        // History
        final history = await _db.getSensorReadings(
          sensor.id,
          type,
          startTime: cutoffEpoch,
        );
        sensorHistory[type] = history;

        // Statistics
        if (history.isNotEmpty) {
          final values = history.map((r) => r.value).toList();
          statistics[type] = _calculateStatistics(values);
        }
      }
    }

    // Calculate VPD if possible
    if (currentReadings.containsKey('temperature') && currentReadings.containsKey('humidity')) {
      currentReadings['vpd'] = _calculateVPD(
        currentReadings['temperature']!,
        currentReadings['humidity']!,
      );
    }

    // --- NEW DATA FETCHING ---

    // Fertigation
    final fertConfig = await _db.getFertigationConfig(zoneId);
    final pumpsData = await _db.getFertigationPumps(zoneId);
    final probesData = await _db.getFertigationProbes(zoneId);
    final recentDosesData = await _db.getRecentDoses(zoneId);
    final dosesLastHour = await _db.getDoseCountLastHour(zoneId);

    final fertigationSnapshot = FertigationSnapshot(
      enabled: fertConfig?.enabled ?? false,
      dosingMode: fertConfig?.dosingMode ?? 'manual',
      reservoirLiters: fertConfig?.reservoirLiters,
      targets: {
        'ph_min': fertConfig?.manualPhMin ?? 5.5,
        'ph_max': fertConfig?.manualPhMax ?? 6.5,
        'ec_min': fertConfig?.manualEcMin ?? 1.0,
        'ec_max': fertConfig?.manualEcMax ?? 2.0,
      },
      targetSource: fertConfig?.useRecipeTargets == true ? 'recipe' : 'manual',
      pumps: pumpsData.map((p) => PumpConfig(
        id: p.id!,
        name: p.name,
        pumpType: p.pumpType,
        relayChannel: p.relayChannel!,
        relayModuleAddress: p.relayModuleAddress!,
        mlPerSecond: p.mlPerSecond,
        enabled: p.enabled,
      )).toList(),
      probes: probesData.map((p) => ProbeConfig(
        id: p.id!,
        probeType: p.probeType,
        hubAddress: p.hubAddress,
        inputChannel: p.inputChannel,
        inputType: p.inputType,
        rangeMin: p.rangeMin,
        rangeMax: p.rangeMax,
        calibrationOffset: p.calibrationOffset,
        calibrationSlope: p.calibrationSlope,
        enabled: p.enabled,
      )).toList(),
      dosesLastHour: dosesLastHour,
      maxDosesPerHour: fertConfig?.maxDosesPerHour ?? 0,
      lastDoseTime: recentDosesData.isNotEmpty 
        ? DateTime.fromMillisecondsSinceEpoch((recentDosesData.first['timestamp'] as int) * 1000) 
        : null,
      lastPhReading: currentReadings['ph'],
      lastEcReading: currentReadings['ec'],
    );

    // Relay Topology & Outputs
    final relayModulesData = await _db.getRelayModules();
    final relayModules = relayModulesData.map((m) => RelayModule(
      address: m['module_number'],
      name: 'Relay Board ${m['module_number']}', // Placeholder name
      channelCount: 8, // Placeholder
      status: 'online', // Placeholder
      activeChannels: [], // Placeholder
    )).toList();

    final outputsData = await _db.getAllOutputAssignments(zoneId);
    final outputs = outputsData.map((o) => OutputAssignment(
      id: o['id'],
      moduleAddress: o['module_number'],
      channel: o['channel_number'],
      assignedTo: o['assigned_to'],
      category: o['category'],
      currentState: o['current_state'] == 1,
    )).toList();

    // Schedules
    final intervalsData = await _db.getIntervalSchedules(zoneId);
    final intervals = intervalsData.map((s) => IntervalSchedule(
      id: s['id'],
      name: s['name'],
      type: s['type'],
      startTime: s['start_time'],
      endTime: s['end_time'],
      scheduleType: s['schedule_type'],
      enabled: s['enabled'] == 1,
    )).toList();

    final irrigationData = await _db.getIrrigationSchedules(zoneId);
    final irrigationSchedules = irrigationData;

    // Active Recipe
    final activeRecipe = _buildActiveRecipe(crop);

    // Calibrations
    final Map<int, SensorCalibration> calibrations = {};
    for (var sensor in sensors) {
      final sensorCals = await _db.getSensorCalibrations(sensor.id);
      if (sensorCals.isNotEmpty) {
        calibrations[sensor.id] = sensorCals.first;
      }
    }

    // System State
    final systemState = SystemState(
      gpioEnabled: true, // Placeholder
      timezone: 'UTC', // Placeholder
      rtcSynced: true, // Placeholder
      systemTime: DateTime.now(),
      esp32Connected: true, // Placeholder
      wifiConnected: true, // Placeholder
      uptimeSeconds: 3600, // Placeholder
    );

    // History
    final alertHistoryData = await _db.getAlertHistory(zoneId);
    // Need to map to GuardianAlert objects, assuming fromMap exists or manual mapping
    // For now using empty list as placeholder if mapping is complex, or implementing simple map
    final alertHistory = alertHistoryData.map((a) => GuardianAlert.fromMap(a)).toList();

    // Get Configuration Data
    final ioAssignments = await _db.getZoneIoAssignments(zoneId);
    final lightingSchedules = await _db.getLightingSchedules(zoneId);
    final systemSettings = await _db.getAllSettings();
    final config = await _db.getGuardianConfig(zoneId);
    
    // Inject Secure API Key
    Map<String, dynamic>? configMap;
    if (config != null) {
      configMap = config.toMap();
      if (config.activeKeyId != null) {
        final key = await SecureStorageService().getApiKey(config.activeKeyId!);
        if (key != null) {
          configMap['api_key'] = key;
        }
      }
    }

    // Get alerts
    // final alerts = await _db.getGuardianAlerts(zoneId, limit: 10);
    
    return GuardianContext(
      zoneId: zoneId,
      zoneName: zone.name,
      growMethod: zone.growMethod ?? 'unknown',
      cropName: crop?['crop_name'],
      growDay: _calculateGrowDay(crop),
      growPhase: phase?.phaseName,
      phaseDay: _calculatePhaseDay(crop, phase),
      currentReadings: currentReadings,
      sensorHistory: sensorHistory,
      statistics: statistics,
      lightsOn: false, // Placeholder: Need to get from LightingService
      irrigationActive: false, // Placeholder
      ventilationActive: false, // Placeholder
      recentAlerts: [], // Placeholder
      sensorHealth: sensorHealth,
      ioAssignments: ioAssignments,
      lightingSchedules: lightingSchedules.map((s) => s.toMap(zoneId)).toList(),
      
      // New Fields
      fertigation: fertigationSnapshot,
      relayModules: relayModules,
      outputs: outputs,
      intervals: intervals,
      irrigationSchedules: irrigationSchedules,
      activeRecipe: activeRecipe,
      sensorCalibrations: calibrations,
      systemState: systemState,
      alertHistory: alertHistory,
      recentDoses: recentDosesData,
      systemSettings: systemSettings,
      config: configMap,
    );
  }

  ActiveRecipe? _buildActiveRecipe(Map<String, dynamic>? crop) {
    if (crop == null) return null;
    return ActiveRecipe(
      recipeId: crop['recipe_id'] ?? 0,
      recipeName: crop['recipe_name'] ?? 'Unknown',
      cropType: crop['crop_type'] ?? 'Unknown',
      currentPhaseId: crop['current_phase_id'] ?? 0,
      currentPhaseName: 'Vegetative', // Placeholder
      phaseDayNumber: 10, // Placeholder
      totalPhaseDays: 28, // Placeholder
      targets: RecipeTargets(
        targetTempDay: 25.0,
        targetTempNight: 20.0,
        targetPhMin: 5.8,
        targetPhMax: 6.2,
      ),
    );
  }

  SensorStatistics _calculateStatistics(List<double> values) {
    if (values.isEmpty) {
      return SensorStatistics(
        mean: 0,
        min: 0,
        max: 0,
        stdDev: 0,
        trend: 'insufficient_data',
        percentInRange: 0,
      );
    }

    final mean = values.reduce((a, b) => a + b) / values.length;
    final minVal = values.reduce(min);
    final maxVal = values.reduce(max);
    
    // Std Dev
    double sumSquaredDiff = 0;
    for (var x in values) {
      sumSquaredDiff += pow(x - mean, 2);
    }
    final stdDev = sqrt(sumSquaredDiff / values.length);

    // Trend
    String trend = 'stable';
    if (values.length >= 10) {
      final quarter = values.length ~/ 4;
      final early = values.take(quarter).reduce((a, b) => a + b) / quarter;
      final late = values.skip(values.length - quarter).reduce((a, b) => a + b) / quarter;
      
      final changePercent = early != 0 ? ((late - early) / early) * 100 : 0;
      if (changePercent > 5) trend = 'rising';
      else if (changePercent < -5) trend = 'falling';
    }

    return SensorStatistics(
      mean: mean,
      min: minVal,
      max: maxVal,
      stdDev: stdDev,
      trend: trend,
      percentInRange: 100, // Placeholder: Needs targets to calculate
    );
  }

  double _calculateVPD(double temp, double humidity) {
    // SVP = 0.61078 * exp(17.27 * T / (T + 237.3))
    final svp = 0.61078 * exp((17.27 * temp) / (temp + 237.3));
    final vpd = svp * (1 - (humidity / 100));
    return double.parse(vpd.toStringAsFixed(2));
  }

  int _calculateGrowDay(Map<String, dynamic>? crop) {
    if (crop == null || crop['start_date'] == null) return 0;
    final start = DateTime.fromMillisecondsSinceEpoch((crop['start_date'] as int) * 1000);
    return DateTime.now().difference(start).inDays + 1;
  }
  
  int _calculatePhaseDay(Map<String, dynamic>? crop, RecipePhase? phase) {
    // Placeholder logic
    return 0; 
  }
}
