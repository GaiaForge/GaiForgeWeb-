import 'package:flutter/material.dart';

class IrrigationSchedule {
  final String id;
  final String name;
  final TimeOfDay startTime;
  final Duration duration;
  final List<bool> days; // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
  final int? pumpId;
  final bool isEnabled;

  IrrigationSchedule({
    required this.id,
    required this.name,
    required this.startTime,
    required this.duration,
    required this.days,
    this.pumpId,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap(int zoneId) {
    return {
      'id': id,
      'zone_id': zoneId,
      'name': name,
      'start_time': '${startTime.hour}:${startTime.minute}',
      'duration_seconds': duration.inSeconds,
      'days_json': days.toString(), // Simple string representation for now, or use jsonEncode
      'pump_id': pumpId,
      'is_enabled': isEnabled ? 1 : 0,
    };
  }

  factory IrrigationSchedule.fromMap(Map<String, dynamic> map) {
    final timeParts = (map['start_time'] as String).split(':');
    final daysString = map['days_json'] as String;
    // Parse simple list string "[true, false, ...]"
    final daysList = daysString
        .substring(1, daysString.length - 1)
        .split(', ')
        .map((e) => e == 'true')
        .toList();

    return IrrigationSchedule(
      id: map['id'],
      name: map['name'],
      startTime: TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1])),
      duration: Duration(seconds: map['duration_seconds']),
      days: daysList,
      pumpId: map['pump_id'] as int?,
      isEnabled: map['is_enabled'] == null ? true : (map['is_enabled'] as int) == 1,
    );
  }
}
