// lib/models/camera.dart
class Camera {
  final int? id; // Changed to nullable
  final String name;
  final String devicePath;
  final int cameraIndex;
  final String model;
  final int resolutionWidth;
  final int resolutionHeight;
  final int captureIntervalHours; // Type changed from double to int
  final bool enabled;
  final bool onlyWhenLightsOn;
  final bool autoCleanupEnabled;
  final int? retentionDays;
  final int? maxPhotos;
  final int createdAt;
  final int updatedAt;

  Camera({
    this.id,
    required this.name,
    required this.devicePath,
    required this.cameraIndex,
    this.model = 'Generic',
    this.resolutionWidth = 1920,
    this.resolutionHeight = 1080,
    required this.captureIntervalHours,
    required this.enabled,
    this.onlyWhenLightsOn = false,
    this.autoCleanupEnabled = false,
    this.retentionDays,
    this.maxPhotos,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Camera.fromMap(Map<String, dynamic> map) {
    return Camera(
      id: map['id'] as int?,
      name: map['name'] as String,
      devicePath: map['device_path'] as String,
      cameraIndex: map['camera_index'] as int? ?? 0,
      model: map['model'] as String? ?? '',
      resolutionWidth: map['resolution_width'] as int,
      resolutionHeight: map['resolution_height'] as int,
      captureIntervalHours: (map['capture_interval_hours'] as num).toInt(),
      enabled: (map['enabled'] as int) == 1,
      onlyWhenLightsOn: map['only_when_lights_on'] == 1,
      autoCleanupEnabled: map['auto_cleanup_enabled'] == 1,
      retentionDays: map['retention_days'],
      maxPhotos: map['max_photos'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'device_path': devicePath,
      'camera_index': cameraIndex,
      'model': model,
      'resolution_width': resolutionWidth,
      'resolution_height': resolutionHeight,
      'capture_interval_hours': captureIntervalHours,
      'enabled': enabled ? 1 : 0,
      'only_when_lights_on': onlyWhenLightsOn ? 1 : 0,
      'auto_cleanup_enabled': autoCleanupEnabled ? 1 : 0,
      'retention_days': retentionDays,
      'max_photos': maxPhotos,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
