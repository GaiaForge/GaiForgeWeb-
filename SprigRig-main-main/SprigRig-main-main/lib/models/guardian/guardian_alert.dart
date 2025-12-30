class GuardianAlert {
  final int? id;
  final int zoneId;
  final String severity; // 'info', 'warning', 'critical'
  final String category;
  final String title;
  final String message;
  final String? readingType;
  final double? value;
  final bool acknowledged;
  final int? acknowledgedAt;
  final int createdAt;

  GuardianAlert({
    this.id,
    required this.zoneId,
    required this.severity,
    required this.category,
    required this.title,
    required this.message,
    this.readingType,
    this.value,
    this.acknowledged = false,
    this.acknowledgedAt,
    required this.createdAt,
  });

  factory GuardianAlert.fromMap(Map<String, dynamic> map) {
    return GuardianAlert(
      id: map['id'] as int?,
      zoneId: map['zone_id'] as int,
      severity: map['severity'] as String,
      category: map['category'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      readingType: map['reading_type'] as String?,
      value: (map['value'] as num?)?.toDouble(),
      acknowledged: (map['acknowledged'] as int) == 1,
      acknowledgedAt: map['acknowledged_at'] as int?,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'severity': severity,
      'category': category,
      'title': title,
      'message': message,
      'reading_type': readingType,
      'value': value,
      'acknowledged': acknowledged ? 1 : 0,
      'acknowledged_at': acknowledgedAt,
      'created_at': createdAt,
    };
  }

  GuardianAlert copyWith({
    int? id,
    int? zoneId,
    String? severity,
    String? category,
    String? title,
    String? message,
    String? readingType,
    double? value,
    bool? acknowledged,
    int? acknowledgedAt,
    int? createdAt,
  }) {
    return GuardianAlert(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      severity: severity ?? this.severity,
      category: category ?? this.category,
      title: title ?? this.title,
      message: message ?? this.message,
      readingType: readingType ?? this.readingType,
      value: value ?? this.value,
      acknowledged: acknowledged ?? this.acknowledged,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
