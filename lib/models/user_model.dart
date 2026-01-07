class UserModel {
  final int id;
  final String username;
  final String email;
  final String? token;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.token,
    this.createdAt,
  });

  // From JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      token: json['token'],
      createdAt: json['created_at'],
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'token': token,
      'created_at': createdAt,
    };
  }

  // To Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'token': token ?? '',
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  // Copy with
  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? token,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}