// lib/models/timer.dart
class WateringTimer {
  final int id;
  final int zoneId;
  final String type;  // interval, sunrise, sunset, time, sensor_trigger
  final int? intervalHours;
  final int? offsetMinutes;
  final String? startTime;
  final int durationSeconds;
  final String? daysOfWeek;
  final bool enabled;
  final int? lastRun;
  final int? nextRun;
  final int createdAt;
  final int updatedAt;

  WateringTimer({
    required this.id,
    required this.zoneId,
    required this.type,
    this.intervalHours,
    this.offsetMinutes,
    this.startTime,
    required this.durationSeconds,
    this.daysOfWeek,
    required this.enabled,
    this.lastRun,
    this.nextRun,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WateringTimer.fromMap(Map<String, dynamic> map) {
    return WateringTimer(
      id: map['id'] as int,
      zoneId: map['zone_id'] as int,
      type: map['type'] as String,
      intervalHours: map['interval_hours'] as int?,
      offsetMinutes: map['offset_minutes'] as int?,
      startTime: map['start_time'] as String?,
      durationSeconds: map['duration_seconds'] as int,
      daysOfWeek: map['days_of_week'] as String?,
      enabled: (map['enabled'] as int) == 1,
      lastRun: map['last_run'] as int?,
      nextRun: map['next_run'] as int?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'type': type,
      'interval_hours': intervalHours,
      'offset_minutes': offsetMinutes,
      'start_time': startTime,
      'duration_seconds': durationSeconds,
      'days_of_week': daysOfWeek,
      'enabled': enabled ? 1 : 0,
      'last_run': lastRun,
      'next_run': nextRun,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Helper methods
  DateTime? get lastRunDateTime => lastRun != null ? DateTime.fromMillisecondsSinceEpoch(lastRun! * 1000) : null;
  DateTime? get nextRunDateTime => nextRun != null ? DateTime.fromMillisecondsSinceEpoch(nextRun! * 1000) : null;

  Duration get duration => Duration(seconds: durationSeconds);
  
  String get durationString {
    final duration = Duration(seconds: durationSeconds);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  String getDescription() {
    switch (type) {
      case 'interval':
        return 'Every ${intervalHours ?? 24} hours for $durationString';
      case 'sunrise':
        final offset = offsetMinutes != null && offsetMinutes! != 0 
            ? (offsetMinutes! > 0 ? ' +${offsetMinutes}min' : ' ${offsetMinutes}min')
            : '';
        return 'At sunrise$offset for $durationString';
      case 'sunset':
        final offset = offsetMinutes != null && offsetMinutes! != 0 
            ? (offsetMinutes! > 0 ? ' +${offsetMinutes}min' : ' ${offsetMinutes}min')
            : '';
        return 'At sunset$offset for $durationString';
      case 'time':
        return 'At $startTime for $durationString';
      case 'sensor_trigger':
        return 'Sensor triggered for $durationString';
      default:
        return 'Custom timer for $durationString';
    }
  }

  // Add this method to your WateringTimer class in timer.dart
  String getFormattedNextRun() {
    if (nextRun == null) return 'Not scheduled';
    
    final nextRunDate = DateTime.fromMillisecondsSinceEpoch(nextRun! * 1000);
    final now = DateTime.now();
    final difference = nextRunDate.difference(now);
    
    if (difference.isNegative) return 'Overdue';
    
    if (difference.inDays > 0) {
      return 'In ${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return 'In ${difference.inHours} hours';
    } else if (difference.inMinutes > 0) {
      return 'In ${difference.inMinutes} minutes';
    } else {
      return 'Starting soon';
    }
  }

  // Check if timer should run on a specific day
  bool shouldRunOnDay(DateTime date) {
    if (daysOfWeek == null) return true;
    
    // Parse days of week (assuming JSON array of integers where 0=Sunday, 1=Monday, etc.)
    // or comma-separated string
    final daysList = daysOfWeek!.split(',').map((e) => int.tryParse(e.trim())).where((e) => e != null).cast<int>().toList();
    
    if (daysList.isEmpty) return true;
    
    return daysList.contains(date.weekday % 7); // Convert to 0=Sunday format
  }

  bool get isAstralTimed => type == 'sunrise' || type == 'sunset';
  bool get isIntervalBased => type == 'interval';
  bool get isTimeBased => type == 'time';
  bool get isSensorTriggered => type == 'sensor_trigger';

  // Copy with method
  WateringTimer copyWith({
    int? id,
    int? zoneId,
    String? type,
    int? intervalHours,
    int? offsetMinutes,
    String? startTime,
    int? durationSeconds,
    String? daysOfWeek,
    bool? enabled,
    int? lastRun,
    int? nextRun,
    int? createdAt,
    int? updatedAt,
  }) {
    return WateringTimer(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      type: type ?? this.type,
      intervalHours: intervalHours ?? this.intervalHours,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      startTime: startTime ?? this.startTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      enabled: enabled ?? this.enabled,
      lastRun: lastRun ?? this.lastRun,
      nextRun: nextRun ?? this.nextRun,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Timer execution event for logging
class TimerEvent {
  final int timerId;
  final String eventType; // started, completed, failed, cancelled
  final int timestamp;
  final String? notes;
  final Map<String, dynamic>? metadata;

  TimerEvent({
    required this.timerId,
    required this.eventType,
    required this.timestamp,
    this.notes,
    this.metadata,
  });

  factory TimerEvent.fromMap(Map<String, dynamic> map) {
    return TimerEvent(
      timerId: map['timer_id'] as int,
      eventType: map['event_type'] as String,
      timestamp: map['timestamp'] as int,
      notes: map['notes'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timer_id': timerId,
      'event_type': eventType,
      'timestamp': timestamp,
      'notes': notes,
      'metadata': metadata,
    };
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
}