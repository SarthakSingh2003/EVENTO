import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentWebhookService {
  static const String _webhookSecret = 'YOUR_WEBHOOK_SECRET'; // Replace with your webhook secret
  
  /// Verify webhook signature
  static bool verifyWebhookSignature({
    required String payload,
    required String signature,
  }) {
    try {
      // In production, implement proper HMAC-SHA256 verification
      // This is a simplified version for demonstration
      final expectedSignature = _generateWebhookSignature(payload);
      return signature == expectedSignature;
    } catch (e) {
      return false;
    }
  }
  
  /// Generate webhook signature
  static String _generateWebhookSignature(String payload) {
    // This is a simplified implementation
    // In production, use proper HMAC-SHA256 with your webhook secret
    return base64Encode(utf8.encode(payload));
  }
  
  /// Process payment webhook
  static Future<void> processWebhook({
    required String event,
    required Map<String, dynamic> payload,
    required String signature,
  }) async {
    try {
      // Verify webhook signature
      if (!verifyWebhookSignature(
        payload: jsonEncode(payload),
        signature: signature,
      )) {
        throw Exception('Invalid webhook signature');
      }
      
      switch (event) {
        case 'payment.captured':
          await _handlePaymentCaptured(payload);
          break;
        case 'payment.failed':
          await _handlePaymentFailed(payload);
          break;
        case 'payment.authorized':
          await _handlePaymentAuthorized(payload);
          break;
        case 'refund.created':
          await _handleRefundCreated(payload);
          break;
        default:
          print('Unhandled webhook event: $event');
      }
    } catch (e) {
      print('Error processing webhook: $e');
      rethrow;
    }
  }
  
  /// Handle successful payment
  static Future<void> _handlePaymentCaptured(Map<String, dynamic> payload) async {
    final paymentId = payload['id'];
    final orderId = payload['order_id'];
    final amount = payload['amount'] / 100; // Convert from paise
    final currency = payload['currency'];
    final method = payload['method'];
    final notes = payload['notes'] as Map<String, dynamic>?;
    
    if (notes != null) {
      final eventId = notes['eventId'];
      final userId = notes['userId'];
      
      if (eventId != null && userId != null) {
        // Update payment status in Firestore
        await FirebaseFirestore.instance
            .collection('payments')
            .doc(paymentId)
            .set({
          'paymentId': paymentId,
          'orderId': orderId,
          'eventId': eventId,
          'userId': userId,
          'amount': amount,
          'currency': currency,
          'method': method,
          'status': 'captured',
          'capturedAt': FieldValue.serverTimestamp(),
          'notes': notes,
        });
        
        // Update ticket status if needed
        await _updateTicketStatus(eventId, userId, paymentId, 'confirmed');
      }
    }
  }
  
  /// Handle failed payment
  static Future<void> _handlePaymentFailed(Map<String, dynamic> payload) async {
    final paymentId = payload['id'];
    final orderId = payload['order_id'];
    final error = payload['error'];
    final notes = payload['notes'] as Map<String, dynamic>?;
    
    if (notes != null) {
      final eventId = notes['eventId'];
      final userId = notes['userId'];
      
      if (eventId != null && userId != null) {
        // Update payment status in Firestore
        await FirebaseFirestore.instance
            .collection('payments')
            .doc(paymentId)
            .set({
          'paymentId': paymentId,
          'orderId': orderId,
          'eventId': eventId,
          'userId': userId,
          'status': 'failed',
          'error': error,
          'failedAt': FieldValue.serverTimestamp(),
          'notes': notes,
        });
        
        // Release reserved tickets
        await _releaseReservedTickets(eventId, userId);
      }
    }
  }
  
  /// Handle authorized payment (for cards)
  static Future<void> _handlePaymentAuthorized(Map<String, dynamic> payload) async {
    final paymentId = payload['id'];
    final orderId = payload['order_id'];
    final notes = payload['notes'] as Map<String, dynamic>?;
    
    if (notes != null) {
      final eventId = notes['eventId'];
      final userId = notes['userId'];
      
      if (eventId != null && userId != null) {
        // Update payment status in Firestore
        await FirebaseFirestore.instance
            .collection('payments')
            .doc(paymentId)
            .set({
          'paymentId': paymentId,
          'orderId': orderId,
          'eventId': eventId,
          'userId': userId,
          'status': 'authorized',
          'authorizedAt': FieldValue.serverTimestamp(),
          'notes': notes,
        });
      }
    }
  }
  
  /// Handle refund creation
  static Future<void> _handleRefundCreated(Map<String, dynamic> payload) async {
    final refundId = payload['id'];
    final paymentId = payload['payment_id'];
    final amount = payload['amount'] / 100; // Convert from paise
    final status = payload['status'];
    
    // Update refund status in Firestore
    await FirebaseFirestore.instance
        .collection('refunds')
        .doc(refundId)
        .set({
      'refundId': refundId,
      'paymentId': paymentId,
      'amount': amount,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  
  /// Update ticket status
  static Future<void> _updateTicketStatus(
    String eventId,
    String userId,
    String paymentId,
    String status,
  ) async {
    try {
      // Find the ticket for this event and user
      final ticketQuery = await FirebaseFirestore.instance
          .collection('tickets')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (ticketQuery.docs.isNotEmpty) {
        final ticketDoc = ticketQuery.docs.first;
        await ticketDoc.reference.update({
          'paymentStatus': status,
          'paymentId': paymentId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating ticket status: $e');
    }
  }
  
  /// Release reserved tickets
  static Future<void> _releaseReservedTickets(String eventId, String userId) async {
    try {
      // Find and delete the reserved ticket
      final ticketQuery = await FirebaseFirestore.instance
          .collection('tickets')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .where('paymentStatus', isEqualTo: 'pending')
          .get();
      
      for (final doc in ticketQuery.docs) {
        await doc.reference.delete();
      }
      
      // Update available tickets count
      await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .update({
        'availableTickets': FieldValue.increment(1),
        'soldTickets': FieldValue.increment(-1),
      });
    } catch (e) {
      print('Error releasing reserved tickets: $e');
    }
  }
  
  /// Get payment history for a user
  static Future<List<Map<String, dynamic>>> getPaymentHistory(String userId) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .orderBy('capturedAt', descending: true)
          .get();
      
      return query.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting payment history: $e');
      return [];
    }
  }
  
  /// Get payment details
  static Future<Map<String, dynamic>?> getPaymentDetails(String paymentId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('payments')
          .doc(paymentId)
          .get();
      
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Error getting payment details: $e');
      return null;
    }
  }
}
