class RecipeSetting {
  final int id;
  final int recipeId;
  final int controlTypeId;
  final String settingName;
  final String settingValue;
  final int createdAt;

  RecipeSetting({
    required this.id,
    required this.recipeId,
    required this.controlTypeId,
    required this.settingName,
    required this.settingValue,
    required this.createdAt,
  });

  factory RecipeSetting.fromMap(Map<String, dynamic> map) {
    return RecipeSetting(
      id: map['id'] as int,
      recipeId: map['recipe_id'] as int,
      controlTypeId: map['control_type_id'] as int,
      settingName: map['setting_name'] as String,
      settingValue: map['setting_value'] as String,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'control_type_id': controlTypeId,
      'setting_name': settingName,
      'setting_value': settingValue,
      'created_at': createdAt,
    };
  }
}
