class GuardianEquipmentNote {
  final int? id;
  final int zoneId;
  final String note;
  final String category; // 'normal_behavior', 'known_issue', 'quirk'
  final int createdAt;

  GuardianEquipmentNote({
    this.id,
    required this.zoneId,
    required this.note,
    required this.category,
    required this.createdAt,
  });

  factory GuardianEquipmentNote.fromMap(Map<String, dynamic> map) {
    return GuardianEquipmentNote(
      id: map['id'] as int?,
      zoneId: map['zone_id'] as int,
      note: map['note'] as String,
      category: map['category'] as String,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'note': note,
      'category': category,
      'created_at': createdAt,
    };
  }
}
