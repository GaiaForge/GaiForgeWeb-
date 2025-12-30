class GuardianAction {
  final int zoneId;
  final String actionType; // 'set_ph_target', 'trigger_dose', etc.
  final String category; // 'fertigation_ph', 'lighting', etc.
  final String description; // Human readable description
  final Map<String, dynamic> parameters;
  final String reasoning; // Why the AI decided to take this action

  GuardianAction({
    required this.zoneId,
    required this.actionType,
    required this.category,
    required this.description,
    required this.parameters,
    required this.reasoning,
  });

  Map<String, dynamic> toMap() {
    return {
      'zone_id': zoneId,
      'action_type': actionType,
      'category': category,
      'description': description,
      'parameters': parameters,
      'reasoning': reasoning,
    };
  }

  factory GuardianAction.fromMap(Map<String, dynamic> map) {
    return GuardianAction(
      zoneId: map['zone_id'] as int,
      actionType: map['action_type'] as String,
      category: map['category'] as String,
      description: map['description'] as String,
      parameters: map['parameters'] as Map<String, dynamic>,
      reasoning: map['reasoning'] as String,
    );
  }
}

class GuardianActionLog {
  final int id;
  final int zoneId;
  final String actionType;
  final String category;
  final String description;
  final Map<String, dynamic> parameters;
  final String? reasoning;
  final bool success;
  final String? error;
  final int timestamp;

  GuardianActionLog({
    required this.id,
    required this.zoneId,
    required this.actionType,
    required this.category,
    required this.description,
    required this.parameters,
    this.reasoning,
    required this.success,
    this.error,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'action_type': actionType,
      'category': category,
      'description': description,
      'parameters': parameters,
      'reasoning': reasoning,
      'success': success ? 1 : 0,
      'error': error,
      'timestamp': timestamp,
    };
  }

  factory GuardianActionLog.fromMap(Map<String, dynamic> map) {
    return GuardianActionLog(
      id: map['id'] as int,
      zoneId: map['zone_id'] as int,
      actionType: map['action_type'] as String,
      category: map['category'] as String,
      description: map['description'] as String,
      parameters: map['parameters'] is String 
          ? {} // Parse JSON if needed
          : map['parameters'] as Map<String, dynamic>,
      reasoning: map['reasoning'] as String?,
      success: (map['success'] as int) == 1,
      error: map['error'] as String?,
      timestamp: map['timestamp'] as int,
    );
  }
}

class ActionResult {
  final bool success;
  final String message;
  final GuardianAction action;

  ActionResult({
    required this.success,
    required this.message,
    required this.action,
  });
}

class ValidationResult {
  final bool isValid;
  final String reason;

  ValidationResult(this.isValid, this.reason);
}
