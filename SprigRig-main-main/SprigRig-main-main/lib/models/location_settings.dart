class LocationSettings {
  final int? id;
  final double latitude;
  final double longitude;
  final String timezone;
  final String? locationName;
  final int createdAt;
  final int updatedAt;

  LocationSettings({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.locationName,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      'location_name': locationName,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory LocationSettings.fromMap(Map<String, dynamic> map) {
    return LocationSettings(
      id: map['id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      timezone: map['timezone'],
      locationName: map['location_name'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}
