import 'package:flutter/material.dart';

class HvacSchedule {
  final String id;
  final String name;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int speed;
  final List<bool> days;
  final bool isEnabled;

  HvacSchedule({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.speed,
    required this.days,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap(int zoneId) {
    return {
      'id': id,
      'zone_id': zoneId,
      'name': name,
      'start_time': '${startTime.hour}:${startTime.minute}',
      'end_time': '${endTime.hour}:${endTime.minute}',
      'speed': speed,
      'days_json': days.toString(),
      'is_enabled': isEnabled ? 1 : 0,
    };
  }

  factory HvacSchedule.fromMap(Map<String, dynamic> map) {
    final startParts = (map['start_time'] as String).split(':');
    final endParts = (map['end_time'] as String).split(':');
    final daysString = map['days_json'] as String;
    final daysList = daysString
        .substring(1, daysString.length - 1)
        .split(', ')
        .map((e) => e == 'true')
        .toList();

    return HvacSchedule(
      id: map['id'],
      name: map['name'],
      startTime: TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1])),
      endTime: TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1])),
      speed: map['speed'] as int,
      days: daysList,
      isEnabled: map['is_enabled'] == null ? true : (map['is_enabled'] as int) == 1,
    );
  }
}
