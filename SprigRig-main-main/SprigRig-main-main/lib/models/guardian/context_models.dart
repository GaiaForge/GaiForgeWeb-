import 'package:flutter/foundation.dart';

class FertigationSnapshot {
  final bool enabled;
  final String dosingMode; // 'auto', 'manual', 'disabled'
  final double? reservoirLiters;
  final Map<String, double>? targets; // {ph_min, ph_max, ec_min, ec_max}
  final String targetSource; // 'recipe', 'manual'
  final List<PumpConfig> pumps;
  final List<ProbeConfig> probes;
  final int dosesLastHour;
  final int maxDosesPerHour;
  final DateTime? lastDoseTime;
  final double? lastPhReading;
  final double? lastEcReading;

  FertigationSnapshot({
    required this.enabled,
    required this.dosingMode,
    this.reservoirLiters,
    this.targets,
    required this.targetSource,
    required this.pumps,
    required this.probes,
    required this.dosesLastHour,
    required this.maxDosesPerHour,
    this.lastDoseTime,
    this.lastPhReading,
    this.lastEcReading,
  });
}

class PumpConfig {
  final int id;
  final String name;
  final String pumpType; // 'ph_up', 'ph_down', 'nutrient_a', etc.
  final int relayChannel;
  final int relayModuleAddress;
  final double mlPerSecond;
  final bool enabled;

  PumpConfig({
    required this.id,
    required this.name,
    required this.pumpType,
    required this.relayChannel,
    required this.relayModuleAddress,
    required this.mlPerSecond,
    required this.enabled,
  });
}

class ProbeConfig {
  final int id;
  final String probeType; // 'ph', 'ec', 'temperature'
  final int hubAddress;
  final int inputChannel;
  final String inputType; // '4-20mA', '0-10V', 'analog'
  final double rangeMin;
  final double rangeMax;
  final double calibrationOffset;
  final double calibrationSlope;
  final bool enabled;
  final DateTime? lastReading;

  ProbeConfig({
    required this.id,
    required this.probeType,
    required this.hubAddress,
    required this.inputChannel,
    required this.inputType,
    required this.rangeMin,
    required this.rangeMax,
    required this.calibrationOffset,
    required this.calibrationSlope,
    required this.enabled,
    this.lastReading,
  });
}

class RelayModule {
  final int address; // I2C address
  final String name;
  final int channelCount;
  final String status; // 'online', 'offline', 'error'
  final DateTime? lastSeen;
  final List<int> activeChannels; // Currently energized

  RelayModule({
    required this.address,
    required this.name,
    required this.channelCount,
    required this.status,
    this.lastSeen,
    required this.activeChannels,
  });
}

class OutputAssignment {
  final int id;
  final int moduleAddress;
  final int channel;
  final String assignedTo; // Device name
  final String category; // 'Lighting', 'Irrigation', 'Ventilation', 'Fertigation', 'Other'
  final bool currentState; // On/Off
  final DateTime? lastStateChange;

  OutputAssignment({
    required this.id,
    required this.moduleAddress,
    required this.channel,
    required this.assignedTo,
    required this.category,
    required this.currentState,
    this.lastStateChange,
  });
}

class ActiveRecipe {
  final int recipeId;
  final String recipeName;
  final String cropType;
  final int currentPhaseId;
  final String currentPhaseName;
  final int phaseDayNumber;
  final int totalPhaseDays;
  final RecipeTargets targets;
  final RecipeTargets? nextPhaseTargets; // For upcoming transition
  final DateTime? phaseTransitionDate;

  ActiveRecipe({
    required this.recipeId,
    required this.recipeName,
    required this.cropType,
    required this.currentPhaseId,
    required this.currentPhaseName,
    required this.phaseDayNumber,
    required this.totalPhaseDays,
    required this.targets,
    this.nextPhaseTargets,
    this.phaseTransitionDate,
  });
}

class RecipeTargets {
  final double? targetTempDay;
  final double? targetTempNight;
  final double? targetHumidityDay;
  final double? targetHumidityNight;
  final double? targetVpd;
  final double? targetPhMin;
  final double? targetPhMax;
  final double? targetEcMin;
  final double? targetEcMax;
  final int? lightHoursOn;
  final Map<String, double>? nutrientRatios; // ml per liter for each type

  RecipeTargets({
    this.targetTempDay,
    this.targetTempNight,
    this.targetHumidityDay,
    this.targetHumidityNight,
    this.targetVpd,
    this.targetPhMin,
    this.targetPhMax,
    this.targetEcMin,
    this.targetEcMax,
    this.lightHoursOn,
    this.nutrientRatios,
  });
}

class SystemState {
  final bool gpioEnabled;
  final String timezone;
  final bool rtcSynced;
  final DateTime systemTime;
  final bool esp32Connected;
  final String? esp32FirmwareVersion;
  final bool wifiConnected;
  final String? ipAddress;
  final double? cpuTemp; // If available on Pi
  final int uptimeSeconds;

  SystemState({
    required this.gpioEnabled,
    required this.timezone,
    required this.rtcSynced,
    required this.systemTime,
    required this.esp32Connected,
    this.esp32FirmwareVersion,
    required this.wifiConnected,
    this.ipAddress,
    this.cpuTemp,
    required this.uptimeSeconds,
  });
}

class IntervalSchedule {
  final int id;
  final String name;
  final String type; // 'audio', 'irrigation', 'misting', etc.
  final String startTime;
  final String endTime;
  final String scheduleType; // 'daily', 'interval', 'astral'
  final bool enabled;
  final DateTime? lastRun;
  final DateTime? nextRun;

  IntervalSchedule({
    required this.id,
    required this.name,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.scheduleType,
    required this.enabled,
    this.lastRun,
    this.nextRun,
  });
}
