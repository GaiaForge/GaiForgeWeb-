class RecipePhase {
  final int? id;
  final int templateId;
  final String phaseName;
  final int phaseOrder;
  final int durationDays;
  final int? lightHoursOn;
  final int? lightHoursOff;
  final double? lightIntensityPercent;
  final double? targetTempDay;
  final double? targetTempNight;
  final double? targetHumidity;
  final double? targetPhMin;
  final double? targetPhMax;
  final double? targetEcMin;
  final double? targetEcMax;
  final int? wateringFrequencyHours;
  final int? wateringDurationMinutes;
  final int? aerationOnMinutes;
  final int? aerationOffMinutes;
  final String? notes;
  final bool? fertigationEnabled;
  final double? nutrientAMlPerLiter;
  final double? nutrientBMlPerLiter;
  final double? nutrientCMlPerLiter;
  final double? calMagMlPerLiter;
  final double? silicaMlPerLiter;
  final double? enzymesMlPerLiter;
  final int createdAt;

  RecipePhase({
    this.id,
    required this.templateId,
    required this.phaseName,
    required this.phaseOrder,
    required this.durationDays,
    this.lightHoursOn,
    this.lightHoursOff,
    this.lightIntensityPercent,
    this.targetTempDay,
    this.targetTempNight,
    this.targetHumidity,
    this.targetPhMin,
    this.targetPhMax,
    this.targetEcMin,
    this.targetEcMax,
    this.wateringFrequencyHours,
    this.wateringDurationMinutes,
    this.aerationOnMinutes,
    this.aerationOffMinutes,
    this.notes,
    this.fertigationEnabled,
    this.nutrientAMlPerLiter,
    this.nutrientBMlPerLiter,
    this.nutrientCMlPerLiter,
    this.calMagMlPerLiter,
    this.silicaMlPerLiter,
    this.enzymesMlPerLiter,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'template_id': templateId,
      'phase_name': phaseName,
      'phase_order': phaseOrder,
      'duration_days': durationDays,
      'light_hours_on': lightHoursOn,
      'light_hours_off': lightHoursOff,
      'light_intensity_percent': lightIntensityPercent,
      'target_temp_day': targetTempDay,
      'target_temp_night': targetTempNight,
      'target_humidity': targetHumidity,
      'target_ph_min': targetPhMin,
      'target_ph_max': targetPhMax,
      'target_ec_min': targetEcMin,
      'target_ec_max': targetEcMax,
      'watering_frequency_hours': wateringFrequencyHours,
      'watering_duration_minutes': wateringDurationMinutes,
      'aeration_on_minutes': aerationOnMinutes,
      'aeration_off_minutes': aerationOffMinutes,
      'notes': notes,
      'fertigation_enabled': (fertigationEnabled ?? false) ? 1 : 0,
      'nutrient_a_ml_per_liter': nutrientAMlPerLiter,
      'nutrient_b_ml_per_liter': nutrientBMlPerLiter,
      'nutrient_c_ml_per_liter': nutrientCMlPerLiter,
      'calmag_ml_per_liter': calMagMlPerLiter,
      'silica_ml_per_liter': silicaMlPerLiter,
      'enzymes_ml_per_liter': enzymesMlPerLiter,
      'created_at': createdAt,
    };
  }

  factory RecipePhase.fromMap(Map<String, dynamic> map) {
    return RecipePhase(
      id: map['id'],
      templateId: map['template_id'],
      phaseName: map['phase_name'],
      phaseOrder: map['phase_order'],
      durationDays: map['duration_days'],
      lightHoursOn: map['light_hours_on'],
      lightHoursOff: map['light_hours_off'],
      lightIntensityPercent: map['light_intensity_percent'],
      targetTempDay: map['target_temp_day'],
      targetTempNight: map['target_temp_night'],
      targetHumidity: map['target_humidity'],
      targetPhMin: map['target_ph_min'],
      targetPhMax: map['target_ph_max'],
      targetEcMin: map['target_ec_min'],
      targetEcMax: map['target_ec_max'],
      wateringFrequencyHours: map['watering_frequency_hours'],
      wateringDurationMinutes: map['watering_duration_minutes'],
      aerationOnMinutes: map['aeration_on_minutes'],
      aerationOffMinutes: map['aeration_off_minutes'],
      notes: map['notes'],
      fertigationEnabled: (map['fertigation_enabled'] as int?) == 1,
      nutrientAMlPerLiter: map['nutrient_a_ml_per_liter'],
      nutrientBMlPerLiter: map['nutrient_b_ml_per_liter'],
      nutrientCMlPerLiter: map['nutrient_c_ml_per_liter'],
      calMagMlPerLiter: map['calmag_ml_per_liter'],
      silicaMlPerLiter: map['silica_ml_per_liter'],
      enzymesMlPerLiter: map['enzymes_ml_per_liter'],
      createdAt: map['created_at'],
    );
  }
}
