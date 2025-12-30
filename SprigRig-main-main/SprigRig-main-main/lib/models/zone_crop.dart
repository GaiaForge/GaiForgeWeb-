class ZoneCrop {
  final int? id;
  final int zoneId;
  final String cropName;
  final int? templateId;
  final int? currentPhaseId;
  final String? phaseStartDate;
  final String? growStartDate;
  final String? expectedHarvestDate;
  final int useRecipeProfile;
  final int isActive;
  final int createdAt;

  ZoneCrop({
    this.id,
    required this.zoneId,
    required this.cropName,
    this.templateId,
    this.currentPhaseId,
    this.phaseStartDate,
    this.growStartDate,
    this.expectedHarvestDate,
    this.useRecipeProfile = 1,
    this.isActive = 1,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'crop_name': cropName,
      'template_id': templateId,
      'current_phase_id': currentPhaseId,
      'phase_start_date': phaseStartDate,
      'grow_start_date': growStartDate,
      'expected_harvest_date': expectedHarvestDate,
      'use_recipe_profile': useRecipeProfile,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }

  factory ZoneCrop.fromMap(Map<String, dynamic> map) {
    return ZoneCrop(
      id: map['id'],
      zoneId: map['zone_id'],
      cropName: map['crop_name'],
      templateId: map['template_id'],
      currentPhaseId: map['current_phase_id'],
      phaseStartDate: map['phase_start_date'],
      growStartDate: map['grow_start_date'],
      expectedHarvestDate: map['expected_harvest_date'],
      useRecipeProfile: map['use_recipe_profile'] ?? 1,
      isActive: map['is_active'] ?? 1,
      createdAt: map['created_at'],
    );
  }
}
