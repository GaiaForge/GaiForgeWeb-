class SensorCalibration {
  final int id;
  final int sensorId;
  final String parameterName;
  final double offsetValue;
  final double scaleFactor;
  final double? referenceLow;
  final double? referenceHigh;
  final double? measuredLow;
  final double? measuredHigh;
  final String calibrationDate;
  final String? nextCalibrationDue;
  final String? calibratedBy;
  final String? notes;

  SensorCalibration({
    required this.id,
    required this.sensorId,
    required this.parameterName,
    this.offsetValue = 0.0,
    this.scaleFactor = 1.0,
    this.referenceLow,
    this.referenceHigh,
    this.measuredLow,
    this.measuredHigh,
    required this.calibrationDate,
    this.nextCalibrationDue,
    this.calibratedBy,
    this.notes,
  });

  factory SensorCalibration.fromMap(Map<String, dynamic> map) {
    return SensorCalibration(
      id: map['id'] as int,
      sensorId: map['sensor_id'] as int,
      parameterName: map['parameter_name'] as String,
      offsetValue: (map['offset_value'] as num?)?.toDouble() ?? 0.0,
      scaleFactor: (map['scale_factor'] as num?)?.toDouble() ?? 1.0,
      referenceLow: (map['reference_low'] as num?)?.toDouble(),
      referenceHigh: (map['reference_high'] as num?)?.toDouble(),
      measuredLow: (map['measured_low'] as num?)?.toDouble(),
      measuredHigh: (map['measured_high'] as num?)?.toDouble(),
      calibrationDate: map['calibration_date'] as String,
      nextCalibrationDue: map['next_calibration_due'] as String?,
      calibratedBy: map['calibrated_by'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sensor_id': sensorId,
      'parameter_name': parameterName,
      'offset_value': offsetValue,
      'scale_factor': scaleFactor,
      'reference_low': referenceLow,
      'reference_high': referenceHigh,
      'measured_low': measuredLow,
      'measured_high': measuredHigh,
      'calibration_date': calibrationDate,
      'next_calibration_due': nextCalibrationDue,
      'calibrated_by': calibratedBy,
      'notes': notes,
    };
  }
}
