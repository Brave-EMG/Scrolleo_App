class User {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? role;
  final String? jwtToken;
  final bool isDirector;
  final List<String> favoriteMovieIds;
  final List<String> watchHistoryIds;
  final int coins;
  final String? profilePicture;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.role,
    this.jwtToken,
    this.isDirector = false,
    this.favoriteMovieIds = const [],
    this.watchHistoryIds = const [],
    required this.coins,
    this.profilePicture,
    required this.createdAt,
    required this.updatedAt,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    bool? isDirector,
    List<String>? favoriteMovieIds,
    List<String>? watchHistoryIds,
    String? role,
    String? jwtToken,
    int? coins,
    String? profilePicture,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isDirector: isDirector ?? this.isDirector,
      favoriteMovieIds: favoriteMovieIds ?? this.favoriteMovieIds,
      watchHistoryIds: watchHistoryIds ?? this.watchHistoryIds,
      role: role ?? this.role,
      jwtToken: jwtToken ?? this.jwtToken,
      coins: coins ?? this.coins,
      profilePicture: profilePicture ?? this.profilePicture,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': role,
      'token': jwtToken,
      'isDirector': isDirector,
      'favoriteMovieIds': favoriteMovieIds,
      'watchHistoryIds': watchHistoryIds,
      'coins': coins,
      'profile_picture': profilePicture,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? '',
      name: json['username'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photoUrl'],
      role: json['role'],
      jwtToken: json['token'],
      isDirector: json['isDirector'] ?? json['role'] == 'realisateur',
      favoriteMovieIds: List<String>.from(json['favoriteMovieIds'] ?? []),
      watchHistoryIds: List<String>.from(json['watchHistoryIds'] ?? []),
      coins: json['coins'] ?? 0,
      profilePicture: json['profile_picture'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, role: $role, isDirector: $isDirector)';
  }
} 