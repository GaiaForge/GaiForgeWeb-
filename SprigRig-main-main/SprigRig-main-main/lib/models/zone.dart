// lib/models/zone.dart
class Zone {
  final int id;
  final int? growId;
  final String name;
  final String growMethod;      // NEW: soil, hydroponic, ebb_flow, aeroponic, aeration, drip, nft
  final bool enabled;
  final String status;          // NEW: active, paused, completed
  final int dayCount;           // NEW: days since grow started
  final int? harvestEstimateDays; // NEW: estimated days to harvest
  final bool hasIrrigation;
  final bool hasLighting;       // Added back
  final String lightingMode;    // NEW: Manual, Schedule, Astral
  final bool hasHvac;
  final bool hasAeration;
  final bool hasSeedlingMat;
  final bool hasCameras;
  final bool hasFertigation;    // NEW
  final bool hasGuardian;       // NEW
  final int createdAt;
  final int updatedAt;

  Zone({
    required this.id,
    this.growId,
    required this.name,
    this.growMethod = '',
    required this.enabled,
    this.status = 'active',
    this.dayCount = 0,
    this.harvestEstimateDays,
    this.hasIrrigation = false,
    this.hasLighting = false,
    this.lightingMode = 'Manual',
    this.hasHvac = false,
    this.hasAeration = false,
    this.hasSeedlingMat = false,
    this.hasCameras = false,
    this.hasFertigation = false,
    this.hasGuardian = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Zone.fromMap(Map<String, dynamic> map) {
    return Zone(
      id: map['id'] as int,
      growId: map['grow_id'] as int?,
      name: map['name'] as String,
      growMethod: map['grow_method'] as String? ?? '',
      enabled: (map['enabled'] as int) == 1,
      status: map['status'] as String? ?? 'active',
      dayCount: map['day_count'] as int? ?? 0,
      harvestEstimateDays: map['harvest_estimate_days'] as int?,
      hasIrrigation: (map['has_irrigation'] as int? ?? 0) == 1,
      hasLighting: (map['has_lighting'] as int? ?? 0) == 1,
      lightingMode: map['lighting_mode'] as String? ?? 'Manual',
      hasHvac: (map['has_hvac'] as int? ?? map['has_ventilation'] as int? ?? 0) == 1,
      hasAeration: (map['has_aeration'] as int? ?? 0) == 1,
      hasSeedlingMat: (map['has_seedling_mat'] as int? ?? 0) == 1,
      hasCameras: (map['has_cameras'] as int? ?? 0) == 1,
      hasFertigation: (map['has_fertigation'] as int? ?? 0) == 1,
      hasGuardian: (map['has_guardian'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'grow_id': growId,
      'name': name,
      'grow_method': growMethod,
      'enabled': enabled ? 1 : 0,
      'status': status,
      'day_count': dayCount,
      'harvest_estimate_days': harvestEstimateDays,
      'has_irrigation': hasIrrigation ? 1 : 0,
      'has_lighting': hasLighting ? 1 : 0,
      'lighting_mode': lightingMode,
      'has_hvac': hasHvac ? 1 : 0,
      'has_aeration': hasAeration ? 1 : 0,
      'has_seedling_mat': hasSeedlingMat ? 1 : 0,
      'has_cameras': hasCameras ? 1 : 0,
      'has_fertigation': hasFertigation ? 1 : 0,
      'has_guardian': hasGuardian ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Helper method to get days remaining until harvest
  int? get daysToHarvest {
    if (harvestEstimateDays == null) return null;
    final remaining = harvestEstimateDays! - dayCount;
    return remaining > 0 ? remaining : 0;
  }

  // Helper method to get harvest progress percentage
  double? get harvestProgress {
    if (harvestEstimateDays == null || harvestEstimateDays == 0) return null;
    final progress = (dayCount / harvestEstimateDays!).clamp(0.0, 1.0);
    return progress;
  }

  // Copy with method for easy updates
  Zone copyWith({
    int? id,
    int? growId,
    String? name,
    String? growMethod,
    bool? enabled,
    String? status,
    int? dayCount,
    int? harvestEstimateDays,
    bool? hasIrrigation,
    bool? hasLighting,
    bool? hasHvac,
    bool? hasAeration,
    bool? hasCameras,
    bool? hasFertigation,
    bool? hasGuardian,
    int? createdAt,
    int? updatedAt,
  }) {
    return Zone(
      id: id ?? this.id,
      growId: growId ?? this.growId,
      name: name ?? this.name,
      growMethod: growMethod ?? this.growMethod,
      enabled: enabled ?? this.enabled,
      status: status ?? this.status,
      dayCount: dayCount ?? this.dayCount,
      harvestEstimateDays: harvestEstimateDays ?? this.harvestEstimateDays,
      hasIrrigation: hasIrrigation ?? this.hasIrrigation,
      hasLighting: hasLighting ?? this.hasLighting,
      hasHvac: hasHvac ?? this.hasHvac,
      hasAeration: hasAeration ?? this.hasAeration,
      hasCameras: hasCameras ?? this.hasCameras,
      hasFertigation: hasFertigation ?? this.hasFertigation,
      hasGuardian: hasGuardian ?? this.hasGuardian,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ZoneControlSummary {
  final int id;
  final String name;
  final String type;
  final bool enabled;

  ZoneControlSummary({
    required this.id,
    required this.name,
    required this.type,
    required this.enabled,
  });

  factory ZoneControlSummary.fromMap(Map<String, dynamic> map) {
    return ZoneControlSummary(
      id: map['id'] as int,
      name: map['name'] as String,
      type: map['type'] as String,
      enabled: (map['enabled'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'enabled': enabled ? 1 : 0,
    };
  }
}