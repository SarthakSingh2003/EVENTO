// import 'package:cloud_firestore/cloud_firestore.dart';  // Temporarily disabled

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
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

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
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      date: map['date'] is DateTime 
          ? map['date'] 
          : DateTime.now(), // Temporarily simplified
      time: map['time'] is DateTime 
          ? map['time'] 
          : DateTime.now(), // Temporarily simplified
      totalTickets: map['totalTickets'] ?? 0,
      soldTickets: map['soldTickets'] ?? 0,
      price: (map['price'] ?? 0.0).toDouble(),
      isFree: map['isFree'] ?? false,
      organiserId: map['organiserId'] ?? '',
      organiserName: map['organiserName'] ?? '',
      bannerImage: map['bannerImage'],
      category: map['category'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] is DateTime 
          ? map['createdAt'] 
          : DateTime.now(), // Temporarily simplified
      updatedAt: map['updatedAt'] is DateTime 
          ? map['updatedAt'] 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'date': date, // Temporarily simplified
      'time': time, // Temporarily simplified
      'totalTickets': totalTickets,
      'soldTickets': soldTickets,
      'price': price,
      'isFree': isFree,
      'organiserId': organiserId,
      'organiserName': organiserName,
      'bannerImage': bannerImage,
      'category': category,
      'isActive': isActive,
      'createdAt': createdAt, // Temporarily simplified
      'updatedAt': updatedAt,
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
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Computed properties
  int get availableTickets => totalTickets - soldTickets;
  bool get isSoldOut => soldTickets >= totalTickets;
  bool get isUpcoming => date.isAfter(DateTime.now());
  bool get isPast => date.isBefore(DateTime.now());
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
    return '\$${price.toStringAsFixed(2)}';
  }

  // Date formatting
  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  String get formattedTime {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDateTime {
    return '$formattedDate at $formattedTime';
  }

  @override
  String toString() {
    return 'EventModel(id: $id, title: $title, date: $date, organiserId: $organiserId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 