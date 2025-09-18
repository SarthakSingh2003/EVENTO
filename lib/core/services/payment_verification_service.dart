import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/payment_verification_model.dart';

class PaymentVerificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _collection = 'payment_verifications';

  /// Submit a payment verification request
  static Future<String> submitPaymentVerification({
    required String eventId,
    required String eventTitle,
    required String userId,
    required String userName,
    required String userEmail,
    required double amount,
    required File screenshotFile,
    required String transactionId,
    Map<String, dynamic>? notes,
  }) async {
    try {
      // Upload screenshot to Firebase Storage
      final screenshotUrl = await _uploadScreenshot(screenshotFile, eventId, userId);
      
      // Create payment verification document
      final verification = PaymentVerificationModel(
        id: '', // Will be set by Firestore
        eventId: eventId,
        eventTitle: eventTitle,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        amount: amount,
        screenshotUrl: screenshotUrl,
        transactionId: transactionId,
        status: 'pending',
        submittedAt: DateTime.now(),
        notes: notes,
      );

      final docRef = await _firestore.collection(_collection).add(verification.toMap());
      // Do not perform a follow-up update here; rules restrict updates to organisers.
      // Return the generated document ID to the caller for reference.
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to submit payment verification: $e');
    }
  }

  /// Upload screenshot to Firebase Storage
  static Future<String> _uploadScreenshot(File file, String eventId, String userId) async {
    try {
      final fileName = 'payment_${eventId}_${userId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final ref = _storage.ref().child('payment_screenshots/$fileName');
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload screenshot: $e');
    }
  }

  /// Get payment verifications for an event (for organizers)
  static Future<List<PaymentVerificationModel>> getEventPaymentVerifications(String eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('eventId', isEqualTo: eventId)
          .get();

      // Sort by submittedAt on client side to avoid index requirement
      final verifications = querySnapshot.docs
          .map((doc) => PaymentVerificationModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();

      // Sort by submittedAt descending (most recent first)
      verifications.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      
      return verifications;
    } catch (e) {
      throw Exception('Failed to get payment verifications: $e');
    }
  }

  /// Get user's payment verifications
  static Future<List<PaymentVerificationModel>> getUserPaymentVerifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      // Sort by submittedAt on client side to avoid index requirement
      final verifications = querySnapshot.docs
          .map((doc) => PaymentVerificationModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();

      // Sort by submittedAt descending (most recent first)
      verifications.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      
      return verifications;
    } catch (e) {
      throw Exception('Failed to get user payment verifications: $e');
    }
  }

  /// Get the user's verification for a specific event (latest)
  static Future<PaymentVerificationModel?> getUserVerificationForEvent({
    required String eventId,
    required String userId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      // Pick latest by submittedAt on client to avoid composite index
      QueryDocumentSnapshot<Map<String, dynamic>>? latest;
      DateTime latestTime = DateTime.fromMillisecondsSinceEpoch(0);
      
      for (final doc in querySnapshot.docs) {
        final submittedAt = (doc.data()['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        if (submittedAt.isAfter(latestTime)) {
          latestTime = submittedAt;
          latest = doc;
        }
      }
      
      if (latest == null) return null;

      return PaymentVerificationModel.fromMap({
        ...latest.data(),
        'id': latest.id,
      });
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        return null;
      }
      throw Exception('Failed to get user verification for event: $e');
    }
  }

  /// Verify a payment (for organizers)
  static Future<void> verifyPayment({
    required String verificationId,
    required String verifiedBy,
    required bool isApproved,
    String? rejectionReason,
  }) async {
    try {
      final updateData = {
        'status': isApproved ? 'verified' : 'rejected',
        'verifiedBy': verifiedBy,
        'verifiedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (!isApproved && rejectionReason != null) {
        updateData['rejectionReason'] = rejectionReason;
      }

      await _firestore
          .collection(_collection)
          .doc(verificationId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to verify payment: $e');
    }
  }

  /// Get pending payment verifications count for an event
  static Future<int> getPendingVerificationsCount(String eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'pending')
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get pending verifications count: $e');
    }
  }

  /// Check if user has already submitted a payment verification for an event
  static Future<bool> hasUserSubmittedVerification(String eventId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .get();

      // Client-side filter to avoid composite index requirement
      return querySnapshot.docs.any((doc) {
        final status = (doc.data()['status'] ?? 'pending') as String;
        return status == 'pending' || status == 'verified';
      });
    } catch (e) {
      // If rules temporarily block list queries, allow submission to proceed.
      if (e is FirebaseException && e.code == 'permission-denied') {
        return false;
      }
      throw Exception('Failed to check existing verification: $e');
    }
  }

  /// Get payment verification by ID
  static Future<PaymentVerificationModel?> getPaymentVerification(String verificationId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(verificationId).get();
      
      if (doc.exists) {
        return PaymentVerificationModel.fromMap({
          ...doc.data()!,
          'id': doc.id,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get payment verification: $e');
    }
  }

  /// Delete payment verification (for cleanup)
  static Future<void> deletePaymentVerification(String verificationId) async {
    try {
      await _firestore.collection(_collection).doc(verificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete payment verification: $e');
    }
  }
}
