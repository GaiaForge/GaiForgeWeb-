import 'dart:convert';

class AerationSchedule {
  final String id;
  final int zoneId;
  final String name;
  final String startTime;
  final int durationSeconds;
  final List<int> days;
  final int? pumpId;
  final bool enabled;

  AerationSchedule({
    required this.id,
    required this.zoneId,
    required this.name,
    required this.startTime,
    required this.durationSeconds,
    required this.days,
    this.pumpId,
    this.enabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'name': name,
      'start_time': startTime,
      'duration_seconds': durationSeconds,
      'days_json': jsonEncode(days),
      'pump_id': pumpId,
      'is_enabled': enabled ? 1 : 0,
    };
  }

  factory AerationSchedule.fromMap(Map<String, dynamic> map) {
    return AerationSchedule(
      id: map['id'],
      zoneId: map['zone_id'],
      name: map['name'],
      startTime: map['start_time'],
      durationSeconds: map['duration_seconds'],
      days: List<int>.from(jsonDecode(map['days_json'])),
      pumpId: map['pump_id'],
      enabled: (map['is_enabled'] ?? 1) == 1,
    );
  }
}
