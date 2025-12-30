class FertigationReading {
  final int? id;
  final int zoneId;
  final int probeId;
  final double value;
  final double? temperature;
  final int timestamp;

  FertigationReading({
    this.id,
    required this.zoneId,
    required this.probeId,
    required this.value,
    this.temperature,
    required this.timestamp,
  });

  factory FertigationReading.fromMap(Map<String, dynamic> map) {
    return FertigationReading(
      id: map['id'] as int?,
      zoneId: map['zone_id'] as int,
      probeId: map['probe_id'] as int,
      value: map['value'] as double,
      temperature: map['temperature'] as double?,
      timestamp: map['timestamp'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'probe_id': probeId,
      'value': value,
      'temperature': temperature,
      'timestamp': timestamp,
    };
  }
}
