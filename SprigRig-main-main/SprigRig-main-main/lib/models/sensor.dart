// lib/models/sensor.dart
class Sensor {
  final int id;
  final int zoneId;
  final String sensorType;
  final String name;
  final String? address;
  final double calibrationOffset;  // NEW: for sensor calibration
  final double scaleFactor; // NEW: for analog calibration (slope)
  final int displayOrder; // NEW: for dashboard ordering
  final bool enabled;
  final int? hubId; // NEW
  final int? inputChannel; // NEW
  final String? inputType; // 'i2c', 'spi', 'analog_0_10v', 'analog_4_20ma'
  final String? i2cAddress; // NEW
  final int? spiCsPin; // NEW
  final int sampleRateSeconds; // NEW
  final bool isActive; // NEW
  final double? setpointValue;
  final double? minValue;
  final double? maxValue;
  final bool useSetpoint;
  final bool useRange;
  final int createdAt;
  final int updatedAt;

  Sensor({
    required this.id,
    required this.zoneId,
    required this.sensorType,
    required this.name,
    this.address,
    this.calibrationOffset = 0.0,
    this.scaleFactor = 1.0, // Default to 1.0
    this.displayOrder = 0,
    required this.enabled,
    this.hubId,
    this.inputChannel,
    this.inputType,
    this.i2cAddress,
    this.spiCsPin,
    this.sampleRateSeconds = 60,
    this.isActive = true,
    this.setpointValue,
    this.minValue,
    this.maxValue,
    this.useSetpoint = false,
    this.useRange = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Sensor.fromMap(Map<String, dynamic> map) {
    return Sensor(
      id: map['id'] as int,
      zoneId: map['zone_id'] as int,
      sensorType: map['sensor_type'] as String,
      name: map['name'] as String,
      address: map['address'] as String?,
      calibrationOffset: (map['calibration_offset'] as num?)?.toDouble() ?? 0.0,
      scaleFactor: (map['scale_factor'] as num?)?.toDouble() ?? 1.0,
      displayOrder: map['display_order'] as int? ?? 0,
      enabled: (map['enabled'] as int) == 1,
      hubId: map['hub_id'] as int?,
      inputChannel: map['input_channel'] as int?,
      inputType: map['input_type'] as String?,
      i2cAddress: map['i2c_address'] as String?,
      spiCsPin: map['spi_cs_pin'] as int?,
      sampleRateSeconds: map['sample_rate_seconds'] as int? ?? 60,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      setpointValue: (map['setpoint_value'] as num?)?.toDouble(),
      minValue: (map['min_value'] as num?)?.toDouble(),
      maxValue: (map['max_value'] as num?)?.toDouble(),
      useSetpoint: (map['use_setpoint'] as int? ?? 0) == 1,
      useRange: (map['use_range'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'sensor_type': sensorType,
      'name': name,
      'address': address,
      'calibration_offset': calibrationOffset,
      'scale_factor': scaleFactor,
      'display_order': displayOrder,
      'enabled': enabled ? 1 : 0,
      'hub_id': hubId,
      'input_channel': inputChannel,
      'input_type': inputType,
      'i2c_address': i2cAddress,
      'spi_cs_pin': spiCsPin,
      'sample_rate_seconds': sampleRateSeconds,
      'is_active': isActive ? 1 : 0,
      'setpoint_value': setpointValue,
      'min_value': minValue,
      'max_value': maxValue,
      'use_setpoint': useSetpoint ? 1 : 0,
      'use_range': useRange ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  List<String> getSupportedReadingTypes() {
    switch (sensorType) {
      case 'dht22':
        return ['temperature', 'humidity'];
      case 'soil_moisture':
        return ['moisture'];
      case 'ph_sensor':
        return ['ph'];
      case 'ec_sensor':
        return ['ec'];
      case 'light_sensor':
        return ['light_intensity'];
      case 'water_level':
        return ['water_level'];
      case 'co2_sensor':
        return ['co2'];
      case 'pressure_sensor':
        return ['pressure'];
      default:
        return ['temperature'];
    }
  }

  // Helper method to apply calibration to a reading
  double applyCalibratedReading(double rawValue) {
    return (rawValue * scaleFactor) + calibrationOffset;
  }

  // Copy with method for easy updates
  Sensor copyWith({
    int? id,
    int? zoneId,
    String? sensorType,
    String? name,
    String? address,
    double? calibrationOffset,
    double? scaleFactor,
    int? displayOrder,
    bool? enabled,
    int? hubId,
    int? inputChannel,
    String? inputType,
    String? i2cAddress,
    int? spiCsPin,
    int? sampleRateSeconds,
    bool? isActive,
    double? setpointValue,
    double? minValue,
    double? maxValue,
    bool? useSetpoint,
    bool? useRange,
    int? createdAt,
    int? updatedAt,
  }) {
    return Sensor(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      sensorType: sensorType ?? this.sensorType,
      name: name ?? this.name,
      address: address ?? this.address,
      calibrationOffset: calibrationOffset ?? this.calibrationOffset,
      scaleFactor: scaleFactor ?? this.scaleFactor,
      displayOrder: displayOrder ?? this.displayOrder,
      enabled: enabled ?? this.enabled,
      hubId: hubId ?? this.hubId,
      inputChannel: inputChannel ?? this.inputChannel,
      inputType: inputType ?? this.inputType,
      i2cAddress: i2cAddress ?? this.i2cAddress,
      spiCsPin: spiCsPin ?? this.spiCsPin,
      sampleRateSeconds: sampleRateSeconds ?? this.sampleRateSeconds,
      isActive: isActive ?? this.isActive,
      setpointValue: setpointValue ?? this.setpointValue,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      useSetpoint: useSetpoint ?? this.useSetpoint,
      useRange: useRange ?? this.useRange,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SensorReading {
  final int id;
  final int sensorId;
  final String readingType;
  final double value;
  final int timestamp;

  SensorReading({
    required this.id,
    required this.sensorId,
    required this.readingType,
    required this.value,
    required this.timestamp,
  });

  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      id: map['id'] as int,
      sensorId: map['sensor_id'] as int,
      readingType: map['reading_type'] as String,
      value: (map['value'] as num).toDouble(),
      timestamp: map['timestamp'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sensor_id': sensorId,
      'reading_type': readingType,
      'value': value,
      'timestamp': timestamp,
    };
  }

  // Helper method to get DateTime from timestamp
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

  // Copy with method
  SensorReading copyWith({
    int? id,
    int? sensorId,
    String? readingType,
    double? value,
    int? timestamp,
  }) {
    return SensorReading(
      id: id ?? this.id,
      sensorId: sensorId ?? this.sensorId,
      readingType: readingType ?? this.readingType,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
