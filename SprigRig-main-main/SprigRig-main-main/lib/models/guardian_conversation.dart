class GuardianConversation {
  final int? id;
  final int zoneId;
  final String question;
  final String response;
  final String? contextJson;
  final int? imageId;
  final int? tokensUsed;
  final int createdAt;

  GuardianConversation({
    this.id,
    required this.zoneId,
    required this.question,
    required this.response,
    this.contextJson,
    this.imageId,
    this.tokensUsed,
    required this.createdAt,
  });

  factory GuardianConversation.fromMap(Map<String, dynamic> map) {
    return GuardianConversation(
      id: map['id'] as int?,
      zoneId: map['zone_id'] as int,
      question: map['question'] as String,
      response: map['response'] as String,
      contextJson: map['context_json'] as String?,
      imageId: map['image_id'] as int?,
      tokensUsed: map['tokens_used'] as int?,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'question': question,
      'response': response,
      'context_json': contextJson,
      'image_id': imageId,
      'tokens_used': tokensUsed,
      'created_at': createdAt,
    };
  }
}
