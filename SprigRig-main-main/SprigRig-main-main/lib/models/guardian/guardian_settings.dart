class GuardianSettings {
  final int? id;
  final int zoneId;
  final bool enabled;
  final bool apiKeyConfigured;
  final int checkIntervalMinutes;
  final bool visionAnalysisEnabled;
  final int visionIntervalHours;
  final String notificationLevel; // 'info', 'warning', 'critical'
  
  // Voice Settings
  final bool voiceEnabled;
  final String wakeWord;
  final String? microphoneDeviceId;
  final String? speakerDeviceId;
  final bool proactiveVoice;

  // Camera Settings
  final String? cameraDeviceId;
  final bool captureOnSchedule;

  final int createdAt;
  final int updatedAt;

  GuardianSettings({
    this.id,
    required this.zoneId,
    this.enabled = false,
    this.apiKeyConfigured = false,
    this.checkIntervalMinutes = 60,
    this.visionAnalysisEnabled = true,
    this.visionIntervalHours = 24,
    this.notificationLevel = 'warning',
    this.voiceEnabled = false,
    this.wakeWord = 'sprigrig',
    this.microphoneDeviceId,
    this.speakerDeviceId,
    this.proactiveVoice = true,
    this.cameraDeviceId,
    this.captureOnSchedule = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GuardianSettings.fromMap(Map<String, dynamic> map) {
    return GuardianSettings(
      id: map['id'],
      zoneId: map['zone_id'],
      enabled: map['enabled'] == 1,
      apiKeyConfigured: map['api_key_configured'] == 1,
      checkIntervalMinutes: map['check_interval_minutes'],
      visionAnalysisEnabled: map['vision_analysis_enabled'] == 1,
      visionIntervalHours: map['vision_interval_hours'],
      notificationLevel: map['notification_level'],
      voiceEnabled: map['voice_enabled'] == 1,
      wakeWord: map['wake_word'] ?? 'sprigrig',
      microphoneDeviceId: map['microphone_device_id'],
      speakerDeviceId: map['speaker_device_id'],
      proactiveVoice: map['proactive_voice'] == 1,
      cameraDeviceId: map['camera_device_id'],
      captureOnSchedule: map['capture_on_schedule'] == 1,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'enabled': enabled ? 1 : 0,
      'api_key_configured': apiKeyConfigured ? 1 : 0,
      'check_interval_minutes': checkIntervalMinutes,
      'vision_analysis_enabled': visionAnalysisEnabled ? 1 : 0,
      'vision_interval_hours': visionIntervalHours,
      'notification_level': notificationLevel,
      'voice_enabled': voiceEnabled ? 1 : 0,
      'wake_word': wakeWord,
      'microphone_device_id': microphoneDeviceId,
      'speaker_device_id': speakerDeviceId,
      'proactive_voice': proactiveVoice ? 1 : 0,
      'camera_device_id': cameraDeviceId,
      'capture_on_schedule': captureOnSchedule ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  GuardianSettings copyWith({
    int? id,
    int? zoneId,
    bool? enabled,
    bool? apiKeyConfigured,
    int? checkIntervalMinutes,
    bool? visionAnalysisEnabled,
    int? visionIntervalHours,
    String? notificationLevel,
    bool? voiceEnabled,
    String? wakeWord,
    String? microphoneDeviceId,
    String? speakerDeviceId,
    bool? proactiveVoice,
    String? cameraDeviceId,
    bool? captureOnSchedule,
    int? createdAt,
    int? updatedAt,
  }) {
    return GuardianSettings(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      enabled: enabled ?? this.enabled,
      apiKeyConfigured: apiKeyConfigured ?? this.apiKeyConfigured,
      checkIntervalMinutes: checkIntervalMinutes ?? this.checkIntervalMinutes,
      visionAnalysisEnabled: visionAnalysisEnabled ?? this.visionAnalysisEnabled,
      visionIntervalHours: visionIntervalHours ?? this.visionIntervalHours,
      notificationLevel: notificationLevel ?? this.notificationLevel,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      wakeWord: wakeWord ?? this.wakeWord,
      microphoneDeviceId: microphoneDeviceId ?? this.microphoneDeviceId,
      speakerDeviceId: speakerDeviceId ?? this.speakerDeviceId,
      proactiveVoice: proactiveVoice ?? this.proactiveVoice,
      cameraDeviceId: cameraDeviceId ?? this.cameraDeviceId,
      captureOnSchedule: captureOnSchedule ?? this.captureOnSchedule,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
