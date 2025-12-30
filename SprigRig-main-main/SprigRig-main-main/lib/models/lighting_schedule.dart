import 'package:flutter/material.dart';

class LightingSchedule {
  final String id;
  final String name;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<bool> days;
  final bool isAstral;
  final bool isEnabled;

  LightingSchedule({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.days,
    this.isAstral = false,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap(int zoneId) {
    return {
      'id': id,
      'zone_id': zoneId,
      'name': name,
      'start_time': '${startTime.hour}:${startTime.minute}',
      'end_time': '${endTime.hour}:${endTime.minute}',
      'days_json': days.toString(),
      'is_astral': isAstral ? 1 : 0,
      'is_enabled': isEnabled ? 1 : 0,
    };
  }

  factory LightingSchedule.fromMap(Map<String, dynamic> map) {
    final startParts = (map['start_time'] as String).split(':');
    final endParts = (map['end_time'] as String).split(':');
    final daysString = map['days_json'] as String;
    final daysList = daysString
        .substring(1, daysString.length - 1)
        .split(', ')
        .map((e) => e == 'true')
        .toList();

    return LightingSchedule(
      id: map['id'],
      name: map['name'],
      startTime: TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1])),
      endTime: TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1])),
      days: daysList,
      isAstral: (map['is_astral'] as int) == 1,
      isEnabled: map['is_enabled'] == null ? true : (map['is_enabled'] as int) == 1,
    );
  }
}
