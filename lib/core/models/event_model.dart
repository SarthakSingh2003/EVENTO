// import 'package:cloud_firestore/cloud_firestore.dart';  // Temporarily disabled
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // Re-enabled for Timestamp handling
import 'access_control_model.dart';

class EventModel {
  final String? id;
  final String title;
  final String description;
  final String location;
  final double latitude;
  final double longitude;
  final DateTime date;
  final DateTime time;
  final int totalTickets;
  final int soldTickets;
  final double price;
  final bool isFree;
  final String organiserId;
  final String organiserName;
  final String? bannerImage;
  final String category;
  final List<String> tags; // New: Event tags for search and filtering
  final bool isActive;
  final bool isFeatured; // New: Featured events for carousel
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? venueDetails; // New: Additional venue information
  final String? eventType; // New: Online/Offline/Hybrid
  final int? maxAttendees; // New: Maximum attendees limit
  final String? contactInfo; // New: Contact information
  final String? website; // New: Event website
  final List<String>? socialMedia; // New: Social media links
  
  // Payments
  final String? paymentQrUrl; // New: QR image URL for manual payments
  
  // Access Control Fields
  final AccessControlModel? accessControl; // New: Access control settings
  final bool requiresAccessControl; // New: Whether access control is enabled
  final String? accessControlId; // New: Reference to access control document
  final bool isPrivate; // New: Private event flag
  final List<String>? allowedUserIds; // New: Specific users allowed (for private events)
  final String? invitationCode; // New: Public invitation code for private events

  EventModel({
    this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.date,
    required this.time,
    required this.totalTickets,
    this.soldTickets = 0,
    required this.price,
    required this.isFree,
    required this.organiserId,
    required this.organiserName,
    this.bannerImage,
    required this.category,
    this.tags = const [], // Default empty tags
    this.isActive = true,
    this.isFeatured = false, // Default not featured
    required this.createdAt,
    this.updatedAt,
    this.venueDetails,
    this.eventType,
    this.maxAttendees,
    this.contactInfo,
    this.website,
    this.socialMedia,
    this.paymentQrUrl,
    this.accessControl,
    this.requiresAccessControl = false,
    this.accessControlId,
    this.isPrivate = false,
    this.allowedUserIds,
    this.invitationCode,
  });

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      date: _parseDateTime(map['date']),
      time: _parseDateTime(map['time']),
      totalTickets: map['totalTickets'] ?? 0,
      soldTickets: map['soldTickets'] ?? 0,
      price: (map['price'] ?? 0.0).toDouble(),
      isFree: map['isFree'] ?? false,
      organiserId: map['organiserId'] ?? '',
      organiserName: map['organiserName'] ?? '',
      bannerImage: map['bannerImage'],
      category: map['category'] ?? '',
      tags: List<String>.from(map['tags'] ?? []), // Parse tags list
      isActive: map['isActive'] ?? true,
      isFeatured: map['isFeatured'] ?? false, // Parse featured status
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? _parseDateTime(map['updatedAt']) : null,
      venueDetails: map['venueDetails'],
      eventType: map['eventType'],
      maxAttendees: map['maxAttendees'],
      contactInfo: map['contactInfo'],
      website: map['website'],
      socialMedia: map['socialMedia'] != null 
          ? List<String>.from(map['socialMedia'])
          : null,
      paymentQrUrl: map['paymentQrUrl'],
      accessControl: map['accessControl'] != null 
          ? AccessControlModel.fromMap(map['accessControl'])
          : null,
      requiresAccessControl: map['requiresAccessControl'] ?? false,
      accessControlId: map['accessControlId'],
      isPrivate: map['isPrivate'] ?? false,
      allowedUserIds: map['allowedUserIds'] != null 
          ? List<String>.from(map['allowedUserIds'])
          : null,
      invitationCode: map['invitationCode'],
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
      'title': title,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'date': Timestamp.fromDate(date), // Convert to Firestore Timestamp
      'time': Timestamp.fromDate(time), // Convert to Firestore Timestamp
      'totalTickets': totalTickets,
      'soldTickets': soldTickets,
      'price': price,
      'isFree': isFree,
      'organiserId': organiserId,
      'organiserName': organiserName,
      'bannerImage': bannerImage,
      'category': category,
      'tags': tags, // Include tags
      'isActive': isActive,
      'isFeatured': isFeatured, // Include featured status
      'createdAt': Timestamp.fromDate(createdAt), // Convert to Firestore Timestamp
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'venueDetails': venueDetails,
      'eventType': eventType,
      'maxAttendees': maxAttendees,
      'contactInfo': contactInfo,
      'website': website,
      'socialMedia': socialMedia,
      'paymentQrUrl': paymentQrUrl,
      'accessControl': accessControl?.toMap(),
      'requiresAccessControl': requiresAccessControl,
      'accessControlId': accessControlId,
      'isPrivate': isPrivate,
      'allowedUserIds': allowedUserIds,
      'invitationCode': invitationCode,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? date,
    DateTime? time,
    int? totalTickets,
    int? soldTickets,
    double? price,
    bool? isFree,
    String? organiserId,
    String? organiserName,
    String? bannerImage,
    String? category,
    List<String>? tags,
    bool? isActive,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? venueDetails,
    String? eventType,
    int? maxAttendees,
    String? contactInfo,
    String? website,
    List<String>? socialMedia,
    String? paymentQrUrl,
    AccessControlModel? accessControl,
    bool? requiresAccessControl,
    String? accessControlId,
    bool? isPrivate,
    List<String>? allowedUserIds,
    String? invitationCode,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      date: date ?? this.date,
      time: time ?? this.time,
      totalTickets: totalTickets ?? this.totalTickets,
      soldTickets: soldTickets ?? this.soldTickets,
      price: price ?? this.price,
      isFree: isFree ?? this.isFree,
      organiserId: organiserId ?? this.organiserId,
      organiserName: organiserName ?? this.organiserName,
      bannerImage: bannerImage ?? this.bannerImage,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      venueDetails: venueDetails ?? this.venueDetails,
      eventType: eventType ?? this.eventType,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      contactInfo: contactInfo ?? this.contactInfo,
      website: website ?? this.website,
      socialMedia: socialMedia ?? this.socialMedia,
      paymentQrUrl: paymentQrUrl ?? this.paymentQrUrl,
      accessControl: accessControl ?? this.accessControl,
      requiresAccessControl: requiresAccessControl ?? this.requiresAccessControl,
      accessControlId: accessControlId ?? this.accessControlId,
      isPrivate: isPrivate ?? this.isPrivate,
      allowedUserIds: allowedUserIds ?? this.allowedUserIds,
      invitationCode: invitationCode ?? this.invitationCode,
    );
  }

  // Computed properties
  int get capacity {
    // Prefer organiser-defined totalTickets; fall back to maxAttendees when totalTickets is not set (>0)
    if (totalTickets > 0) return totalTickets;
    return maxAttendees ?? 0;
  }
  int get availableTickets {
    final remaining = capacity - soldTickets;
    return remaining < 0 ? 0 : remaining;
  }
  bool get hasUnlimitedCapacity => false; // no unlimited mode
  bool get isSoldOut => capacity > 0 && soldTickets >= capacity;
  bool get isUpcoming => date.isAfter(DateTime.now());
  bool get isPast => date.isBefore(DateTime.now());
  bool get isToday => date.year == DateTime.now().year && 
                      date.month == DateTime.now().month && 
                      date.day == DateTime.now().day;
  DateTime get eventDateTime => DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

  // Price formatting
  String get formattedPrice {
    if (isFree) return 'Free';
    return '₹${price.toStringAsFixed(2)}';
  }

  // Date formatting
  String get formattedDate {
    // Show the actual event date instead of relative time
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Time formatting
  String get formattedTime {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Full date and time together
  String get formattedDateTime {
    return '${formattedDate} at ${formattedTime}';
  }

  // Short date format (MM/DD/YYYY)
  String get shortDate {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }

  // Day of week
  String get dayOfWeek {
    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 
      'Friday', 'Saturday', 'Sunday'
    ];
    // DateTime.weekday returns 1-7 (Monday = 1)
    return days[date.weekday - 1];
  }

  // Tags formatting for display
  String get tagsDisplay {
    if (tags.isEmpty) return 'No tags';
    return tags.take(3).join(', ') + (tags.length > 3 ? '...' : '');
  }

  // Event status
  String get status {
    if (isSoldOut) return 'Sold Out';
    if (isPast) return 'Past Event - Tickets Available';
    if (isToday) return 'Today';
    if (isUpcoming) return 'Upcoming';
    return 'Unknown';
  }

  // Category color (for UI)
  int get categoryColor {
    switch (category.toLowerCase()) {
      case 'music':
        return 0xFF9C27B0; // Purple
      case 'technology':
        return 0xFF2196F3; // Blue
      case 'business':
        return 0xFFF44336; // Red
      case 'education':
        return 0xFF3F51B5; // Indigo
      case 'sports':
        return 0xFFFF9800; // Orange
      case 'arts & culture':
        return 0xFF4CAF50; // Green
      case 'food & drink':
        return 0xFFFF5722; // Deep Orange
      case 'health & wellness':
        return 0xFF009688; // Teal
      case 'entertainment':
        return 0xFFE91E63; // Pink
      default:
        return 0xFF607D8B; // Blue Grey
    }
  }

  // Category icon (for UI)
  IconData get categoryIcon {
    switch (category.toLowerCase()) {
      case 'music':
        return Icons.music_note;
      case 'technology':
        return Icons.computer;
      case 'business':
        return Icons.business;
      case 'education':
        return Icons.school;
      case 'sports':
        return Icons.sports_soccer;
      case 'arts & culture':
        return Icons.palette;
      case 'food & drink':
        return Icons.restaurant;
      case 'health & wellness':
        return Icons.favorite;
      case 'entertainment':
        return Icons.movie;
      default:
        return Icons.event;
    }
  }

  // Access Control Helpers
  bool get hasAccessControl => accessControl != null && requiresAccessControl;
  bool get isPublicEvent => !isPrivate && !hasAccessControl;
  bool get isRestrictedEvent => hasAccessControl || isPrivate;
  
  String get accessControlDescription {
    if (!hasAccessControl) return 'Public event - anyone can attend';
    return accessControl!.accessTypeDescription;
  }
  
  bool isUserAllowed(String userId) {
    if (isPublicEvent) return true;
    if (allowedUserIds?.contains(userId) == true) return true;
    return false;
  }

  @override
  String toString() {
    return 'EventModel(id: $id, title: $title, category: $category, isPrivate: $isPrivate, hasAccessControl: $hasAccessControl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 