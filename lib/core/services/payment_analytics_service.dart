import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentAnalyticsService {
  /// Track payment attempt
  static Future<void> trackPaymentAttempt({
    required String eventId,
    required String userId,
    required double amount,
    required String paymentMethod,
    required String status, // 'initiated', 'success', 'failed'
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('payment_analytics')
          .add({
        'eventId': eventId,
        'userId': userId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
      });
    } catch (e) {
      print('Error tracking payment attempt: $e');
    }
  }
  
  /// Get payment analytics for an event
  static Future<Map<String, dynamic>> getEventPaymentAnalytics(String eventId) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('payment_analytics')
          .where('eventId', isEqualTo: eventId)
          .get();
      
      final payments = query.docs.map((doc) => doc.data()).toList();
      
      // Calculate analytics
      final totalAttempts = payments.length;
      final successfulPayments = payments.where((p) => p['status'] == 'success').length;
      final failedPayments = payments.where((p) => p['status'] == 'failed').length;
      final totalRevenue = payments
          .where((p) => p['status'] == 'success')
          .fold(0.0, (sum, p) => sum + (p['amount'] as num).toDouble());
      
      // Payment method breakdown
      final paymentMethodBreakdown = <String, int>{};
      for (final payment in payments.where((p) => p['status'] == 'success')) {
        final method = payment['paymentMethod'] as String;
        paymentMethodBreakdown[method] = (paymentMethodBreakdown[method] ?? 0) + 1;
      }
      
      // Success rate by payment method
      final successRateByMethod = <String, double>{};
      final methodAttempts = <String, int>{};
      final methodSuccesses = <String, int>{};
      
      for (final payment in payments) {
        final method = payment['paymentMethod'] as String;
        methodAttempts[method] = (methodAttempts[method] ?? 0) + 1;
        if (payment['status'] == 'success') {
          methodSuccesses[method] = (methodSuccesses[method] ?? 0) + 1;
        }
      }
      
      for (final method in methodAttempts.keys) {
        final attempts = methodAttempts[method]!;
        final successes = methodSuccesses[method] ?? 0;
        successRateByMethod[method] = attempts > 0 ? (successes / attempts) * 100 : 0.0;
      }
      
      return {
        'totalAttempts': totalAttempts,
        'successfulPayments': successfulPayments,
        'failedPayments': failedPayments,
        'successRate': totalAttempts > 0 ? (successfulPayments / totalAttempts) * 100 : 0.0,
        'totalRevenue': totalRevenue,
        'averageTicketPrice': successfulPayments > 0 ? totalRevenue / successfulPayments : 0.0,
        'paymentMethodBreakdown': paymentMethodBreakdown,
        'successRateByMethod': successRateByMethod,
      };
    } catch (e) {
      print('Error getting event payment analytics: $e');
      return {};
    }
  }
  
  /// Get payment analytics for an organizer
  static Future<Map<String, dynamic>> getOrganizerPaymentAnalytics(String organizerId) async {
    try {
      // Get all events by this organizer
      final eventsQuery = await FirebaseFirestore.instance
          .collection('events')
          .where('organizerId', isEqualTo: organizerId)
          .get();
      
      final eventIds = eventsQuery.docs.map((doc) => doc.id).toList();
      
      if (eventIds.isEmpty) {
        return {
          'totalEvents': 0,
          'totalRevenue': 0.0,
          'totalTicketsSold': 0,
          'averageRevenuePerEvent': 0.0,
        };
      }
      
      // Get payment analytics for all events
      final analyticsQuery = await FirebaseFirestore.instance
          .collection('payment_analytics')
          .where('eventId', whereIn: eventIds)
          .where('status', isEqualTo: 'success')
          .get();
      
      final payments = analyticsQuery.docs.map((doc) => doc.data()).toList();
      
      // Calculate analytics
      final totalRevenue = payments.fold(0.0, (sum, p) => sum + (p['amount'] as num).toDouble());
      final totalTicketsSold = payments.length;
      final averageRevenuePerEvent = eventIds.length > 0 ? totalRevenue / eventIds.length : 0.0;
      
      // Monthly revenue breakdown
      final monthlyRevenue = <String, double>{};
      for (final payment in payments) {
        final timestamp = payment['timestamp'] as Timestamp;
        final month = '${timestamp.toDate().year}-${timestamp.toDate().month.toString().padLeft(2, '0')}';
        monthlyRevenue[month] = (monthlyRevenue[month] ?? 0.0) + (payment['amount'] as num).toDouble();
      }
      
      return {
        'totalEvents': eventIds.length,
        'totalRevenue': totalRevenue,
        'totalTicketsSold': totalTicketsSold,
        'averageRevenuePerEvent': averageRevenuePerEvent,
        'monthlyRevenue': monthlyRevenue,
      };
    } catch (e) {
      print('Error getting organizer payment analytics: $e');
      return {};
    }
  }
  
  /// Get payment trends over time
  static Future<List<Map<String, dynamic>>> getPaymentTrends({
    required String eventId,
    required int days,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      final query = await FirebaseFirestore.instance
          .collection('payment_analytics')
          .where('eventId', isEqualTo: eventId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp')
          .get();
      
      final payments = query.docs.map((doc) => doc.data()).toList();
      
      // Group by date
      final dailyData = <String, Map<String, dynamic>>{};
      
      for (final payment in payments) {
        final timestamp = payment['timestamp'] as Timestamp;
        final date = '${timestamp.toDate().year}-${timestamp.toDate().month.toString().padLeft(2, '0')}-${timestamp.toDate().day.toString().padLeft(2, '0')}';
        
        if (!dailyData.containsKey(date)) {
          dailyData[date] = {
            'date': date,
            'attempts': 0,
            'successes': 0,
            'revenue': 0.0,
          };
        }
        
        dailyData[date]!['attempts']++;
        if (payment['status'] == 'success') {
          dailyData[date]!['successes']++;
          dailyData[date]!['revenue'] += (payment['amount'] as num).toDouble();
        }
      }
      
      return dailyData.values.toList();
    } catch (e) {
      print('Error getting payment trends: $e');
      return [];
    }
  }
  
  /// Track refund
  static Future<void> trackRefund({
    required String eventId,
    required String userId,
    required double amount,
    required String reason,
    required String refundId,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('refund_analytics')
          .add({
        'eventId': eventId,
        'userId': userId,
        'amount': amount,
        'reason': reason,
        'refundId': refundId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error tracking refund: $e');
    }
  }
  
  /// Get refund analytics
  static Future<Map<String, dynamic>> getRefundAnalytics(String eventId) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('refund_analytics')
          .where('eventId', isEqualTo: eventId)
          .get();
      
      final refunds = query.docs.map((doc) => doc.data()).toList();
      
      final totalRefunds = refunds.length;
      final totalRefundAmount = refunds.fold(0.0, (sum, r) => sum + (r['amount'] as num).toDouble());
      
      // Refund reasons breakdown
      final refundReasons = <String, int>{};
      for (final refund in refunds) {
        final reason = refund['reason'] as String;
        refundReasons[reason] = (refundReasons[reason] ?? 0) + 1;
      }
      
      return {
        'totalRefunds': totalRefunds,
        'totalRefundAmount': totalRefundAmount,
        'refundReasons': refundReasons,
      };
    } catch (e) {
      print('Error getting refund analytics: $e');
      return {};
    }
  }
}
