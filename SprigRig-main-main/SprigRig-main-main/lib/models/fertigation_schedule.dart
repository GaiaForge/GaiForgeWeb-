import 'dart:convert';

class FertigationSchedule {
  final int? id;
  final int zoneId;
  final String name;
  final String scheduleType; // 'feed', 'ph_check', 'ec_check'
  final String time; // HH:MM
  final List<int> daysOfWeek; // [0,1,2,3,4,5,6] where 0 is Sunday
  final bool enabled;

  FertigationSchedule({
    this.id,
    required this.zoneId,
    required this.name,
    required this.scheduleType,
    required this.time,
    required this.daysOfWeek,
    this.enabled = true,
  });

  factory FertigationSchedule.fromMap(Map<String, dynamic> map) {
    return FertigationSchedule(
      id: map['id'] as int?,
      zoneId: map['zone_id'] as int,
      name: map['name'] as String,
      scheduleType: map['schedule_type'] as String,
      time: map['time'] as String,
      daysOfWeek: List<int>.from(jsonDecode(map['days_of_week'] as String)),
      enabled: (map['enabled'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'name': name,
      'schedule_type': scheduleType,
      'time': time,
      'days_of_week': jsonEncode(daysOfWeek),
      'enabled': enabled ? 1 : 0,
    };
  }

  FertigationSchedule copyWith({
    int? id,
    int? zoneId,
    String? name,
    String? scheduleType,
    String? time,
    List<int>? daysOfWeek,
    bool? enabled,
  }) {
    return FertigationSchedule(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      name: name ?? this.name,
      scheduleType: scheduleType ?? this.scheduleType,
      time: time ?? this.time,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      enabled: enabled ?? this.enabled,
    );
  }
}
