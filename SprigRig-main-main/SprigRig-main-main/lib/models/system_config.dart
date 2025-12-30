// lib/models/system_config.dart
class SystemConfig {
  final int? id;
  final String systemType;
  final String facilityScale;
  final int zoneCount;
  final String? zones;
  final String? hardwareRequirements;
  final int createdAt;
  final int updatedAt;

  SystemConfig({
    this.id,
    required this.systemType,
    required this.facilityScale,
    required this.zoneCount,
    this.zones,
    this.hardwareRequirements,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SystemConfig.fromMap(Map<String, dynamic> map) {
    return SystemConfig(
      id: map['id'] as int?,
      systemType: map['system_type'] as String,
      facilityScale: map['facility_scale'] as String,
      zoneCount: map['zone_count'] as int,
      zones: map['zones'] as String?,
      hardwareRequirements: map['hardware_requirements'] as String?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'system_type': systemType,
      'facility_scale': facilityScale,
      'zone_count': zoneCount,
      'zones': zones,
      'hardware_requirements': hardwareRequirements,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
