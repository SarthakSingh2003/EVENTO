// import 'package:cloud_firestore/cloud_firestore.dart';  // Temporarily disabled

enum UserRole { organiser, moderator, attendee }

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? phone;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? username;
  final DateTime? birthday;
  final String? securityQuestion;
  final String? securityAnswer;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.profileImage,
    required this.createdAt,
    this.lastLoginAt,
    this.username,
    this.birthday,
    this.securityQuestion,
    this.securityAnswer,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.name == map['role'],
        orElse: () => UserRole.attendee,
      ),
      phone: map['phone'],
      profileImage: map['profileImage'],
      createdAt: map['createdAt'] is DateTime 
          ? map['createdAt'] 
          : DateTime.now(), // Temporarily simplified
      lastLoginAt: map['lastLoginAt'] is DateTime 
          ? map['lastLoginAt'] 
          : null,
      username: map['username'],
      birthday: map['birthday'] is DateTime 
          ? map['birthday'] 
          : null,
      securityQuestion: map['securityQuestion'],
      securityAnswer: map['securityAnswer'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'phone': phone,
      'profileImage': profileImage,
      'createdAt': createdAt, // Temporarily simplified
      'lastLoginAt': lastLoginAt,
      'username': username,
      'birthday': birthday,
      'securityQuestion': securityQuestion,
      'securityAnswer': securityAnswer,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? phone,
    String? profileImage,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? username,
    DateTime? birthday,
    String? securityQuestion,
    String? securityAnswer,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      username: username ?? this.username,
      birthday: birthday ?? this.birthday,
      securityQuestion: securityQuestion ?? this.securityQuestion,
      securityAnswer: securityAnswer ?? this.securityAnswer,
    );
  }

  bool get isOrganiser => role == UserRole.organiser;
  bool get isModerator => role == UserRole.moderator;
  bool get isAttendee => role == UserRole.attendee;

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 