// lib/models/camera_assignment.dart
class CameraAssignment {
  final int id;
  final int cameraId;
  final int zoneId;
  final String position;
  final String? name;
  final String? devicePath;
  final bool? enabled;

  CameraAssignment({
    required this.id,
    required this.cameraId,
    required this.zoneId,
    required this.position,
    this.name,
    this.devicePath,
    this.enabled,
  });

  factory CameraAssignment.fromMap(Map<String, dynamic> map) {
    return CameraAssignment(
      id: map['id'] as int,
      cameraId: map['camera_id'] as int,
      zoneId: map['zone_id'] as int,
      position: map['position'] as String,
      name: map['name'] as String?,
      devicePath: map['device_path'] as String?,
      enabled: map['enabled'] != null ? (map['enabled'] as int) == 1 : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'camera_id': cameraId,
      'zone_id': zoneId,
      'position': position,
      'name': name,
      'device_path': devicePath,
      'enabled': enabled != null ? (enabled! ? 1 : 0) : null,
    };
  }
}
