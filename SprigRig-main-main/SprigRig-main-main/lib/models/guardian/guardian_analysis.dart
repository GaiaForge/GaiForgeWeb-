class GuardianAnalysis {
  final int? id;
  final int zoneId;
  final String analysisType; // 'quick', 'full', 'vision'
  final String status; // 'pending', 'completed', 'failed'
  final double? confidence;
  final String? summary;
  final String? fullResponse; // JSON blob
  final String? imagePath;
  final int createdAt;

  GuardianAnalysis({
    this.id,
    required this.zoneId,
    required this.analysisType,
    required this.status,
    this.confidence,
    this.summary,
    this.fullResponse,
    this.imagePath,
    required this.createdAt,
  });

  factory GuardianAnalysis.fromMap(Map<String, dynamic> map) {
    return GuardianAnalysis(
      id: map['id'] as int?,
      zoneId: map['zone_id'] as int,
      analysisType: map['analysis_type'] as String,
      status: map['status'] as String,
      confidence: (map['confidence'] as num?)?.toDouble(),
      summary: map['summary'] as String?,
      fullResponse: map['full_response'] as String?,
      imagePath: map['image_path'] as String?,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'analysis_type': analysisType,
      'status': status,
      'confidence': confidence,
      'summary': summary,
      'full_response': fullResponse,
      'image_path': imagePath,
      'created_at': createdAt,
    };
  }
}
