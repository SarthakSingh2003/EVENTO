import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class RefundService {
  // Note: This service now handles manual refunds for QR code payments
  // Refunds need to be processed manually by the organizer
  
  /// Process refund for a ticket (Manual refund for QR payments)
  static Future<Map<String, dynamic>> processRefund({
    required String paymentId,
    required double amount,
    required String reason,
    required String eventId,
    required String userId,
    required String ticketId,
  }) async {
    try {
      // Generate a manual refund ID
      final refundId = 'REFUND_${DateTime.now().millisecondsSinceEpoch}';
      
      // Update ticket status
      await _updateTicketForRefund(ticketId, refundId);
      
      // Update event ticket counts
      await _updateEventTicketCounts(eventId);
      
      // Create refund record
      await _createRefundRecord(
        refundId: refundId,
        paymentId: paymentId,
        ticketId: ticketId,
        eventId: eventId,
        userId: userId,
        amount: amount,
        reason: reason,
      );
      
      return {
        'success': true,
        'refundId': refundId,
        'amount': amount,
        'status': 'processed',
        'note': 'Manual refund processed. Organizer needs to process actual payment refund.',
      };
    } catch (e) {
      throw Exception('Error processing refund: $e');
    }
  }
  
  /// Create manual refund record (for QR code payments)
  static Future<Map<String, dynamic>> _createManualRefund({
    required String paymentId,
    required double amount,
    required String reason,
  }) async {
    try {
      // For QR code payments, we just create a record
      // The actual refund needs to be processed manually by the organizer
      final refundId = 'REFUND_${DateTime.now().millisecondsSinceEpoch}';
      
      return {
        'success': true,
        'refundId': refundId,
        'amount': amount,
        'status': 'pending_manual_processing',
        'note': 'Manual refund required - organizer needs to process actual payment refund',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Update ticket for refund
  static Future<void> _updateTicketForRefund(String ticketId, String refundId) async {
    await FirebaseFirestore.instance
        .collection('tickets')
        .doc(ticketId)
        .update({
      'isRefunded': true,
      'refundId': refundId,
      'refundedAt': FieldValue.serverTimestamp(),
      'status': 'cancelled',
    });
  }
  
  /// Update event ticket counts after refund
  static Future<void> _updateEventTicketCounts(String eventId) async {
    await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .update({
      'availableTickets': FieldValue.increment(1),
      'soldTickets': FieldValue.increment(-1),
    });
  }
  
  /// Create refund record
  static Future<void> _createRefundRecord({
    required String refundId,
    required String paymentId,
    required String ticketId,
    required String eventId,
    required String userId,
    required double amount,
    required String reason,
  }) async {
    await FirebaseFirestore.instance
        .collection('refunds')
        .doc(refundId)
        .set({
      'refundId': refundId,
      'paymentId': paymentId,
      'ticketId': ticketId,
      'eventId': eventId,
      'userId': userId,
      'amount': amount,
      'reason': reason,
      'status': 'processed',
      'processedAt': FieldValue.serverTimestamp(),
    });
  }
  
  /// Get refund history for a user
  static Future<List<Map<String, dynamic>>> getRefundHistory(String userId) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('refunds')
          .where('userId', isEqualTo: userId)
          .orderBy('processedAt', descending: true)
          .get();
      
      return query.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting refund history: $e');
      return [];
    }
  }
  
  /// Get refund details
  static Future<Map<String, dynamic>?> getRefundDetails(String refundId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('refunds')
          .doc(refundId)
          .get();
      
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Error getting refund details: $e');
      return null;
    }
  }
  
  /// Check if ticket is eligible for refund
  static Future<bool> isTicketEligibleForRefund(String ticketId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('tickets')
          .doc(ticketId)
          .get();
      
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      final isRefunded = data['isRefunded'] ?? false;
      final isUsed = data['isUsed'] ?? false;
      final purchasedAt = (data['purchasedAt'] as Timestamp).toDate();
      final eventDate = (data['eventDate'] as Timestamp).toDate();
      
      // Check if ticket is not already refunded or used
      if (isRefunded || isUsed) return false;
      
      // Check if refund is within allowed time (e.g., 24 hours before event)
      final now = DateTime.now();
      final timeDifference = eventDate.difference(now);
      
      // Allow refund if more than 24 hours before event
      return timeDifference.inHours > 24;
    } catch (e) {
      print('Error checking refund eligibility: $e');
      return false;
    }
  }
  
  /// Calculate refund amount (with cancellation fees if applicable)
  static Future<double> calculateRefundAmount(String ticketId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('tickets')
          .doc(ticketId)
          .get();
      
      if (!doc.exists) return 0.0;
      
      final data = doc.data()!;
      final ticketPrice = (data['price'] as num).toDouble();
      final purchasedAt = (data['purchasedAt'] as Timestamp).toDate();
      final eventDate = (data['eventDate'] as Timestamp).toDate();
      
      final now = DateTime.now();
      final timeDifference = eventDate.difference(now);
      
      // Calculate cancellation fees based on time remaining
      double cancellationFee = 0.0;
      
      if (timeDifference.inHours < 24) {
        // Less than 24 hours: 50% cancellation fee
        cancellationFee = ticketPrice * 0.5;
      } else if (timeDifference.inHours < 72) {
        // Less than 72 hours: 25% cancellation fee
        cancellationFee = ticketPrice * 0.25;
      } else if (timeDifference.inHours < 168) {
        // Less than 1 week: 10% cancellation fee
        cancellationFee = ticketPrice * 0.1;
      }
      // More than 1 week: No cancellation fee
      
      return ticketPrice - cancellationFee;
    } catch (e) {
      print('Error calculating refund amount: $e');
      return 0.0;
    }
  }
}
