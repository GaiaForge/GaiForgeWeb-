// lib/models/grow.dart
class Grow {
  final int id;
  final int? plantId;
  final int? growModeId;
  final String name;
  final int startTime;
  final int? endTime;
  final String status;
  final String? notes;
  final int? expectedHarvestDate;
  final int createdAt;
  final int updatedAt;

  Grow({
    required this.id,
    this.plantId,
    this.growModeId,
    required this.name,
    required this.startTime,
    this.endTime,
    this.status = 'active',
    this.notes,
    this.expectedHarvestDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Grow.fromMap(Map<String, dynamic> map) {
    return Grow(
      id: map['id'] as int,
      plantId: map['plant_id'] as int?,
      growModeId: map['grow_mode_id'] as int?,
      name: map['name'] as String,
      startTime: map['start_time'] as int,
      endTime: map['end_time'] as int?,
      status: map['status'] as String? ?? 'active',
      notes: map['notes'] as String?,
      expectedHarvestDate: map['expected_harvest_date'] as int?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plant_id': plantId,
      'grow_mode_id': growModeId,
      'name': name,
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
      'notes': notes,
      'expected_harvest_date': expectedHarvestDate,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Helper methods
  DateTime get startDateTime => DateTime.fromMillisecondsSinceEpoch(startTime * 1000);
  DateTime? get endDateTime => endTime != null ? DateTime.fromMillisecondsSinceEpoch(endTime! * 1000) : null;
  DateTime? get expectedHarvestDateTime => expectedHarvestDate != null ? DateTime.fromMillisecondsSinceEpoch(expectedHarvestDate! * 1000) : null;

  int get daysSinceStart {
    final now = DateTime.now();
    return now.difference(startDateTime).inDays;
  }

  int getCurrentDay() {
  final now = DateTime.now();
  final startDate = DateTime.fromMillisecondsSinceEpoch(startTime * 1000);
  return now.difference(startDate).inDays;
}

  int? get daysToHarvest {
    if (expectedHarvestDate == null) return null;
    final now = DateTime.now();
    final harvest = expectedHarvestDateTime!;
    final days = harvest.difference(now).inDays;
    return days > 0 ? days : 0;
  }

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isPaused => status == 'paused';

  // Duration of grow in days
  int? get growDuration {
    if (endTime == null) return daysSinceStart;
    return endDateTime!.difference(startDateTime).inDays;
  }

  // Copy with method
  Grow copyWith({
    int? id,
    int? plantId,
    int? growModeId,
    String? name,
    int? startTime,
    int? endTime,
    String? status,
    String? notes,
    int? expectedHarvestDate,
    int? createdAt,
    int? updatedAt,
  }) {
    return Grow(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      growModeId: growModeId ?? this.growModeId,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      expectedHarvestDate: expectedHarvestDate ?? this.expectedHarvestDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}