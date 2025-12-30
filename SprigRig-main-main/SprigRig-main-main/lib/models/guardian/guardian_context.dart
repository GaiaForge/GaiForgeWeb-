import '../sensor.dart';
import '../irrigation_schedule.dart';
import '../sensor_calibration.dart';
import 'guardian_alert.dart';
import 'context_models.dart';

class GuardianContext {
  final int zoneId;
  final String zoneName;
  final String growMethod;
  final String? cropName;
  final int growDay;
  final String? growPhase;
  final int phaseDay;
  final DateTime? expectedHarvestDate;
  
  // Targets (simplified for now, ideally use RecipeTargets model)
  final Map<String, dynamic>? targets;
  
  final Map<String, double> currentReadings;
  final Map<String, List<SensorReading>> sensorHistory;
  final Map<String, SensorStatistics> statistics;
  
  final bool lightsOn;
  final bool irrigationActive;
  final bool ventilationActive;
  
  final Map<String, dynamic>? fertigationStatus; // Placeholder for now
  
  final List<GuardianAlert> recentAlerts;
  final Map<int, SensorHealth> sensorHealth;

  // Legacy fields (kept for compatibility, but populated from new models where possible)
  final List<Map<String, dynamic>> ioAssignments;
  final List<Map<String, dynamic>> lightingSchedules;
  final Map<String, dynamic>? config;

  // --- NEW FIELDS ---
  
  // Fertigation System
  final FertigationSnapshot? fertigation;

  // Relay/IO Topology  
  final List<RelayModule> relayModules;
  final List<OutputAssignment> outputs;

  // Schedules & Automation
  final List<IntervalSchedule> intervals;
  final List<IrrigationSchedule> irrigationSchedules;

  // Recipe & Targets
  final ActiveRecipe? activeRecipe;

  // Calibration Data
  final Map<int, SensorCalibration> sensorCalibrations;

  // System State
  final SystemState? systemState;

  // Historical Context
  final List<GuardianAlert> alertHistory; // Last 7 days, resolved included
  final List<Map<String, dynamic>> recentDoses; // Last 48 hours
  final Map<String, dynamic> systemSettings; // Global settings

  GuardianContext({
    required this.zoneId,
    required this.zoneName,
    required this.growMethod,
    this.cropName,
    required this.growDay,
    this.growPhase,
    required this.phaseDay,
    this.expectedHarvestDate,
    this.targets,
    required this.currentReadings,
    required this.sensorHistory,
    required this.statistics,
    required this.lightsOn,
    required this.irrigationActive,
    required this.ventilationActive,
    this.fertigationStatus,
    required this.recentAlerts,
    required this.sensorHealth,
    this.ioAssignments = const [],
    this.lightingSchedules = const [],
    this.config,
    this.fertigation,
    this.relayModules = const [],
    this.outputs = const [],
    this.intervals = const [],
    this.irrigationSchedules = const [],
    this.activeRecipe,
    this.sensorCalibrations = const {},
    this.systemState,
    this.alertHistory = const [],
    this.recentDoses = const [],
    this.systemSettings = const {},
  });
}

class SensorStatistics {
  final double mean;
  final double min;
  final double max;
  final double stdDev;
  final String trend; // 'rising', 'falling', 'stable', 'insufficient_data'
  final double percentInRange;

  SensorStatistics({
    required this.mean,
    required this.min,
    required this.max,
    required this.stdDev,
    required this.trend,
    required this.percentInRange,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'mean': mean,
      'min': min,
      'max': max,
      'std_dev': stdDev,
      'trend': trend,
      'percent_in_range': percentInRange,
    };
  }
}

class SensorHealth {
  final String sensorName;
  final String status; // 'online', 'offline', 'error'
  final int minutesSinceSeen;

  SensorHealth({
    required this.sensorName,
    required this.status,
    required this.minutesSinceSeen,
  });
}
