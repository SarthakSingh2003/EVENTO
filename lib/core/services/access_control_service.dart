import 'dart:math' as math;
import '../models/access_control_model.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';

class AccessControlValidationResult {
  final bool isEligible;
  final String? reason;
  final List<String> requirements;
  final bool requiresAction;
  final String? actionRequired;

  AccessControlValidationResult({
    required this.isEligible,
    this.reason,
    this.requirements = const [],
    this.requiresAction = false,
    this.actionRequired,
  });
}

class AccessControlService {
  static const double _earthRadius = 6371; // Earth's radius in kilometers

  /// Validates if a user can purchase tickets for an event
  static Future<AccessControlValidationResult> validateUserAccess({
    required UserModel user,
    required EventModel event,
    required AccessControlModel? accessControl,
    String? invitationCode,
    int requestedTickets = 1,
  }) async {
    // If no access control is set, allow access
    if (accessControl == null || !accessControl.isActive) {
      return AccessControlValidationResult(
        isEligible: true,
        reason: 'No access restrictions applied',
      );
    }

    // Check if access control is within valid time range
    if (!accessControl.isAccessTimeValid) {
      return AccessControlValidationResult(
        isEligible: false,
        reason: 'Ticket sales are not currently available for this event',
        requirements: ['Wait for ticket sales to open'],
      );
    }

    // Check if user is blocked from this event
    if (user.blockedEvents.contains(event.id)) {
      return AccessControlValidationResult(
        isEligible: false,
        reason: 'You are not allowed to purchase tickets for this event',
        requirements: ['Contact event organizer for assistance'],
      );
    }

    // Validate based on access control type
    switch (accessControl.type) {
      case AccessControlType.public:
        return _validatePublicAccess(user, event, accessControl, requestedTickets);
      
      case AccessControlType.emailDomain:
      case AccessControlType.emailDomainRestricted:
        return _validateEmailDomainAccess(user, event, accessControl, requestedTickets);
      
      case AccessControlType.userGroup:
      case AccessControlType.userGroupRestricted:
        return _validateUserGroupAccess(user, event, accessControl, requestedTickets);
      
      case AccessControlType.invitationOnly:
        return _validateInvitationAccess(user, event, accessControl, invitationCode, requestedTickets);
      
      case AccessControlType.ageRestricted:
        return _validateAgeRestrictedAccess(user, event, accessControl, requestedTickets);
      
      case AccessControlType.locationBased:
        return _validateLocationBasedAccess(user, event, accessControl, requestedTickets);
      
      case AccessControlType.customCriteria:
        return _validateCustomCriteriaAccess(user, event, accessControl, requestedTickets);
    }
  }

  /// Validates public access (no restrictions)
  static AccessControlValidationResult _validatePublicAccess(
    UserModel user,
    EventModel event,
    AccessControlModel accessControl,
    int requestedTickets,
  ) {
    return AccessControlValidationResult(
      isEligible: true,
      reason: 'Public event - anyone can purchase tickets',
    );
  }

  /// Validates email domain restrictions
  static AccessControlValidationResult _validateEmailDomainAccess(
    UserModel user,
    EventModel event,
    AccessControlModel accessControl,
    int requestedTickets,
  ) {
    final userDomain = user.emailDomain;
    if (userDomain == null) {
      return AccessControlValidationResult(
        isEligible: false,
        reason: 'Invalid email address',
        requirements: ['Provide a valid email address'],
      );
    }

    // Check blocked domains first
    if (accessControl.blockedEmailDomains?.contains(userDomain) == true) {
      return AccessControlValidationResult(
        isEligible: false,
        reason: 'Your email domain is not allowed for this event',
        requirements: ['Use a different email address'],
      );
    }

    // Check allowed domains
    if (accessControl.allowedEmailDomains?.isNotEmpty == true) {
      if (!accessControl.allowedEmailDomains!.contains(userDomain)) {
        return AccessControlValidationResult(
          isEligible: false,
          reason: 'Only specific email domains are allowed for this event',
          requirements: [
            'Use an email from one of these domains: ${accessControl.allowedEmailDomains!.join(', ')}'
          ],
        );
      }
    }

    return AccessControlValidationResult(
      isEligible: true,
      reason: 'Email domain validation passed',
    );
  }

  /// Validates user group restrictions
  static AccessControlValidationResult _validateUserGroupAccess(
    UserModel user,
    EventModel event,
    AccessControlModel accessControl,
    int requestedTickets,
  ) {
    if (accessControl.allowedUserGroups?.isEmpty == true) {
      return AccessControlValidationResult(
        isEligible: false,
        reason: 'No user groups are allowed for this event',
        requirements: ['Contact event organizer for access'],
      );
    }

    // Check if user belongs to any allowed group
    final hasAllowedGroup = accessControl.allowedUserGroups!.any(
      (group) => user.userGroups.contains(group),
    );

    if (!hasAllowedGroup) {
      return AccessControlValidationResult(
        isEligible: false,
        reason: 'You do not belong to the required user groups for this event',
        requirements: [
          'Required groups: ${accessControl.allowedUserGroups!.map((g) => g.toString().split('.').last).join(', ')}',
          'Update your profile with the required information',
        ],
        requiresAction: true,
        actionRequired: 'Update user profile',
      );
    }

    return AccessControlValidationResult(
      isEligible: true,
      reason: 'User group validation passed',
    );
  }

  /// Validates invitation-only access
  static AccessControlValidationResult _validateInvitationAccess(
    UserModel user,
    EventModel event,
    AccessControlModel accessControl,
    String? invitationCode,
    int requestedTickets,
  ) {
    // Check if user is in invited emails list
    if (accessControl.invitedEmails?.contains(user.email) == true) {
      return AccessControlValidationResult(
        isEligible: true,
        reason: 'You are invited to this event',
      );
    }

    // Check invitation code if required
    if (accessControl.requireInvitationCode) {
      if (invitationCode == null || invitationCode.isEmpty) {
        return AccessControlValidationResult(
          isEligible: false,
          reason: 'Invitation code is required for this event',
          requirements: ['Enter a valid invitation code'],
          requiresAction: true,
          actionRequired: 'Enter invitation code',
        );
      }

      if (invitationCode != accessControl.invitationCode) {
        return AccessControlValidationResult(
          isEligible: false,
          reason: 'Invalid invitation code',
          requirements: ['Enter the correct invitation code'],
          requiresAction: true,
          actionRequired: 'Enter correct invitation code',
        );
      }
    }

    return AccessControlValidationResult(
      isEligible: true,
      reason: 'Invitation validation passed',
    );
  }

  /// Validates age restrictions
  static AccessControlValidationResult _validateAgeRestrictedAccess(
    UserModel user,
    EventModel event,
    AccessControlModel accessControl,
    int requestedTickets,
  ) {
    final userAge = user.age;
    if (userAge == null) {
      return AccessControlValidationResult(
        isEligible: false,
        reason: 'Age verification required',
        requirements: ['Add your date of birth to your profile'],
        requiresAction: true,
        actionRequired: 'Update profile with date of birth',
      );
    }

    if (accessControl.minimumAge != null && userAge < accessControl.minimumAge!) {
      return AccessControlValidationResult(
        isEligible: false,
        reason: 'You must be at least ${accessControl.minimumAge} years old',
        requirements: ['Minimum age: ${accessControl.minimumAge} years'],
      );
    }

    if (accessControl.maximumAge != null && userAge > accessControl.maximumAge!) {
      return AccessControlValidationResult(
        isEligible: false,
        reason: 'You must be ${accessControl.maximumAge} years old or younger',
        requirements: ['Maximum age: ${accessControl.maximumAge} years'],
      );
    }

    return AccessControlValidationResult(
      isEligible: true,
      reason: 'Age validation passed',
    );
  }

  /// Validates location-based restrictions
  static AccessControlValidationResult _validateLocationBasedAccess(
    UserModel user,
    EventModel event,
    AccessControlModel accessControl,
    int requestedTickets,
  ) {
    // Check if user has location data
    if (!user.hasLocation || !user.isLocationRecent) {
      return AccessControlValidationResult(
        isEligible: false,
        reason: 'Location verification required',
        requirements: ['Enable location tracking and update your location'],
        requiresAction: true,
        actionRequired: 'Enable location tracking',
      );
    }

    // Check country restrictions
    if (accessControl.allowedCountries?.isNotEmpty == true) {
      if (user.country == null || !accessControl.allowedCountries!.contains(user.country)) {
        return AccessControlValidationResult(
          isEligible: false,
          reason: 'This event is only available in specific countries',
          requirements: ['Available countries: ${accessControl.allowedCountries!.join(', ')}'],
        );
      }
    }

    // Check city restrictions
    if (accessControl.allowedCities?.isNotEmpty == true) {
      if (user.city == null || !accessControl.allowedCities!.contains(user.city)) {
        return AccessControlValidationResult(
          isEligible: false,
          reason: 'This event is only available in specific cities',
          requirements: ['Available cities: ${accessControl.allowedCities!.join(', ')}'],
        );
      }
    }

    // Check distance restrictions
    if (accessControl.maxDistanceKm != null) {
      final distance = _calculateDistance(
        user.latitude!,
        user.longitude!,
        event.latitude,
        event.longitude,
      );

      if (distance > accessControl.maxDistanceKm!) {
        return AccessControlValidationResult(
          isEligible: false,
          reason: 'You are too far from the event location',
          requirements: [
            'Maximum distance: ${accessControl.maxDistanceKm} km',
            'Your distance: ${distance.toStringAsFixed(1)} km',
          ],
        );
      }
    }

    return AccessControlValidationResult(
      isEligible: true,
      reason: 'Location validation passed',
    );
  }

  /// Validates custom criteria
  static AccessControlValidationResult _validateCustomCriteriaAccess(
    UserModel user,
    EventModel event,
    AccessControlModel accessControl,
    int requestedTickets,
  ) {
    final requirements = <String>[];

    // Check verification requirements
    if (accessControl.requireEmailVerification && !user.isEmailVerified) {
      requirements.add('Email verification required');
    }

    if (accessControl.requirePhoneVerification && !user.isPhoneVerified) {
      requirements.add('Phone verification required');
    }

    if (accessControl.requireDocumentVerification && !user.isDocumentVerified) {
      requirements.add('Document verification required');
    }

    // Check required documents
    if (accessControl.requiredDocuments?.isNotEmpty == true) {
      for (final document in accessControl.requiredDocuments!) {
        if (!user.hasVerifiedDocument(document)) {
          requirements.add('Verified $document required');
        }
      }
    }

    if (requirements.isNotEmpty) {
      return AccessControlValidationResult(
        isEligible: false,
        reason: 'Additional verification required',
        requirements: requirements,
        requiresAction: true,
        actionRequired: 'Complete verification requirements',
      );
    }

    // Execute custom validation script if provided
    if (accessControl.validationScript?.isNotEmpty == true) {
      // This would typically involve a secure script execution environment
      // For now, we'll implement basic custom rule evaluation
      final isValid = _evaluateCustomRules(user, accessControl.customRules);
      if (!isValid) {
        return AccessControlValidationResult(
          isEligible: false,
          reason: 'Custom validation failed',
          requirements: ['Meet custom event requirements'],
        );
      }
    }

    return AccessControlValidationResult(
      isEligible: true,
      reason: 'Custom criteria validation passed',
    );
  }

  /// Calculates distance between two points using Haversine formula
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return _earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Evaluates custom validation rules
  static bool _evaluateCustomRules(UserModel user, Map<String, dynamic>? rules) {
    if (rules == null || rules.isEmpty) return true;

    // Example custom rule evaluation
    // This is a simplified implementation - in production, you'd want a more robust rule engine
    
    for (final entry in rules.entries) {
      final field = entry.key;
      final expectedValue = entry.value;
      
      switch (field) {
        case 'institution':
          if (user.institution != expectedValue) return false;
          break;
        case 'department':
          if (user.department != expectedValue) return false;
          break;
        case 'major':
          if (user.major != expectedValue) return false;
          break;
        case 'graduationYear':
          if (user.graduationYear != expectedValue) return false;
          break;
        case 'hasStudentId':
          if (expectedValue == true && user.studentId == null) return false;
          break;
        case 'hasEmployeeId':
          if (expectedValue == true && user.employeeId == null) return false;
          break;
        default:
          // Check custom fields
          if (user.getCustomField(field) != expectedValue) return false;
          break;
      }
    }
    
    return true;
  }

  /// Gets a user-friendly description of access requirements
  static String getAccessRequirementsDescription(AccessControlModel accessControl) {
    switch (accessControl.type) {
      case AccessControlType.public:
        return 'This event is open to everyone.';
      
      case AccessControlType.emailDomain:
      case AccessControlType.emailDomainRestricted:
        if (accessControl.allowedEmailDomains?.isNotEmpty == true) {
          return 'Only users with emails from these domains: ${accessControl.allowedEmailDomains!.join(', ')}';
        }
        return 'Email domain restrictions apply.';
      
      case AccessControlType.userGroup:
      case AccessControlType.userGroupRestricted:
        if (accessControl.allowedUserGroups?.isNotEmpty == true) {
          return 'Only for: ${accessControl.allowedUserGroups!.map((g) => g.name).join(', ')}';
        }
        return 'User group restrictions apply.';
      
      case AccessControlType.invitationOnly:
        return 'This event is invitation only.';
      
      case AccessControlType.ageRestricted:
        final requirements = <String>[];
        if (accessControl.minimumAge != null) {
          requirements.add('Minimum age: ${accessControl.minimumAge}');
        }
        if (accessControl.maximumAge != null) {
          requirements.add('Maximum age: ${accessControl.maximumAge}');
        }
        return 'Age restrictions: ${requirements.join(', ')}';
      
      case AccessControlType.locationBased:
        final requirements = <String>[];
        if (accessControl.maxDistanceKm != null) {
          requirements.add('Within ${accessControl.maxDistanceKm} km');
        }
        if (accessControl.allowedCountries?.isNotEmpty == true) {
          requirements.add('Countries: ${accessControl.allowedCountries!.join(', ')}');
        }
        return 'Location restrictions: ${requirements.join(', ')}';
      
      case AccessControlType.customCriteria:
        return 'Custom requirements apply. Please check your eligibility.';
    }
  }

  /// Checks if user needs to complete any verification steps
  static List<String> getRequiredVerifications(
    UserModel user,
    AccessControlModel accessControl,
  ) {
    final requirements = <String>[];

    if (accessControl.requireEmailVerification && !user.isEmailVerified) {
      requirements.add('Email verification');
    }

    if (accessControl.requirePhoneVerification && !user.isPhoneVerified) {
      requirements.add('Phone verification');
    }

    if (accessControl.requireDocumentVerification && !user.isDocumentVerified) {
      requirements.add('Document verification');
    }

    if (accessControl.requiredDocuments?.isNotEmpty == true) {
      for (final document in accessControl.requiredDocuments!) {
        if (!user.hasVerifiedDocument(document)) {
          requirements.add('$document verification');
        }
      }
    }

    return requirements;
  }
}
