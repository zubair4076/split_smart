import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String username;
  final List<String> groupIds;
  final DateTime createdAt;
  final DateTime lastLogin;
  final String? photoUrl;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.groupIds,
    required this.createdAt,
    required this.lastLogin,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'groupIds': groupIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'photoUrl': photoUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      groupIds: List<String>.from(map['groupIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLogin: (map['lastLogin'] as Timestamp).toDate(),
      photoUrl: map['photoUrl'],
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    List<String>? groupIds,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? photoUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      groupIds: groupIds ?? this.groupIds,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
} 