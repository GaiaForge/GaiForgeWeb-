import 'dart:convert';

class GuardianReport {
  final int? id;
  final int zoneId;
  final String reportType; // 'quick', 'hourly', 'daily', 'weekly', 'on_demand', 'ask'
  final String alertsJson; // JSON array of alerts
  final String? plantHealth;
  final String? environmentSummary;
  final String? recipeCompliance;
  final String? recommendations;
  final String? watching;
  final String? fullResponse;
  final int? growId;
  final int? growDay;
  final int? recipeId;
  final String? recipePhase;
  final String? imageIds; // JSON array of image IDs
  final int? promptTokens;
  final int? completionTokens;
  final double? costCents;
  final int createdAt;

  GuardianReport({
    this.id,
    required this.zoneId,
    required this.reportType,
    this.alertsJson = '[]',
    this.plantHealth,
    this.environmentSummary,
    this.recipeCompliance,
    this.recommendations,
    this.watching,
    this.fullResponse,
    this.growId,
    this.growDay,
    this.recipeId,
    this.recipePhase,
    this.imageIds,
    this.promptTokens,
    this.completionTokens,
    this.costCents,
    required this.createdAt,
  });

  factory GuardianReport.fromMap(Map<String, dynamic> map) {
    return GuardianReport(
      id: map['id'] as int?,
      zoneId: map['zone_id'] as int,
      reportType: map['report_type'] as String,
      alertsJson: map['alerts_json'] as String? ?? '[]',
      plantHealth: map['plant_health'] as String?,
      environmentSummary: map['environment_summary'] as String?,
      recipeCompliance: map['recipe_compliance'] as String?,
      recommendations: map['recommendations'] as String?,
      watching: map['watching'] as String?,
      fullResponse: map['full_response'] as String?,
      growId: map['grow_id'] as int?,
      growDay: map['grow_day'] as int?,
      recipeId: map['recipe_id'] as int?,
      recipePhase: map['recipe_phase'] as String?,
      imageIds: map['image_ids'] as String?,
      promptTokens: map['prompt_tokens'] as int?,
      completionTokens: map['completion_tokens'] as int?,
      costCents: map['cost_cents'] as double?,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'report_type': reportType,
      'alerts_json': alertsJson,
      'plant_health': plantHealth,
      'environment_summary': environmentSummary,
      'recipe_compliance': recipeCompliance,
      'recommendations': recommendations,
      'watching': watching,
      'full_response': fullResponse,
      'grow_id': growId,
      'grow_day': growDay,
      'recipe_id': recipeId,
      'recipe_phase': recipePhase,
      'image_ids': imageIds,
      'prompt_tokens': promptTokens,
      'completion_tokens': completionTokens,
      'cost_cents': costCents,
      'created_at': createdAt,
    };
  }

  List<dynamic> get alerts => jsonDecode(alertsJson);
  List<int> get imageIdList => imageIds != null ? List<int>.from(jsonDecode(imageIds!)) : [];
}
