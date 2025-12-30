class GuardianBaseline {
  final int? id;
  final int zoneId;
  final String metric; // 'temp_day', 'temp_night', 'humidity', 'ph_drift_rate', etc.
  final String context; // 'lights_on', 'lights_off', 'general'
  final double valueAvg;
  final double valueMin;
  final double valueMax;
  final double stdDev;
  final int sampleCount;
  final int lastCalculated;

  GuardianBaseline({
    this.id,
    required this.zoneId,
    required this.metric,
    required this.context,
    required this.valueAvg,
    required this.valueMin,
    required this.valueMax,
    required this.stdDev,
    required this.sampleCount,
    required this.lastCalculated,
  });

  factory GuardianBaseline.fromMap(Map<String, dynamic> map) {
    return GuardianBaseline(
      id: map['id'] as int?,
      zoneId: map['zone_id'] as int,
      metric: map['metric'] as String,
      context: map['context'] as String,
      valueAvg: map['value_avg'] as double,
      valueMin: map['value_min'] as double,
      valueMax: map['value_max'] as double,
      stdDev: map['std_dev'] as double,
      sampleCount: map['sample_count'] as int,
      lastCalculated: map['last_calculated'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'metric': metric,
      'context': context,
      'value_avg': valueAvg,
      'value_min': valueMin,
      'value_max': valueMax,
      'std_dev': stdDev,
      'sample_count': sampleCount,
      'last_calculated': lastCalculated,
    };
  }
}
