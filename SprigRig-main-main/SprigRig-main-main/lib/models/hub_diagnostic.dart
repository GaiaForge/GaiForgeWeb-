class HubDiagnostic {
  final int id;
  final int hubId;
  final String timestamp;
  final int communicationErrors;
  final int successfulReads;
  final double? averageResponseTimeMs;
  final String? lastErrorMessage;

  HubDiagnostic({
    required this.id,
    required this.hubId,
    required this.timestamp,
    this.communicationErrors = 0,
    this.successfulReads = 0,
    this.averageResponseTimeMs,
    this.lastErrorMessage,
  });

  factory HubDiagnostic.fromMap(Map<String, dynamic> map) {
    return HubDiagnostic(
      id: map['id'] as int,
      hubId: map['hub_id'] as int,
      timestamp: map['timestamp'] as String,
      communicationErrors: map['communication_errors'] as int? ?? 0,
      successfulReads: map['successful_reads'] as int? ?? 0,
      averageResponseTimeMs: (map['average_response_time_ms'] as num?)?.toDouble(),
      lastErrorMessage: map['last_error_message'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hub_id': hubId,
      'timestamp': timestamp,
      'communication_errors': communicationErrors,
      'successful_reads': successfulReads,
      'average_response_time_ms': averageResponseTimeMs,
      'last_error_message': lastErrorMessage,
    };
  }
}
