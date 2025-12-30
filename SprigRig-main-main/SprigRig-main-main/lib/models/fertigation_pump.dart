class FertigationPump {
  final int? id;
  final int zoneId;
  final String name;
  final String pumpType; // 'ph_up', 'ph_down', 'nutrient_a', 'nutrient_b', 'calmag', 'other'
  final int relayChannel;
  final int relayModuleAddress;
  final double mlPerSecond;
  final bool enabled;
  final int createdAt;
  final int updatedAt;

  FertigationPump({
    this.id,
    required this.zoneId,
    required this.name,
    required this.pumpType,
    required this.relayChannel,
    required this.relayModuleAddress,
    required this.mlPerSecond,
    this.enabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FertigationPump.fromMap(Map<String, dynamic> map) {
    return FertigationPump(
      id: map['id'] as int?,
      zoneId: map['zone_id'] as int,
      name: map['name'] as String,
      pumpType: map['pump_type'] as String,
      relayChannel: map['relay_channel'] as int,
      relayModuleAddress: map['relay_module_address'] as int,
      mlPerSecond: map['ml_per_second'] as double,
      enabled: (map['enabled'] as int) == 1,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'name': name,
      'pump_type': pumpType,
      'relay_channel': relayChannel,
      'relay_module_address': relayModuleAddress,
      'ml_per_second': mlPerSecond,
      'enabled': enabled ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  FertigationPump copyWith({
    int? id,
    int? zoneId,
    String? name,
    String? pumpType,
    int? relayChannel,
    int? relayModuleAddress,
    double? mlPerSecond,
    bool? enabled,
    int? createdAt,
    int? updatedAt,
  }) {
    return FertigationPump(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      name: name ?? this.name,
      pumpType: pumpType ?? this.pumpType,
      relayChannel: relayChannel ?? this.relayChannel,
      relayModuleAddress: relayModuleAddress ?? this.relayModuleAddress,
      mlPerSecond: mlPerSecond ?? this.mlPerSecond,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
