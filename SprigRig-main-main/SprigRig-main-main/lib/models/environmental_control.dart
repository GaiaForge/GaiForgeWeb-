// lib/models/environmental_control.dart
class EnvironmentalControl {
  final int id;
  final int zoneId;
  final int controlTypeId;
  final String name;
  final bool enabled;
  final String? typeName;

  EnvironmentalControl({
    required this.id,
    required this.zoneId,
    required this.controlTypeId,
    required this.name,
    required this.enabled,
    this.typeName,
  });

  factory EnvironmentalControl.fromMap(Map<String, dynamic> map) {
    return EnvironmentalControl(
      id: map['id'] as int,
      zoneId: map['zone_id'] as int,
      controlTypeId: map['control_type_id'] as int,
      name: map['name'] as String,
      enabled: (map['enabled'] as int) == 1,
      typeName: map['type_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'control_type_id': controlTypeId,
      'name': name,
      'enabled': enabled ? 1 : 0,
      'type_name': typeName,
    };
  }
}

class ControlSetting {
  final int id;
  final int zoneControlId;
  final String settingName;
  final String settingValue;
  final String? settingUnit;
  final int createdAt;
  final int updatedAt;

  ControlSetting({
    required this.id,
    required this.zoneControlId,
    required this.settingName,
    required this.settingValue,
    this.settingUnit,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ControlSetting.fromMap(Map<String, dynamic> map) {
    return ControlSetting(
      id: map['id'] as int,
      zoneControlId: map['zone_control_id'] as int,
      settingName: map['setting_name'] as String,
      settingValue: map['setting_value'] as String,
      settingUnit: map['setting_unit'] as String?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_control_id': zoneControlId,
      'setting_name': settingName,
      'setting_value': settingValue,
      'setting_unit': settingUnit,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class ControlSchedule {
  final int id;
  final int zoneControlId;
  final String scheduleType;
  final String? startTime;
  final String? endTime;
  final String? daysOfWeek;
  final String? astralEvent;
  final int? offsetMinutes;
  final double? triggerThreshold;
  final int? intervalMinutes;
  final int? durationMinutes;
  final bool enabled;
  final int createdAt;
  final int updatedAt;

  ControlSchedule({
    required this.id,
    required this.zoneControlId,
    required this.scheduleType,
    this.startTime,
    this.endTime,
    this.daysOfWeek,
    this.astralEvent,
    this.offsetMinutes,
    this.triggerThreshold,
    this.intervalMinutes,
    this.durationMinutes,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ControlSchedule.fromMap(Map<String, dynamic> map) {
    return ControlSchedule(
      id: map['id'] as int,
      zoneControlId: map['zone_control_id'] as int,
      scheduleType: map['schedule_type'] as String,
      startTime: map['start_time'] as String?,
      endTime: map['end_time'] as String?,
      daysOfWeek: map['days_of_week'] as String?,
      astralEvent: map['astral_event'] as String?,
      offsetMinutes: map['offset_minutes'] as int?,
      triggerThreshold: (map['trigger_threshold'] as num?)?.toDouble(),
      intervalMinutes: map['interval_minutes'] as int?,
      durationMinutes: map['duration_minutes'] as int?,
      enabled: (map['enabled'] as int) == 1,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_control_id': zoneControlId,
      'schedule_type': scheduleType,
      'start_time': startTime,
      'end_time': endTime,
      'days_of_week': daysOfWeek,
      'astral_event': astralEvent,
      'offset_minutes': offsetMinutes,
      'trigger_threshold': triggerThreshold,
      'interval_minutes': intervalMinutes,
      'duration_minutes': durationMinutes,
      'enabled': enabled ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
