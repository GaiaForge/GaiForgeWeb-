class FertigationDoseLog {
  final int? id;
  final int zoneId;
  final int pumpId;
  final double doseMl;
  final double durationSeconds;
  final String trigger; // 'auto_ph', 'auto_ec', 'manual', 'schedule'
  final double? readingBefore;
  final double? readingAfter;
  final int timestamp;

  FertigationDoseLog({
    this.id,
    required this.zoneId,
    required this.pumpId,
    required this.doseMl,
    required this.durationSeconds,
    required this.trigger,
    this.readingBefore,
    this.readingAfter,
    required this.timestamp,
  });

  factory FertigationDoseLog.fromMap(Map<String, dynamic> map) {
    return FertigationDoseLog(
      id: map['id'] as int?,
      zoneId: map['zone_id'] as int,
      pumpId: map['pump_id'] as int,
      doseMl: map['dose_ml'] as double,
      durationSeconds: map['duration_seconds'] as double,
      trigger: map['trigger'] as String,
      readingBefore: map['reading_before'] as double?,
      readingAfter: map['reading_after'] as double?,
      timestamp: map['timestamp'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'pump_id': pumpId,
      'dose_ml': doseMl,
      'duration_seconds': durationSeconds,
      'trigger': trigger,
      'reading_before': readingBefore,
      'reading_after': readingAfter,
      'timestamp': timestamp,
    };
  }
}
