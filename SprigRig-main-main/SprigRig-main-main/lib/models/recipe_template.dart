class RecipeTemplate {
  final int? id;
  final String name;
  final String category;
  final String? description;
  final int? totalCycleDays;
  final int isSystemTemplate;
  final int createdByUser;
  final int createdAt;

  RecipeTemplate({
    this.id,
    required this.name,
    required this.category,
    this.description,
    this.totalCycleDays,
    this.isSystemTemplate = 0,
    this.createdByUser = 1,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'total_cycle_days': totalCycleDays,
      'is_system_template': isSystemTemplate,
      'created_by_user': createdByUser,
      'created_at': createdAt,
    };
  }

  factory RecipeTemplate.fromMap(Map<String, dynamic> map) {
    return RecipeTemplate(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      description: map['description'],
      totalCycleDays: map['total_cycle_days'],
      isSystemTemplate: map['is_system_template'] ?? 0,
      createdByUser: map['created_by_user'] ?? 1,
      createdAt: map['created_at'],
    );
  }
}
