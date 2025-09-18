// import 'package:cloud_firestore/cloud_firestore.dart';  // Temporarily disabled
import 'package:cloud_firestore/cloud_firestore.dart';  // Re-enabled for Timestamp handling
import 'access_control_model.dart';

enum UserRole { organiser, moderator, attendee }

enum VerificationStatus {
  unverified,
  emailVerified,
  phoneVerified,
  documentVerified,
  fullyVerified,
}

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
  
  // Enhanced fields for access control
  final VerificationStatus verificationStatus;
  final List<UserGroup> userGroups;
  final String? institution; // University, company, etc.
  final String? studentId; // Student ID number
  final String? employeeId; // Employee ID number
  final String? department; // Department/division
  final String? position; // Job title/position
  final String? graduationYear; // For alumni
  final String? major; // For students
  final String? country;
  final String? city;
  final double? latitude; // Current location
  final double? longitude;
  final DateTime? locationUpdatedAt;
  
  // Verification fields
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isDocumentVerified;
  final List<String> verifiedDocuments; // ['student_id', 'employee_badge', etc.]
  final DateTime? emailVerifiedAt;
  final DateTime? phoneVerifiedAt;
  final DateTime? documentVerifiedAt;
  
  // Access control preferences
  final bool allowLocationTracking;
  final bool allowNotifications;
  final List<String> blockedEvents; // Event IDs user is blocked from
  final Map<String, dynamic> customFields; // For custom validation rules

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
    this.verificationStatus = VerificationStatus.unverified,
    this.userGroups = const [],
    this.institution,
    this.studentId,
    this.employeeId,
    this.department,
    this.position,
    this.graduationYear,
    this.major,
    this.country,
    this.city,
    this.latitude,
    this.longitude,
    this.locationUpdatedAt,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.isDocumentVerified = false,
    this.verifiedDocuments = const [],
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    this.documentVerifiedAt,
    this.allowLocationTracking = false,
    this.allowNotifications = true,
    this.blockedEvents = const [],
    this.customFields = const {},
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
      createdAt: _parseDateTime(map['createdAt']),
      lastLoginAt: map['lastLoginAt'] != null ? _parseDateTime(map['lastLoginAt']) : null,
      username: map['username'],
      birthday: map['birthday'] != null ? _parseDateTime(map['birthday']) : null,
      securityQuestion: map['securityQuestion'],
      securityAnswer: map['securityAnswer'],
      verificationStatus: VerificationStatus.values.firstWhere(
        (status) => status.name == map['verificationStatus'],
        orElse: () => VerificationStatus.unverified,
      ),
      userGroups: map['userGroups'] != null 
          ? (map['userGroups'] as List)
              .map((group) => UserGroup.values.firstWhere(
                    (g) => g.name == group,
                    orElse: () => UserGroup.custom,
                  ))
              .toList()
          : [],
      institution: map['institution'],
      studentId: map['studentId'],
      employeeId: map['employeeId'],
      department: map['department'],
      position: map['position'],
      graduationYear: map['graduationYear'],
      major: map['major'],
      country: map['country'],
      city: map['city'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      locationUpdatedAt: map['locationUpdatedAt'] != null ? _parseDateTime(map['locationUpdatedAt']) : null,
      isEmailVerified: map['isEmailVerified'] ?? false,
      isPhoneVerified: map['isPhoneVerified'] ?? false,
      isDocumentVerified: map['isDocumentVerified'] ?? false,
      verifiedDocuments: map['verifiedDocuments'] != null 
          ? List<String>.from(map['verifiedDocuments'])
          : [],
      emailVerifiedAt: map['emailVerifiedAt'] != null ? _parseDateTime(map['emailVerifiedAt']) : null,
      phoneVerifiedAt: map['phoneVerifiedAt'] != null ? _parseDateTime(map['phoneVerifiedAt']) : null,
      documentVerifiedAt: map['documentVerifiedAt'] != null ? _parseDateTime(map['documentVerifiedAt']) : null,
      allowLocationTracking: map['allowLocationTracking'] ?? false,
      allowNotifications: map['allowNotifications'] ?? true,
      blockedEvents: map['blockedEvents'] != null 
          ? List<String>.from(map['blockedEvents'])
          : [],
      customFields: map['customFields'] ?? {},
    );
  }

  // Helper method to parse DateTime from various formats (Firestore Timestamp, DateTime, etc.)
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    if (value is DateTime) {
      return value;
    }
    
    if (value is Timestamp) {
      return value.toDate();
    }
    
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    // Fallback to current time if parsing fails
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'phone': phone,
      'profileImage': profileImage,
      'createdAt': Timestamp.fromDate(createdAt), // Convert to Firestore Timestamp
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'username': username,
      'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
      'securityQuestion': securityQuestion,
      'securityAnswer': securityAnswer,
      'verificationStatus': verificationStatus.name,
      'userGroups': userGroups.map((group) => group.name).toList(),
      'institution': institution,
      'studentId': studentId,
      'employeeId': employeeId,
      'department': department,
      'position': position,
      'graduationYear': graduationYear,
      'major': major,
      'country': country,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'locationUpdatedAt': locationUpdatedAt != null ? Timestamp.fromDate(locationUpdatedAt!) : null,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'isDocumentVerified': isDocumentVerified,
      'verifiedDocuments': verifiedDocuments,
      'emailVerifiedAt': emailVerifiedAt != null ? Timestamp.fromDate(emailVerifiedAt!) : null,
      'phoneVerifiedAt': phoneVerifiedAt != null ? Timestamp.fromDate(phoneVerifiedAt!) : null,
      'documentVerifiedAt': documentVerifiedAt != null ? Timestamp.fromDate(documentVerifiedAt!) : null,
      'allowLocationTracking': allowLocationTracking,
      'allowNotifications': allowNotifications,
      'blockedEvents': blockedEvents,
      'customFields': customFields,
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
    VerificationStatus? verificationStatus,
    List<UserGroup>? userGroups,
    String? institution,
    String? studentId,
    String? employeeId,
    String? department,
    String? position,
    String? graduationYear,
    String? major,
    String? country,
    String? city,
    double? latitude,
    double? longitude,
    DateTime? locationUpdatedAt,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isDocumentVerified,
    List<String>? verifiedDocuments,
    DateTime? emailVerifiedAt,
    DateTime? phoneVerifiedAt,
    DateTime? documentVerifiedAt,
    bool? allowLocationTracking,
    bool? allowNotifications,
    List<String>? blockedEvents,
    Map<String, dynamic>? customFields,
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
      verificationStatus: verificationStatus ?? this.verificationStatus,
      userGroups: userGroups ?? this.userGroups,
      institution: institution ?? this.institution,
      studentId: studentId ?? this.studentId,
      employeeId: employeeId ?? this.employeeId,
      department: department ?? this.department,
      position: position ?? this.position,
      graduationYear: graduationYear ?? this.graduationYear,
      major: major ?? this.major,
      country: country ?? this.country,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationUpdatedAt: locationUpdatedAt ?? this.locationUpdatedAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isDocumentVerified: isDocumentVerified ?? this.isDocumentVerified,
      verifiedDocuments: verifiedDocuments ?? this.verifiedDocuments,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      phoneVerifiedAt: phoneVerifiedAt ?? this.phoneVerifiedAt,
      documentVerifiedAt: documentVerifiedAt ?? this.documentVerifiedAt,
      allowLocationTracking: allowLocationTracking ?? this.allowLocationTracking,
      allowNotifications: allowNotifications ?? this.allowNotifications,
      blockedEvents: blockedEvents ?? this.blockedEvents,
      customFields: customFields ?? this.customFields,
    );
  }

  // Helper methods
  bool get isOrganiser => role == UserRole.organiser;
  bool get isModerator => role == UserRole.moderator;
  bool get isAttendee => role == UserRole.attendee;
  
  // Age calculation
  int? get age {
    if (birthday == null) return null;
    final now = DateTime.now();
    int age = now.year - birthday!.year;
    if (now.month < birthday!.month || 
        (now.month == birthday!.month && now.day < birthday!.day)) {
      age--;
    }
    return age;
  }
  
  // Email domain extraction
  String? get emailDomain {
    if (!email.contains('@')) return null;
    return email.split('@').last.toLowerCase();
  }
  
  // Verification helpers
  bool get isFullyVerified => verificationStatus == VerificationStatus.fullyVerified;
  bool get hasRequiredVerification => isEmailVerified && isPhoneVerified;
  
  // User group helpers
  bool get isStudent => userGroups.contains(UserGroup.students);
  bool get isFaculty => userGroups.contains(UserGroup.faculty);
  bool get isEmployee => userGroups.contains(UserGroup.employees);
  bool get isAlumni => userGroups.contains(UserGroup.alumni);
  bool get isMember => userGroups.contains(UserGroup.members);
  bool get isVip => userGroups.contains(UserGroup.vip);
  
  // Location helpers
  bool get hasLocation => latitude != null && longitude != null;
  bool get isLocationRecent {
    if (locationUpdatedAt == null) return false;
    return DateTime.now().difference(locationUpdatedAt!).inHours < 24;
  }
  
  // Document verification helpers
  bool hasVerifiedDocument(String documentType) {
    return verifiedDocuments.contains(documentType);
  }
  
  // Custom field helpers
  dynamic getCustomField(String key) {
    return customFields[key];
  }
  
  bool hasCustomField(String key) {
    return customFields.containsKey(key);
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, role: $role, verificationStatus: $verificationStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

} 