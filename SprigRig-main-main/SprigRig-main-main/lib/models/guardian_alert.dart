class GuardianAlert {
  final int? id;
  final int zoneId;
  final int? reportId;
  final String severity; // 'URGENT', 'WARNING', 'INFO'
  final String category; // 'temperature', 'humidity', 'ph', 'plant_health', 'equipment', etc.
  final String title;
  final String message;
  final String? recommendation;
  final String source; // 'rule', 'pattern', 'ai'
  final bool acknowledged;
  final int? acknowledgedAt;
  final int createdAt;

  GuardianAlert({
    this.id,
    required this.zoneId,
    this.reportId,
    required this.severity,
    required this.category,
    required this.title,
    required this.message,
    this.recommendation,
    required this.source,
    this.acknowledged = false,
    this.acknowledgedAt,
    required this.createdAt,
  });

  factory GuardianAlert.fromMap(Map<String, dynamic> map) {
    return GuardianAlert(
      id: map['id'] as int?,
      zoneId: map['zone_id'] as int,
      reportId: map['report_id'] as int?,
      severity: map['severity'] as String,
      category: map['category'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      recommendation: map['recommendation'] as String?,
      source: map['source'] as String,
      acknowledged: (map['acknowledged'] as int) == 1,
      acknowledgedAt: map['acknowledged_at'] as int?,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'report_id': reportId,
      'severity': severity,
      'category': category,
      'title': title,
      'message': message,
      'recommendation': recommendation,
      'source': source,
      'acknowledged': acknowledged ? 1 : 0,
      'acknowledged_at': acknowledgedAt,
      'created_at': createdAt,
    };
  }

  GuardianAlert copyWith({
    int? id,
    int? zoneId,
    int? reportId,
    String? severity,
    String? category,
    String? title,
    String? message,
    String? recommendation,
    String? source,
    bool? acknowledged,
    int? acknowledgedAt,
    int? createdAt,
  }) {
    return GuardianAlert(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      reportId: reportId ?? this.reportId,
      severity: severity ?? this.severity,
      category: category ?? this.category,
      title: title ?? this.title,
      message: message ?? this.message,
      recommendation: recommendation ?? this.recommendation,
      source: source ?? this.source,
      acknowledged: acknowledged ?? this.acknowledged,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
