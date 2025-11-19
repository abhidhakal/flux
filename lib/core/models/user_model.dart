import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final Map<String, dynamic> preferences;
  final bool isEmailVerified;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    this.preferences = const {},
    this.isEmailVerified = false,
  });

  bool get isPremium => (preferences['isPremium'] as bool?) ?? false;

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
    bool? isEmailVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'preferences': preferences,
      'isEmailVerified': isEmailVerified,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        createdAt,
        lastLoginAt,
        preferences,
        isEmailVerified,
      ];
}
