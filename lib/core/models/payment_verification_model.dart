import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentVerificationModel {
  final String id;
  final String eventId;
  final String eventTitle;
  final String userId;
  final String userName;
  final String userEmail;
  final double amount;
  final String screenshotUrl;
  final String transactionId;
  final String status; // 'pending', 'verified', 'rejected'
  final String? rejectionReason;
  final String? verifiedBy;
  final DateTime submittedAt;
  final DateTime? verifiedAt;
  final Map<String, dynamic>? notes;

  PaymentVerificationModel({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.amount,
    required this.screenshotUrl,
    required this.transactionId,
    required this.status,
    this.rejectionReason,
    this.verifiedBy,
    required this.submittedAt,
    this.verifiedAt,
    this.notes,
  });

  factory PaymentVerificationModel.fromMap(Map<String, dynamic> map) {
    DateTime _parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    String _normalizeStatus(dynamic value) {
      return (value ?? 'pending').toString().toLowerCase();
    }

    double _toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
      return 0.0;
    }

    return PaymentVerificationModel(
      id: map['id'] ?? '',
      eventId: map['eventId'] ?? '',
      eventTitle: map['eventTitle'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      amount: _toDouble(map['amount']),
      screenshotUrl: map['screenshotUrl'] ?? '',
      transactionId: map['transactionId'] ?? '',
      status: _normalizeStatus(map['status']),
      rejectionReason: map['rejectionReason'],
      verifiedBy: map['verifiedBy'],
      submittedAt: _parseDate(map['submittedAt']),
      verifiedAt: map['verifiedAt'] != null ? _parseDate(map['verifiedAt']) : null,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'amount': amount,
      'screenshotUrl': screenshotUrl,
      'transactionId': transactionId,
      'status': status,
      'rejectionReason': rejectionReason,
      'verifiedBy': verifiedBy,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'notes': notes,
    };
  }

  PaymentVerificationModel copyWith({
    String? id,
    String? eventId,
    String? eventTitle,
    String? userId,
    String? userName,
    String? userEmail,
    double? amount,
    String? screenshotUrl,
    String? transactionId,
    String? status,
    String? rejectionReason,
    String? verifiedBy,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    Map<String, dynamic>? notes,
  }) {
    return PaymentVerificationModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      amount: amount ?? this.amount,
      screenshotUrl: screenshotUrl ?? this.screenshotUrl,
      transactionId: transactionId ?? this.transactionId,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      submittedAt: submittedAt ?? this.submittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      notes: notes ?? this.notes,
    );
  }

  bool get isPending => status == 'pending';
  bool get isVerified => status == 'verified';
  bool get isRejected => status == 'rejected';

  String get formattedAmount => '₹${amount.toStringAsFixed(2)}';
  String get formattedSubmittedAt => 
      '${submittedAt.day}/${submittedAt.month}/${submittedAt.year} at ${submittedAt.hour.toString().padLeft(2, '0')}:${submittedAt.minute.toString().padLeft(2, '0')}';
}
