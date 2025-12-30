class FertigationConfig {
  final int? id;
  final int zoneId;
  final bool enabled;
  final double? reservoirLiters;
  final int mixingTimeSeconds;
  final int checkIntervalSeconds;
  final String dosingMode; // 'auto', 'manual', 'notify_only'
  
  // Manual Override Targets (used when no recipe or override enabled)
  final double? manualPhMin;
  final double? manualPhMax;
  final double? manualEcMin;
  final double? manualEcMax;
  
  final bool useRecipeTargets;
  final double maxDoseMl;
  final int maxDosesPerHour;
  final int createdAt;
  final int updatedAt;

  // Getters for backward compatibility if needed, or migration logic
  double get phTargetMin => manualPhMin ?? 5.8;
  double get phTargetMax => manualPhMax ?? 6.2;
  double get ecTarget => manualEcMin ?? 1.4; // Assuming min is target for now

  FertigationConfig({
    this.id,
    required this.zoneId,
    this.enabled = false,
    this.reservoirLiters,
    this.mixingTimeSeconds = 300,
    this.checkIntervalSeconds = 900,
    this.dosingMode = 'auto',
    this.manualPhMin,
    this.manualPhMax,
    this.manualEcMin,
    this.manualEcMax,
    this.useRecipeTargets = true,
    this.maxDoseMl = 50.0,
    this.maxDosesPerHour = 4,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FertigationConfig.fromMap(Map<String, dynamic> map) {
    return FertigationConfig(
      id: map['id'] as int?,
      zoneId: map['zone_id'] as int,
      enabled: (map['enabled'] as int) == 1,
      reservoirLiters: map['reservoir_liters'] as double?,
      mixingTimeSeconds: map['mixing_time_seconds'] as int? ?? 300,
      checkIntervalSeconds: map['check_interval_seconds'] as int? ?? 900,
      dosingMode: map['dosing_mode'] as String? ?? 'auto',
      manualPhMin: map['manual_ph_min'] as double?,
      manualPhMax: map['manual_ph_max'] as double?,
      manualEcMin: map['manual_ec_min'] as double?,
      manualEcMax: map['manual_ec_max'] as double?,
      // Fallback for old columns if new ones are null (during migration transition)
      // manualPhMin: map['manual_ph_min'] as double? ?? map['ph_target_min'] as double?,
      useRecipeTargets: (map['use_recipe_targets'] as int? ?? 1) == 1,
      maxDoseMl: map['max_dose_ml'] as double? ?? 50.0,
      maxDosesPerHour: map['max_doses_per_hour'] as int? ?? 4,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'enabled': enabled ? 1 : 0,
      'reservoir_liters': reservoirLiters,
      'mixing_time_seconds': mixingTimeSeconds,
      'check_interval_seconds': checkIntervalSeconds,
      'dosing_mode': dosingMode,
      'manual_ph_min': manualPhMin,
      'manual_ph_max': manualPhMax,
      'manual_ec_min': manualEcMin,
      'manual_ec_max': manualEcMax,
      'use_recipe_targets': useRecipeTargets ? 1 : 0,
      'max_dose_ml': maxDoseMl,
      'max_doses_per_hour': maxDosesPerHour,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  FertigationConfig copyWith({
    int? id,
    int? zoneId,
    bool? enabled,
    double? reservoirLiters,
    int? mixingTimeSeconds,
    int? checkIntervalSeconds,
    String? dosingMode,
    double? manualPhMin,
    double? manualPhMax,
    double? manualEcMin,
    double? manualEcMax,
    bool? useRecipeTargets,
    double? maxDoseMl,
    int? maxDosesPerHour,
    int? createdAt,
    int? updatedAt,
  }) {
    return FertigationConfig(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      enabled: enabled ?? this.enabled,
      reservoirLiters: reservoirLiters ?? this.reservoirLiters,
      mixingTimeSeconds: mixingTimeSeconds ?? this.mixingTimeSeconds,
      checkIntervalSeconds: checkIntervalSeconds ?? this.checkIntervalSeconds,
      dosingMode: dosingMode ?? this.dosingMode,
      manualPhMin: manualPhMin ?? this.manualPhMin,
      manualPhMax: manualPhMax ?? this.manualPhMax,
      manualEcMin: manualEcMin ?? this.manualEcMin,
      manualEcMax: manualEcMax ?? this.manualEcMax,
      useRecipeTargets: useRecipeTargets ?? this.useRecipeTargets,
      maxDoseMl: maxDoseMl ?? this.maxDoseMl,
      maxDosesPerHour: maxDosesPerHour ?? this.maxDosesPerHour,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
