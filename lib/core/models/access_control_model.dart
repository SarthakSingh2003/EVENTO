// import 'package:cloud_firestore/cloud_firestore.dart';  // Temporarily disabled
import 'package:cloud_firestore/cloud_firestore.dart';  // Re-enabled for Timestamp handling

enum AccessControlType {
  public,                    // Anyone can purchase
  emailDomain,               // Only specific email domains (e.g., @university.edu)
  emailDomainRestricted,     // Email domain restricted (alias for emailDomain)
  userGroup,                 // Specific user groups (students, employees, etc.)
  userGroupRestricted,       // User group restricted (alias for userGroup)
  invitationOnly,            // Only invited users
  ageRestricted,             // Age-based restrictions
  locationBased,             // Geographic restrictions
  customCriteria,            // Custom validation rules
}

enum UserGroup {
  students,
  faculty,
  employees,
  alumni,
  members,
  guests,
  vip,
  custom,
}

class AccessControlModel {
  final String? id;
  final String eventId;
  final AccessControlType type;
  final String name;
  final String description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Email domain restrictions
  final List<String>? allowedEmailDomains;
  final List<String>? blockedEmailDomains;
  
  // User group restrictions
  final List<UserGroup>? allowedUserGroups;
  final List<String>? allowedUserIds; // Specific user IDs
  
  // Age restrictions
  final int? minimumAge;
  final int? maximumAge;
  
  // Location restrictions
  final double? maxDistanceKm; // Maximum distance from event location
  final List<String>? allowedCountries;
  final List<String>? allowedCities;
  
  // Custom validation rules
  final Map<String, dynamic>? customRules;
  final String? validationScript; // For complex validation logic
  
  // Invitation system
  final List<String>? invitedEmails;
  final String? invitationCode;
  final bool requireInvitationCode;
  
  // Verification requirements
  final bool requireEmailVerification;
  final bool requirePhoneVerification;
  final bool requireDocumentVerification;
  final List<String>? requiredDocuments; // ['student_id', 'employee_badge', etc.]
  
  // Access control settings
  final int? maxTicketsPerUser;
  final bool allowWaitlist;
  final int? waitlistCapacity;
  final DateTime? accessStartDate;
  final DateTime? accessEndDate;

  AccessControlModel({
    this.id,
    required this.eventId,
    required this.type,
    required this.name,
    required this.description,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.allowedEmailDomains,
    this.blockedEmailDomains,
    this.allowedUserGroups,
    this.allowedUserIds,
    this.minimumAge,
    this.maximumAge,
    this.maxDistanceKm,
    this.allowedCountries,
    this.allowedCities,
    this.customRules,
    this.validationScript,
    this.invitedEmails,
    this.invitationCode,
    this.requireInvitationCode = false,
    this.requireEmailVerification = false,
    this.requirePhoneVerification = false,
    this.requireDocumentVerification = false,
    this.requiredDocuments,
    this.maxTicketsPerUser,
    this.allowWaitlist = false,
    this.waitlistCapacity,
    this.accessStartDate,
    this.accessEndDate,
  });

  factory AccessControlModel.fromMap(Map<String, dynamic> map) {
    return AccessControlModel(
      id: map['id'],
      eventId: map['eventId'] ?? '',
      type: AccessControlType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => AccessControlType.public,
      ),
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? _parseDateTime(map['updatedAt']) : null,
      allowedEmailDomains: map['allowedEmailDomains'] != null 
          ? List<String>.from(map['allowedEmailDomains'])
          : null,
      blockedEmailDomains: map['blockedEmailDomains'] != null 
          ? List<String>.from(map['blockedEmailDomains'])
          : null,
      allowedUserGroups: map['allowedUserGroups'] != null 
          ? (map['allowedUserGroups'] as List)
              .map((group) => UserGroup.values.firstWhere(
                    (g) => g.name == group,
                    orElse: () => UserGroup.custom,
                  ))
              .toList()
          : null,
      allowedUserIds: map['allowedUserIds'] != null 
          ? List<String>.from(map['allowedUserIds'])
          : null,
      minimumAge: map['minimumAge'],
      maximumAge: map['maximumAge'],
      maxDistanceKm: map['maxDistanceKm']?.toDouble(),
      allowedCountries: map['allowedCountries'] != null 
          ? List<String>.from(map['allowedCountries'])
          : null,
      allowedCities: map['allowedCities'] != null 
          ? List<String>.from(map['allowedCities'])
          : null,
      customRules: map['customRules'],
      validationScript: map['validationScript'],
      invitedEmails: map['invitedEmails'] != null 
          ? List<String>.from(map['invitedEmails'])
          : null,
      invitationCode: map['invitationCode'],
      requireInvitationCode: map['requireInvitationCode'] ?? false,
      requireEmailVerification: map['requireEmailVerification'] ?? false,
      requirePhoneVerification: map['requirePhoneVerification'] ?? false,
      requireDocumentVerification: map['requireDocumentVerification'] ?? false,
      requiredDocuments: map['requiredDocuments'] != null 
          ? List<String>.from(map['requiredDocuments'])
          : null,
      maxTicketsPerUser: map['maxTicketsPerUser'],
      allowWaitlist: map['allowWaitlist'] ?? false,
      waitlistCapacity: map['waitlistCapacity'],
      accessStartDate: map['accessStartDate'] != null ? _parseDateTime(map['accessStartDate']) : null,
      accessEndDate: map['accessEndDate'] != null ? _parseDateTime(map['accessEndDate']) : null,
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
      'eventId': eventId,
      'type': type.name,
      'name': name,
      'description': description,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt), // Convert to Firestore Timestamp
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'allowedEmailDomains': allowedEmailDomains,
      'blockedEmailDomains': blockedEmailDomains,
      'allowedUserGroups': allowedUserGroups?.map((group) => group.name).toList(),
      'allowedUserIds': allowedUserIds,
      'minimumAge': minimumAge,
      'maximumAge': maximumAge,
      'maxDistanceKm': maxDistanceKm,
      'allowedCountries': allowedCountries,
      'allowedCities': allowedCities,
      'customRules': customRules,
      'validationScript': validationScript,
      'invitedEmails': invitedEmails,
      'invitationCode': invitationCode,
      'requireInvitationCode': requireInvitationCode,
      'requireEmailVerification': requireEmailVerification,
      'requirePhoneVerification': requirePhoneVerification,
      'requireDocumentVerification': requireDocumentVerification,
      'requiredDocuments': requiredDocuments,
      'maxTicketsPerUser': maxTicketsPerUser,
      'allowWaitlist': allowWaitlist,
      'waitlistCapacity': waitlistCapacity,
      'accessStartDate': accessStartDate != null ? Timestamp.fromDate(accessStartDate!) : null,
      'accessEndDate': accessEndDate != null ? Timestamp.fromDate(accessEndDate!) : null,
    };
  }

  AccessControlModel copyWith({
    String? id,
    String? eventId,
    AccessControlType? type,
    String? name,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? allowedEmailDomains,
    List<String>? blockedEmailDomains,
    List<UserGroup>? allowedUserGroups,
    List<String>? allowedUserIds,
    int? minimumAge,
    int? maximumAge,
    double? maxDistanceKm,
    List<String>? allowedCountries,
    List<String>? allowedCities,
    Map<String, dynamic>? customRules,
    String? validationScript,
    List<String>? invitedEmails,
    String? invitationCode,
    bool? requireInvitationCode,
    bool? requireEmailVerification,
    bool? requirePhoneVerification,
    bool? requireDocumentVerification,
    List<String>? requiredDocuments,
    int? maxTicketsPerUser,
    bool? allowWaitlist,
    int? waitlistCapacity,
    DateTime? accessStartDate,
    DateTime? accessEndDate,
  }) {
    return AccessControlModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      allowedEmailDomains: allowedEmailDomains ?? this.allowedEmailDomains,
      blockedEmailDomains: blockedEmailDomains ?? this.blockedEmailDomains,
      allowedUserGroups: allowedUserGroups ?? this.allowedUserGroups,
      allowedUserIds: allowedUserIds ?? this.allowedUserIds,
      minimumAge: minimumAge ?? this.minimumAge,
      maximumAge: maximumAge ?? this.maximumAge,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      allowedCountries: allowedCountries ?? this.allowedCountries,
      allowedCities: allowedCities ?? this.allowedCities,
      customRules: customRules ?? this.customRules,
      validationScript: validationScript ?? this.validationScript,
      invitedEmails: invitedEmails ?? this.invitedEmails,
      invitationCode: invitationCode ?? this.invitationCode,
      requireInvitationCode: requireInvitationCode ?? this.requireInvitationCode,
      requireEmailVerification: requireEmailVerification ?? this.requireEmailVerification,
      requirePhoneVerification: requirePhoneVerification ?? this.requirePhoneVerification,
      requireDocumentVerification: requireDocumentVerification ?? this.requireDocumentVerification,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
      maxTicketsPerUser: maxTicketsPerUser ?? this.maxTicketsPerUser,
      allowWaitlist: allowWaitlist ?? this.allowWaitlist,
      waitlistCapacity: waitlistCapacity ?? this.waitlistCapacity,
      accessStartDate: accessStartDate ?? this.accessStartDate,
      accessEndDate: accessEndDate ?? this.accessEndDate,
    );
  }

  // Helper methods
  bool get isPublic => type == AccessControlType.public;
  bool get isEmailDomainRestricted => type == AccessControlType.emailDomain;
  bool get isUserGroupRestricted => type == AccessControlType.userGroup;
  bool get isInvitationOnly => type == AccessControlType.invitationOnly;
  bool get isAgeRestricted => type == AccessControlType.ageRestricted;
  bool get isLocationBased => type == AccessControlType.locationBased;
  bool get isCustomCriteria => type == AccessControlType.customCriteria;

  bool get isAccessTimeValid {
    final now = DateTime.now();
    if (accessStartDate != null && now.isBefore(accessStartDate!)) return false;
    if (accessEndDate != null && now.isAfter(accessEndDate!)) return false;
    return true;
  }

  String get accessTypeDescription {
    switch (type) {
      case AccessControlType.public:
        return 'Public - Anyone can purchase tickets';
      case AccessControlType.emailDomain:
      case AccessControlType.emailDomainRestricted:
        return 'Email Domain Restricted - Only specific email domains';
      case AccessControlType.userGroup:
      case AccessControlType.userGroupRestricted:
        return 'User Group Restricted - Only specific user groups';
      case AccessControlType.invitationOnly:
        return 'Invitation Only - Only invited users';
      case AccessControlType.ageRestricted:
        return 'Age Restricted - Age-based restrictions apply';
      case AccessControlType.locationBased:
        return 'Location Based - Geographic restrictions apply';
      case AccessControlType.customCriteria:
        return 'Custom Criteria - Custom validation rules apply';
    }
  }

  @override
  String toString() {
    return 'AccessControlModel(id: $id, eventId: $eventId, type: $type, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccessControlModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

}
