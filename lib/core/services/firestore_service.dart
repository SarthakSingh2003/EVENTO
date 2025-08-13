import 'dart:math' as math;
// import 'package:cloud_firestore/cloud_firestore.dart';  // Temporarily disabled
import '../models/event_model.dart';
import '../models/ticket_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;  // Temporarily disabled

  // Event Operations
  Future<String> createEvent(EventModel event) async {
    // Temporarily disabled Firebase operations
    // try {
    //   final docRef = await _firestore.collection('events').add(event.toMap());
    //   return docRef.id;
    // } catch (e) {
    //   throw Exception('Failed to create event: $e');
    // }
    
    // Mock implementation
    await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
    return 'mock-event-id-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> updates) async {
    // Temporarily disabled Firebase operations
    // try {
    //   await _firestore.collection('events').doc(eventId).update(updates);
    // } catch (e) {
    //   throw Exception('Failed to update event: $e');
    // }
    
    // Mock implementation
    await Future.delayed(Duration(milliseconds: 300));
  }

  Future<void> deleteEvent(String eventId) async {
    // Temporarily disabled Firebase operations
    // try {
    //   await _firestore.collection('events').doc(eventId).delete();
    // } catch (e) {
    //   throw Exception('Failed to delete event: $e');
    // }
    
    // Mock implementation
    await Future.delayed(Duration(milliseconds: 300));
  }

  Future<EventModel?> getEvent(String eventId) async {
    // Temporarily disabled Firebase operations
    // try {
    //   final doc = await _firestore.collection('events').doc(eventId).get();
    //   if (doc.exists) {
    //     return EventModel.fromMap(doc.data()!..['id'] = doc.id);
    //   }
    //   return null;
    // } catch (e) {
    //   throw Exception('Failed to get event: $e');
    // }
    
    // Mock implementation
    await Future.delayed(Duration(milliseconds: 300));
    return null;
  }

  Stream<List<EventModel>> getUpcomingEvents() {
    // Temporarily disabled Firebase operations
    // return _firestore
    //     .collection('events')
    //     .where('date', isGreaterThan: DateTime.now())
    //     .orderBy('date')
    //     .snapshots()
    //     .map((snapshot) => snapshot.docs
    //         .map((doc) => EventModel.fromMap(doc.data()..['id'] = doc.id))
    //         .toList());
    
    // Mock implementation
    return Stream.value([]);
  }

  Stream<List<EventModel>> getEventsByOrganiser(String organiserId) {
    // Temporarily disabled Firebase operations
    // return _firestore
    //     .collection('events')
    //     .where('organiserId', isEqualTo: organiserId)
    //     .orderBy('date', descending: true)
    //     .snapshots()
    //     .map((snapshot) => snapshot.docs
    //         .map((doc) => EventModel.fromMap(doc.data()..['id'] = doc.id))
    //         .toList());
    
    // Mock implementation
    return Stream.value([]);
  }

  Stream<List<EventModel>> getPastEvents() {
    // Temporarily disabled Firebase operations
    // return _firestore
    //     .collection('events')
    //     .where('date', isLessThan: DateTime.now())
    //     .orderBy('date', descending: true)
    //     .snapshots()
    //     .map((snapshot) => snapshot.docs
    //         .map((doc) => EventModel.fromMap(doc.data()..['id'] = doc.id))
    //         .toList());
    
    // Mock implementation
    return Stream.value([]);
  }

  // Ticket Operations
  Future<String> createTicket(TicketModel ticket) async {
    // Temporarily disabled Firebase operations
    // try {
    //   final docRef = await _firestore.collection('tickets').add(ticket.toMap());
    //   return docRef.id;
    // } catch (e) {
    //   throw Exception('Failed to create ticket: $e');
    // }
    
    // Mock implementation
    await Future.delayed(Duration(milliseconds: 500));
    return 'mock-ticket-id-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> updateTicket(String ticketId, Map<String, dynamic> updates) async {
    // Temporarily disabled Firebase operations
    // try {
    //   await _firestore.collection('tickets').doc(ticketId).update(updates);
    // } catch (e) {
    //   throw Exception('Failed to update ticket: $e');
    // }
    
    // Mock implementation
    await Future.delayed(Duration(milliseconds: 300));
  }

  Stream<List<TicketModel>> getUserTickets(String userId) {
    // Temporarily disabled Firebase operations
    // return _firestore
    //     .collection('tickets')
    //     .where('userId', isEqualTo: userId)
    //     .orderBy('purchasedAt', descending: true)
    //     .snapshots()
    //     .map((snapshot) => snapshot.docs
    //         .map((doc) => TicketModel.fromMap(doc.data()..['id'] = doc.id))
    //         .toList());
    
    // Mock implementation
    return Stream.value([]);
  }

  Stream<List<TicketModel>> getEventTickets(String eventId) {
    // Temporarily disabled Firebase operations
    // return _firestore
    //     .collection('tickets')
    //     .where('eventId', isEqualTo: eventId)
    //     .snapshots()
    //     .map((snapshot) => snapshot.docs
    //         .map((doc) => TicketModel.fromMap(doc.data()..['id'] = doc.id))
    //         .toList());
    
    // Mock implementation
    return Stream.value([]);
  }

  Future<TicketModel?> getTicketByQRCode(String qrCode) async {
    // Temporarily disabled Firebase operations
    // try {
    //   final query = await _firestore
    //       .collection('tickets')
    //       .where('qrCode', isEqualTo: qrCode)
    //       .limit(1)
    //       .get();
    //   
    //   if (query.docs.isNotEmpty) {
    //     final doc = query.docs.first;
    //     return TicketModel.fromMap(doc.data()..['id'] = doc.id);
    //   }
    //   return null;
    // } catch (e) {
    //   throw Exception('Failed to get ticket: $e');
    // }
    
    // Mock implementation
    await Future.delayed(Duration(milliseconds: 300));
    return null;
  }

  Future<void> markTicketAsUsed(String ticketId) async {
    // Temporarily disabled Firebase operations
    // try {
    //   await _firestore.collection('tickets').doc(ticketId).update({
    //     'isUsed': true,
    //     'usedAt': DateTime.now(),
    //   });
    // } catch (e) {
    //   throw Exception('Failed to mark ticket as used: $e');
    // }
    
    // Mock implementation
    await Future.delayed(Duration(milliseconds: 300));
  }

  // User Operations
  Future<UserModel?> getUser(String userId) async {
    // Temporarily disabled Firebase operations
    // try {
    //   final doc = await _firestore.collection('users').doc(userId).get();
    //   if (doc.exists) {
    //     return UserModel.fromMap(doc.data()!);
    //   }
    //   return null;
    // } catch (e) {
    //   throw Exception('Failed to get user: $e');
    // }
    
    // Mock implementation
    await Future.delayed(Duration(milliseconds: 300));
    return null;
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    // Temporarily disabled Firebase operations
    // try {
    //   await _firestore.collection('users').doc(userId).update(updates);
    // } catch (e) {
    //   throw Exception('Failed to update user: $e');
    // }
    
    // Mock implementation
    await Future.delayed(Duration(milliseconds: 300));
  }

  // Event Statistics
  Future<Map<String, dynamic>> getEventStatistics(String eventId) async {
    // Temporarily disabled Firebase operations
    // try {
    //   final ticketsQuery = await _firestore
    //       .collection('tickets')
    //       .where('eventId', isEqualTo: eventId)
    //       .get();

    //   final totalTickets = ticketsQuery.docs.length;
    //   final usedTickets = ticketsQuery.docs
    //       .where((doc) => doc.data()['isUsed'] == true)
    //       .length;

    //   return {
    //     'totalTickets': totalTickets,
    //     'usedTickets': usedTickets,
    //     'unusedTickets': totalTickets - usedTickets,
    //   };
    // } catch (e) {
    //   throw Exception('Failed to get event statistics: $e');
    // }
    
    // Mock implementation
    await Future.delayed(Duration(milliseconds: 300));
    return {
      'totalTickets': 0,
      'usedTickets': 0,
      'unusedTickets': 0,
    };
  }

  // Search Events
  Stream<List<EventModel>> searchEvents(String query) {
    // Temporarily disabled Firebase operations
    // return _firestore
    //     .collection('events')
    //     .where('title', isGreaterThanOrEqualTo: query)
    //     .where('title', isLessThan: query + '\uf8ff')
    //     .snapshots()
    //     .map((snapshot) => snapshot.docs
    //         .map((doc) => EventModel.fromMap(doc.data()..['id'] = doc.id))
    //         .toList());
    
    // Mock implementation
    return Stream.value([]);
  }

  // Location-based Events
  Stream<List<EventModel>> getEventsByLocation(
    double latitude,
    double longitude,
    double radiusInKm,
  ) {
    // Temporarily disabled Firebase operations
    // This is a simplified implementation
    // In a real app, you'd use geohashing or a geospatial database
    // return _firestore
    //     .collection('events')
    //     .where('date', isGreaterThan: DateTime.now())
    //     .snapshots()
    //     .map((snapshot) => snapshot.docs
    //         .map((doc) => EventModel.fromMap(doc.data()..['id'] = doc.id))
    //         .where((event) => _isWithinRadius(
    //             event.latitude,
    //             event.longitude,
    //             latitude,
    //             longitude,
    //             radiusInKm))
    //         .toList());
    
    // Mock implementation
    return Stream.value([]);
  }

  bool _isWithinRadius(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
    double radiusInKm,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        (math.sin(lat1) * math.sin(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2));
    final double c = 2 * math.atan(math.sqrt(a) / math.sqrt(1 - a));
    final double distance = earthRadius * c;
    return distance <= radiusInKm;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }
} 