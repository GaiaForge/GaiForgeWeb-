import 'dart:convert';

class GuardianConfig {
  final int? id;
  final int zoneId;
  final bool enabled;
  final String? apiKey;
  final String? activeKeyId;
  final int checkIntervalHours;
  final bool visionEnabled;
  final bool dataAnalysisEnabled;
  final String alertSensitivity;
  
  // Voice Settings
  final bool voiceEnabled;
  final String wakeWord;
  final String? microphoneDeviceId;
  final String? speakerDeviceId;
  final bool proactiveVoice;

  // Camera Settings
  final String? cameraDeviceId;
  final bool captureOnSchedule;

  // AI Actions (Experimental)
  final bool actionsEnabled;
  final Map<String, bool> actionPermissions;
  final bool requireConfirmation;
  final int actionCooldownMinutes;

  final int createdAt;
  final int updatedAt;

  GuardianConfig({
    this.id,
    required this.zoneId,
    this.enabled = false,
    this.apiKey,
    this.activeKeyId,
    this.checkIntervalHours = 24,
    this.visionEnabled = true,
    this.dataAnalysisEnabled = true,
    this.alertSensitivity = 'medium',
    this.voiceEnabled = false,
    this.wakeWord = 'sprigrig',
    this.microphoneDeviceId,
    this.speakerDeviceId,
    this.proactiveVoice = true,
    this.cameraDeviceId,
    this.captureOnSchedule = true,
    this.actionsEnabled = false,
    Map<String, bool>? actionPermissions,
    this.requireConfirmation = true,
    this.actionCooldownMinutes = 5,
    required this.createdAt,
    required this.updatedAt,
  }) : actionPermissions = actionPermissions ?? {
    'fertigation_ph': false,
    'fertigation_ec': false,
    'fertigation_pumps': false,
    'lighting': false,
    'hvac': false,
    'irrigation': false,
    'recipes': false,
    'setpoints': false,
  };

  factory GuardianConfig.fromMap(Map<String, dynamic> map) {
    return GuardianConfig(
      id: map['id'] as int?,
      zoneId: map['zone_id'] as int,
      enabled: (map['enabled'] as int) == 1,
      apiKey: map['api_key'] as String?,
      activeKeyId: map['active_key_id'] as String?,
      checkIntervalHours: map['check_interval_hours'] as int? ?? 24,
      visionEnabled: (map['vision_enabled'] as int? ?? 1) == 1,
      dataAnalysisEnabled: (map['data_analysis_enabled'] as int? ?? 1) == 1,
      alertSensitivity: map['alert_sensitivity'] as String? ?? 'medium',
      voiceEnabled: (map['voice_enabled'] as int? ?? 0) == 1,
      wakeWord: map['wake_word'] as String? ?? 'sprigrig',
      microphoneDeviceId: map['microphone_device_id'] as String?,
      speakerDeviceId: map['speaker_device_id'] as String?,
      proactiveVoice: (map['proactive_voice'] as int? ?? 1) == 1,
      cameraDeviceId: map['camera_device_id'] as String?,
      captureOnSchedule: (map['capture_on_schedule'] as int? ?? 1) == 1,
      actionsEnabled: (map['actions_enabled'] as int? ?? 0) == 1,
      actionPermissions: map['action_permissions'] != null 
          ? Map<String, bool>.from(jsonDecode(map['action_permissions'] as String))
          : null,
      requireConfirmation: (map['require_confirmation'] as int? ?? 1) == 1,
      actionCooldownMinutes: map['action_cooldown_minutes'] as int? ?? 5,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'enabled': enabled ? 1 : 0,
      'api_key': apiKey,
      'active_key_id': activeKeyId,
      'check_interval_hours': checkIntervalHours,
      'vision_enabled': visionEnabled ? 1 : 0,
      'data_analysis_enabled': dataAnalysisEnabled ? 1 : 0,
      'alert_sensitivity': alertSensitivity,
      'voice_enabled': voiceEnabled ? 1 : 0,
      'wake_word': wakeWord,
      'microphone_device_id': microphoneDeviceId,
      'speaker_device_id': speakerDeviceId,
      'proactive_voice': proactiveVoice ? 1 : 0,
      'camera_device_id': cameraDeviceId,
      'capture_on_schedule': captureOnSchedule ? 1 : 0,
      'actions_enabled': actionsEnabled ? 1 : 0,
      'action_permissions': jsonEncode(actionPermissions),
      'require_confirmation': requireConfirmation ? 1 : 0,
      'action_cooldown_minutes': actionCooldownMinutes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  GuardianConfig copyWith({
    int? id,
    int? zoneId,
    bool? enabled,
    String? apiKey,
    String? activeKeyId,
    int? checkIntervalHours,
    bool? visionEnabled,
    bool? dataAnalysisEnabled,
    String? alertSensitivity,
    bool? voiceEnabled,
    String? wakeWord,
    String? microphoneDeviceId,
    String? speakerDeviceId,
    bool? proactiveVoice,
    String? cameraDeviceId,
    bool? captureOnSchedule,
    bool? actionsEnabled,
    Map<String, bool>? actionPermissions,
    bool? requireConfirmation,
    int? actionCooldownMinutes,
    int? createdAt,
    int? updatedAt,
  }) {
    return GuardianConfig(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      enabled: enabled ?? this.enabled,
      apiKey: apiKey ?? this.apiKey,
      activeKeyId: activeKeyId ?? this.activeKeyId,
      checkIntervalHours: checkIntervalHours ?? this.checkIntervalHours,
      visionEnabled: visionEnabled ?? this.visionEnabled,
      dataAnalysisEnabled: dataAnalysisEnabled ?? this.dataAnalysisEnabled,
      alertSensitivity: alertSensitivity ?? this.alertSensitivity,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      wakeWord: wakeWord ?? this.wakeWord,
      microphoneDeviceId: microphoneDeviceId ?? this.microphoneDeviceId,
      speakerDeviceId: speakerDeviceId ?? this.speakerDeviceId,
      proactiveVoice: proactiveVoice ?? this.proactiveVoice,
      cameraDeviceId: cameraDeviceId ?? this.cameraDeviceId,
      captureOnSchedule: captureOnSchedule ?? this.captureOnSchedule,
      actionsEnabled: actionsEnabled ?? this.actionsEnabled,
      actionPermissions: actionPermissions ?? this.actionPermissions,
      requireConfirmation: requireConfirmation ?? this.requireConfirmation,
      actionCooldownMinutes: actionCooldownMinutes ?? this.actionCooldownMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
