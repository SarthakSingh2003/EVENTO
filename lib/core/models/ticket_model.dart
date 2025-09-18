// import 'package:cloud_firestore/cloud_firestore.dart';  // Temporarily disabled
import 'package:cloud_firestore/cloud_firestore.dart';  // Re-enabled for Timestamp handling

class TicketModel {
  final String? id;
  final String eventId;
  final String eventTitle;
  final String userId;
  final String userName;
  final String qrCode;
  final double price;
  final bool isFree;
  final bool isUsed;
  final DateTime purchasedAt;
  final DateTime? usedAt;
  final String? transactionId;

  TicketModel({
    this.id,
    required this.eventId,
    required this.eventTitle,
    required this.userId,
    required this.userName,
    required this.qrCode,
    required this.price,
    required this.isFree,
    this.isUsed = false,
    required this.purchasedAt,
    this.usedAt,
    this.transactionId,
  });

  factory TicketModel.fromMap(Map<String, dynamic> map) {
    return TicketModel(
      id: map['id'],
      eventId: map['eventId'] ?? '',
      eventTitle: map['eventTitle'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      qrCode: map['qrCode'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      isFree: map['isFree'] ?? false,
      isUsed: map['isUsed'] ?? false,
      purchasedAt: _parseDateTime(map['purchasedAt']),
      usedAt: map['usedAt'] != null ? _parseDateTime(map['usedAt']) : null,
      transactionId: map['transactionId'],
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
      'eventTitle': eventTitle,
      'userId': userId,
      'userName': userName,
      'qrCode': qrCode,
      'price': price,
      'isFree': isFree,
      'isUsed': isUsed,
      'purchasedAt': Timestamp.fromDate(purchasedAt), // Convert to Firestore Timestamp
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
      'transactionId': transactionId,
    };
  }

  TicketModel copyWith({
    String? id,
    String? eventId,
    String? eventTitle,
    String? userId,
    String? userName,
    String? qrCode,
    double? price,
    bool? isFree,
    bool? isUsed,
    DateTime? purchasedAt,
    DateTime? usedAt,
    String? transactionId,
  }) {
    return TicketModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      qrCode: qrCode ?? this.qrCode,
      price: price ?? this.price,
      isFree: isFree ?? this.isFree,
      isUsed: isUsed ?? this.isUsed,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      usedAt: usedAt ?? this.usedAt,
      transactionId: transactionId ?? this.transactionId,
    );
  }

  // Computed properties
  bool get isValid => !isUsed;
  String get formattedPrice {
    if (isFree) return 'Free';
    return '₹${price.toStringAsFixed(2)}';
  }

  String get formattedPurchaseDate {
    return '${purchasedAt.day}/${purchasedAt.month}/${purchasedAt.year}';
  }

  String get formattedPurchaseTime {
    return '${purchasedAt.hour.toString().padLeft(2, '0')}:${purchasedAt.minute.toString().padLeft(2, '0')}';
  }

  String get status {
    if (isUsed) return 'Used';
    return 'Valid';
  }

  @override
  String toString() {
    return 'TicketModel(id: $id, eventTitle: $eventTitle, qrCode: $qrCode, isUsed: $isUsed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TicketModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 