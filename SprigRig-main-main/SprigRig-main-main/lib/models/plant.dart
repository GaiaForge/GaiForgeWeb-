// lib/models/plant.dart
class Plant {
  final int id;
  final String name;
  final String category;
  final int? defaultWaterDuration;
  final int? defaultWaterInterval;
  final double? defaultTemperatureMin;
  final double? defaultTemperatureMax;
  final double? defaultHumidityMin;
  final double? defaultHumidityMax;
  final int? defaultLightHours;
  final String? notes;
  final int createdAt;
  final int updatedAt;

  Plant({
    required this.id,
    required this.name,
    required this.category,
    this.defaultWaterDuration,
    this.defaultWaterInterval,
    this.defaultTemperatureMin,
    this.defaultTemperatureMax,
    this.defaultHumidityMin,
    this.defaultHumidityMax,
    this.defaultLightHours,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      id: map['id'] as int,
      name: map['name'] as String,
      category: map['category'] as String,
      defaultWaterDuration: map['default_water_duration'] as int?,
      defaultWaterInterval: map['default_water_interval'] as int?,
      defaultTemperatureMin:
          (map['default_temperature_min'] as num?)?.toDouble(),
      defaultTemperatureMax:
          (map['default_temperature_max'] as num?)?.toDouble(),
      defaultHumidityMin: (map['default_humidity_min'] as num?)?.toDouble(),
      defaultHumidityMax: (map['default_humidity_max'] as num?)?.toDouble(),
      defaultLightHours: map['default_light_hours'] as int?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'default_water_duration': defaultWaterDuration,
      'default_water_interval': defaultWaterInterval,
      'default_temperature_min': defaultTemperatureMin,
      'default_temperature_max': defaultTemperatureMax,
      'default_humidity_min': defaultHumidityMin,
      'default_humidity_max': defaultHumidityMax,
      'default_light_hours': defaultLightHours,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class GrowMode {
  final int id;
  final String name;
  final String? description;
  final bool isSystem;

  GrowMode({
    required this.id,
    required this.name,
    this.description,
    required this.isSystem,
  });

  factory GrowMode.fromMap(Map<String, dynamic> map) {
    return GrowMode(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      isSystem: (map['is_system'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_system': isSystem ? 1 : 0,
    };
  }
}
