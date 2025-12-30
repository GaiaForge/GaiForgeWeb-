class FertigationProbe {
  final int? id;
  final int zoneId;
  final String probeType; // 'ph', 'ec', 'temperature'
  final int hubAddress;
  final int inputChannel;
  final String inputType; // '4-20mA', '0-10V'
  final double rangeMin;
  final double rangeMax;
  final double calibrationOffset;
  final double calibrationSlope;
  final bool enabled;
  final int createdAt;
  final int updatedAt;

  FertigationProbe({
    this.id,
    required this.zoneId,
    required this.probeType,
    required this.hubAddress,
    required this.inputChannel,
    required this.inputType,
    required this.rangeMin,
    required this.rangeMax,
    this.calibrationOffset = 0.0,
    this.calibrationSlope = 1.0,
    this.enabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FertigationProbe.fromMap(Map<String, dynamic> map) {
    return FertigationProbe(
      id: map['id'] as int?,
      zoneId: map['zone_id'] as int,
      probeType: map['probe_type'] as String,
      hubAddress: map['hub_address'] as int,
      inputChannel: map['input_channel'] as int,
      inputType: map['input_type'] as String,
      rangeMin: map['range_min'] as double,
      rangeMax: map['range_max'] as double,
      calibrationOffset: map['calibration_offset'] as double? ?? 0.0,
      calibrationSlope: map['calibration_slope'] as double? ?? 1.0,
      enabled: (map['enabled'] as int) == 1,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'probe_type': probeType,
      'hub_address': hubAddress,
      'input_channel': inputChannel,
      'input_type': inputType,
      'range_min': rangeMin,
      'range_max': rangeMax,
      'calibration_offset': calibrationOffset,
      'calibration_slope': calibrationSlope,
      'enabled': enabled ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  FertigationProbe copyWith({
    int? id,
    int? zoneId,
    String? probeType,
    int? hubAddress,
    int? inputChannel,
    String? inputType,
    double? rangeMin,
    double? rangeMax,
    double? calibrationOffset,
    double? calibrationSlope,
    bool? enabled,
    int? createdAt,
    int? updatedAt,
  }) {
    return FertigationProbe(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      probeType: probeType ?? this.probeType,
      hubAddress: hubAddress ?? this.hubAddress,
      inputChannel: inputChannel ?? this.inputChannel,
      inputType: inputType ?? this.inputType,
      rangeMin: rangeMin ?? this.rangeMin,
      rangeMax: rangeMax ?? this.rangeMax,
      calibrationOffset: calibrationOffset ?? this.calibrationOffset,
      calibrationSlope: calibrationSlope ?? this.calibrationSlope,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
