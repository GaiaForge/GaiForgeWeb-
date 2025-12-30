class User {
  final int? id;
  final String username;
  final String pin; // Encrypted or hashed in a real app, simple PIN for now
  final String role; // 'basic', 'elevated', 'developer'
  final int createdAt;
  final int? lastLogin;

  User({
    this.id,
    required this.username,
    required this.pin,
    required this.role,
    required this.createdAt,
    this.lastLogin,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      pin: map['pin'] as String,
      role: map['role'] as String,
      createdAt: map['created_at'] as int,
      lastLogin: map['last_login'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'pin': pin,
      'role': role,
      'created_at': createdAt,
      'last_login': lastLogin,
    };
  }

  // Helper to check permissions
  bool get isDeveloper => role == 'developer';
  bool get isElevated => role == 'elevated' || role == 'developer';
  bool get canModify => isElevated;
}
