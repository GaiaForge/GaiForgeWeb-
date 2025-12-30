class IrrigationSettings {
  final int zoneId;
  final String mode; // 'Fixed Interval' or 'Astral'
  final String syncMode; // 'sunrise', 'sunset', 'moon'
  final int sunriseOffset;
  final int sunsetOffset;
  final double? targetWaterLevel; // For Hydroponic: 0.0 - 100.0
  final int? refillPumpId; // For Hydroponic: ID of the pump to use for refilling

  IrrigationSettings({
    required this.zoneId,
    required this.mode,
    required this.syncMode,
    required this.sunriseOffset,
    required this.sunsetOffset,
    this.targetWaterLevel,
    this.refillPumpId,
  });

  factory IrrigationSettings.fromMap(Map<String, dynamic> map) {
    return IrrigationSettings(
      zoneId: map['zone_id'] as int,
      mode: map['mode'] as String,
      syncMode: map['sync_mode'] as String,
      sunriseOffset: map['sunrise_offset'] as int,
      sunsetOffset: map['sunset_offset'] as int,
      targetWaterLevel: map['target_water_level'] as double?,
      refillPumpId: map['refill_pump_id'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'zone_id': zoneId,
      'mode': mode,
      'sync_mode': syncMode,
      'sunrise_offset': sunriseOffset,
      'sunset_offset': sunsetOffset,
      'target_water_level': targetWaterLevel,
      'refill_pump_id': refillPumpId,
    };
  }
}
