import 'guardian_alert.dart';

class GuardianStatus {
  final String overallStatus; // 'healthy', 'warning', 'critical'
  final double confidence;
  final String summary;
  final Map<String, ConditionStatus> conditions;
  final Map<String, String> trends; // 'rising', 'falling', 'stable'
  final List<GuardianAlert> alerts;
  final List<Recommendation> recommendations;
  final DateTime lastAnalysis;
  final DateTime? lastVisionAnalysis;

  GuardianStatus({
    required this.overallStatus,
    required this.confidence,
    required this.summary,
    required this.conditions,
    required this.trends,
    required this.alerts,
    required this.recommendations,
    required this.lastAnalysis,
    this.lastVisionAnalysis,
  });

  factory GuardianStatus.fromJson(Map<String, dynamic> json) {
    return GuardianStatus(
      overallStatus: json['overall_status'] ?? 'unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      summary: json['summary'] ?? '',
      conditions: (json['conditions'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, ConditionStatus.fromJson(v)),
          ) ?? {},
      trends: (json['trends'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ?? {},
      alerts: (json['alerts'] as List<dynamic>?)
              ?.map((a) => GuardianAlert.fromMap(a))
              .toList() ?? [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((r) => Recommendation.fromJson(r))
              .toList() ?? [],
      lastAnalysis: DateTime.parse(json['last_analysis']),
      lastVisionAnalysis: json['last_vision_analysis'] != null
          ? DateTime.parse(json['last_vision_analysis'])
          : null,
    );
  }
}

class ConditionStatus {
  final String status; // 'optimal', 'high', 'low'
  final String? note;

  ConditionStatus({required this.status, this.note});

  factory ConditionStatus.fromJson(Map<String, dynamic> json) {
    return ConditionStatus(
      status: json['status'] ?? 'unknown',
      note: json['note'],
    );
  }
}

class Recommendation {
  final int priority; // 1-3
  final String action;
  final String reason;

  Recommendation({
    required this.priority,
    required this.action,
    required this.reason,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      priority: json['priority'] as int? ?? 3,
      action: json['action'] ?? '',
      reason: json['reason'] ?? '',
    );
  }
}
