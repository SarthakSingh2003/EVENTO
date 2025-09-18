import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../models/ticket_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Mock events data for testing - make it a mutable list
  List<EventModel> _mockEventsList = [];
  
  // Getter for mock events
  List<EventModel> get _mockEvents {
    if (_mockEventsList.isEmpty) {
      _mockEventsList = _generateMockEvents();
    }
    return _mockEventsList;
  }

  // Event Operations
  Future<String> createEvent(EventModel event) async {
    try {
      // Add the event to Firestore
      final docRef = await _firestore.collection('events').add(event.toMap());
      
      // Also add to mock events for immediate display (temporary)
      final newEvent = event.copyWith(id: docRef.id);
      _mockEventsList.add(newEvent);
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> updates) async {
    try {
      // Update in Firestore
      await _firestore.collection('events').doc(eventId).update(updates);
      
      // Also update in mock events for immediate display
      final mockEventIndex = _mockEventsList.indexWhere((event) => event.id == eventId);
      if (mockEventIndex != -1) {
        final updatedEvent = _mockEventsList[mockEventIndex].copyWith(
          title: updates['title'] ?? _mockEventsList[mockEventIndex].title,
          description: updates['description'] ?? _mockEventsList[mockEventIndex].description,
          location: updates['location'] ?? _mockEventsList[mockEventIndex].location,
          latitude: updates['latitude'] ?? _mockEventsList[mockEventIndex].latitude,
          longitude: updates['longitude'] ?? _mockEventsList[mockEventIndex].longitude,
          date: updates['date'] ?? _mockEventsList[mockEventIndex].date,
          time: updates['time'] ?? _mockEventsList[mockEventIndex].time,
          totalTickets: updates['totalTickets'] ?? _mockEventsList[mockEventIndex].totalTickets,
          soldTickets: updates['soldTickets'] ?? _mockEventsList[mockEventIndex].soldTickets,
          price: updates['price'] ?? _mockEventsList[mockEventIndex].price,
          isFree: updates['isFree'] ?? _mockEventsList[mockEventIndex].isFree,
          bannerImage: updates['bannerImage'] ?? _mockEventsList[mockEventIndex].bannerImage,
          category: updates['category'] ?? _mockEventsList[mockEventIndex].category,
          tags: updates['tags'] != null ? List<String>.from(updates['tags']) : _mockEventsList[mockEventIndex].tags,
          venueDetails: updates['venueDetails'] ?? _mockEventsList[mockEventIndex].venueDetails,
          eventType: updates['eventType'] ?? _mockEventsList[mockEventIndex].eventType,
          maxAttendees: updates['maxAttendees'] ?? _mockEventsList[mockEventIndex].maxAttendees,
          contactInfo: updates['contactInfo'] ?? _mockEventsList[mockEventIndex].contactInfo,
          website: updates['website'] ?? _mockEventsList[mockEventIndex].website,
          updatedAt: DateTime.now(),
        );
        _mockEventsList[mockEventIndex] = updatedEvent;
      }
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  /// Synchronizes the soldTickets count with the actual number of tickets in the database
  Future<void> syncSoldTicketsCount(String eventId) async {
    try {
      debugPrint('=== SYNC TICKETS DEBUG ===');
      debugPrint('Syncing tickets for event: $eventId');
      
      // Get actual ticket count from Firestore
      final ticketsQuery = await _firestore
          .collection('tickets')
          .where('eventId', isEqualTo: eventId)
          .get();
      
      final actualSoldTickets = ticketsQuery.docs.length;
      debugPrint('Found $actualSoldTickets tickets in database');
      
      // Get current event data
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (eventDoc.exists) {
        final currentData = eventDoc.data()!;
        final currentSoldTickets = currentData['soldTickets'] ?? 0;
        debugPrint('Current soldTickets in event: $currentSoldTickets');
        debugPrint('Actual tickets in database: $actualSoldTickets');
        
        if (currentSoldTickets != actualSoldTickets) {
          debugPrint('Updating soldTickets from $currentSoldTickets to $actualSoldTickets');
          
          // Update the event's soldTickets field
          await _firestore.collection('events').doc(eventId).update({
            'soldTickets': actualSoldTickets,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          // Also update in mock events for immediate display
          final mockEventIndex = _mockEventsList.indexWhere((event) => event.id == eventId);
          if (mockEventIndex != -1) {
            final updatedEvent = _mockEventsList[mockEventIndex].copyWith(
              soldTickets: actualSoldTickets,
              updatedAt: DateTime.now(),
            );
            _mockEventsList[mockEventIndex] = updatedEvent;
            debugPrint('Updated mock event with new soldTickets count');
          }
        } else {
          debugPrint('Ticket counts already match, no update needed');
        }
      }
      
      debugPrint('Sync completed for event $eventId');
      debugPrint('============================');
    } catch (e) {
      debugPrint('Error syncing sold tickets for event $eventId: $e');
      // Don't throw error, just log it
    }
  }

  /// Fast increment for soldTickets to reflect purchases immediately
  Future<void> incrementSoldTickets(String eventId, int delta) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'soldTickets': FieldValue.increment(delta),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('incrementSoldTickets error for $eventId: $e');
    }
  }

  /// Atomically reserves tickets by incrementing soldTickets if capacity allows.
  /// Returns true if reservation succeeded; false if not enough tickets remain.
  Future<bool> reserveTickets(String eventId, int quantity) async {
    return await _firestore.runTransaction<bool>((txn) async {
      final ref = _firestore.collection('events').doc(eventId);
      final snap = await txn.get(ref);
      if (!snap.exists) {
        debugPrint('reserveTickets: event not found');
        return false;
      }
      final data = snap.data() as Map<String, dynamic>;
      final int total = ((data['totalTickets'] ?? 0) as num).toInt();
      final int maxAttendees = ((data['maxAttendees'] ?? 0) as num).toInt();
      final int capacity = total > 0 ? total : maxAttendees;
      final int sold = ((data['soldTickets'] ?? 0) as num).toInt();
      final int remaining = capacity - sold;
      debugPrint('reserveTickets: capacity=$capacity sold=$sold remaining=$remaining qty=$quantity');
      if (capacity <= 0) {
        // No capacity configured → treat as sold out
        return false;
      }
      if (remaining < quantity) {
        return false;
      }
      txn.update(ref, {
        'soldTickets': sold + quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  // Live ticket count for an event
  Stream<int> streamTicketCount(String eventId) {
    return _firestore
        .collection('tickets')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snap) => snap.size);
  }

  Future<int> getTicketCountOnce(String eventId) async {
    final q = await _firestore
        .collection('tickets')
        .where('eventId', isEqualTo: eventId)
        .get();
    return q.size;
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      // Delete from Firestore
      await _firestore.collection('events').doc(eventId).delete();
      
      // Also remove from mock events
      _mockEventsList.removeWhere((event) => event.id == eventId);
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  Future<EventModel?> getEvent(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();
      if (doc.exists) {
        return EventModel.fromMap(doc.data()!..['id'] = doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get event: $e');
    }
  }

  // Realtime event stream
  Stream<EventModel?> streamEvent(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .snapshots()
        .map((snap) => snap.exists ? EventModel.fromMap(snap.data()!..['id'] = snap.id) : null);
  }

  /// If an event has totalTickets = 0 but maxAttendees > 0, promote
  /// maxAttendees to totalTickets to reflect organiser-provided capacity.
  Future<void> autoFixEventCapacity(String eventId) async {
    try {
      final ref = _firestore.collection('events').doc(eventId);
      final snap = await ref.get();
      if (!snap.exists) return;
      final data = snap.data()!;
      final int total = (data['totalTickets'] ?? 0) as int;
      final int maxAttendees = (data['maxAttendees'] ?? 0) as int;
      if (total == 0 && maxAttendees > 0) {
        await ref.update({
          'totalTickets': maxAttendees,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('autoFixEventCapacity error for $eventId: $e');
    }
  }

  Stream<List<EventModel>> getUpcomingEvents() {
    return _firestore
        .collection('events')
        .where('date', isGreaterThan: DateTime.now())
        .where('isActive', isEqualTo: true)
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
          final firestoreEvents = snapshot.docs
              .map((doc) => EventModel.fromMap(doc.data()..['id'] = doc.id))
              .toList();
          
          // Combine with mock events for immediate display
          final mockUpcomingEvents = _mockEventsList.where((event) => 
            event.date.isAfter(DateTime.now()) && event.isActive
          ).toList();
          
          // Merge and remove duplicates based on ID
          final allEvents = [...firestoreEvents, ...mockUpcomingEvents];
          final uniqueEvents = <String, EventModel>{};
          
          for (final event in allEvents) {
            if (event.id != null) {
              uniqueEvents[event.id!] = event;
            }
          }
          
          return uniqueEvents.values.toList()..sort((a, b) => a.date.compareTo(b.date));
        });
  }

  /// Loads upcoming events with synced ticket counts
  Future<List<EventModel>> getUpcomingEventsWithSync() async {
    try {
      debugPrint('=== LOADING UPCOMING EVENTS WITH SYNC ===');
      
      // Get events from Firestore
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await _firestore
            .collection('events')
            .where('date', isGreaterThan: DateTime.now())
            .where('isActive', isEqualTo: true)
            .orderBy('date')
            .get();
      } catch (e) {
        // Fallback for missing composite index: query only by date and filter client-side
        debugPrint('Primary upcoming events query failed, retrying without isActive filter: $e');
        snapshot = await _firestore
            .collection('events')
            .where('date', isGreaterThan: DateTime.now())
            .orderBy('date')
            .get();
      }
      
      final events = snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data()..['id'] = doc.id))
          .where((e) => e.isActive)
          .toList();
      
      debugPrint('Found ${events.length} upcoming events');
      
      // Sync ticket counts for each event
      for (final event in events) {
        if (event.id != null) {
          debugPrint('Syncing tickets for event: ${event.title} (${event.id})');
          await syncSoldTicketsCount(event.id!);
        }
      }
      
      // Reload events with updated ticket counts
      QuerySnapshot<Map<String, dynamic>> updatedSnapshot;
      try {
        updatedSnapshot = await _firestore
            .collection('events')
            .where('date', isGreaterThan: DateTime.now())
            .where('isActive', isEqualTo: true)
            .orderBy('date')
            .get();
      } catch (e) {
        debugPrint('Updated upcoming events query failed, retrying without isActive filter: $e');
        updatedSnapshot = await _firestore
            .collection('events')
            .where('date', isGreaterThan: DateTime.now())
            .orderBy('date')
            .get();
      }
      
      final updatedEvents = updatedSnapshot.docs
          .map((doc) => EventModel.fromMap(doc.data()..['id'] = doc.id))
          .where((e) => e.isActive)
          .toList();
      
      debugPrint('Returning ${updatedEvents.length} events with synced ticket counts');
      for (final event in updatedEvents) {
        debugPrint('Event: ${event.title} - Sold: ${event.soldTickets}/${event.totalTickets} - Available: ${event.availableTickets}');
      }
      
      debugPrint('=== UPCOMING EVENTS SYNC COMPLETED ===');
      return updatedEvents;
    } catch (e) {
      debugPrint('Error loading upcoming events with sync: $e');
      // Fallback to mock events
      return _mockEventsList.where((event) => 
        event.date.isAfter(DateTime.now()) && event.isActive
      ).toList();
    }
  }

  Stream<List<EventModel>> getPastEvents() {
    try {
      return _firestore
          .collection('events')
          .where('date', isLessThan: DateTime.now())
          .where('isActive', isEqualTo: true)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
            final firestoreEvents = snapshot.docs
                .map((doc) => EventModel.fromMap(doc.data()..['id'] = doc.id))
                .toList();
          
            // Combine with mock events for immediate display
            final mockPastEvents = _mockEventsList.where((event) => 
              event.date.isBefore(DateTime.now()) && event.isActive
            ).toList();
          
            // Merge and remove duplicates based on ID
            final allEvents = [...firestoreEvents, ...mockPastEvents];
            final uniqueEvents = <String, EventModel>{};
          
            for (final event in allEvents) {
              if (event.id != null) {
                uniqueEvents[event.id!] = event;
              }
            }
          
            return uniqueEvents.values.toList()..sort((a, b) => b.date.compareTo(a.date));
          });
    } catch (e) {
      // Fallback: query without isActive filter and filter client-side
      return _firestore
          .collection('events')
          .where('date', isLessThan: DateTime.now())
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
            final firestoreEvents = snapshot.docs
                .map((doc) => EventModel.fromMap(doc.data()..['id'] = doc.id))
                .where((e) => e.isActive)
                .toList();

            final mockPastEvents = _mockEventsList.where((event) => 
              event.date.isBefore(DateTime.now()) && event.isActive
            ).toList();

            final allEvents = [...firestoreEvents, ...mockPastEvents];
            final uniqueEvents = <String, EventModel>{};
            for (final event in allEvents) {
              if (event.id != null) uniqueEvents[event.id!] = event;
            }
            return uniqueEvents.values.toList()..sort((a, b) => b.date.compareTo(a.date));
          });
    }
  }

  Stream<List<EventModel>> getEventsByOrganiser(String organiserId) {
    return _firestore
        .collection('events')
        .where('organiserId', isEqualTo: organiserId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromMap(doc.data()..['id'] = doc.id))
            .where((e) => e.isActive)
            .toList());
  }

  // Search events by tags and categories
  Stream<List<EventModel>> searchEventsByTags(List<String> tags) {
    // Temporarily disabled Firebase operations
    // return _firestore
    //     .collection('events')
    //     .where('tags', arrayContainsAny: tags)
    //     .where('isActive', isEqualTo: true)
    //     .snapshots()
    //     .map((snapshot) => snapshot.docs
    //         .map((doc) => EventModel.fromMap(doc.data()..['id'] = doc.id))
    //         .toList());
    
    // Mock implementation - search through all events
    return Stream.value(_mockEventsList.where((event) => 
      event.tags.any((tag) => tags.contains(tag)) && event.isActive
    ).toList());
  }

  // Get featured events for carousel
  Stream<List<EventModel>> getFeaturedEvents() {
    // Temporarily disabled Firebase operations
    // return _firestore
    //     .collection('events')
    //     .where('isFeatured', isEqualTo: true)
    //     .where('isActive', isEqualTo: true)
    //     .where('date', isGreaterThan: DateTime.now())
    //     .orderBy('date')
    //     .limit(5)
    //     .snapshots()
    //     .map((snapshot) => snapshot.docs
    //         .map((doc) => EventModel.fromMap(doc.data()..['id'] = doc.id))
    //         .toList());
    
    // Mock implementation - return upcoming events marked as featured
    return Stream.value(_mockEventsList.where((event) => 
      event.isFeatured && event.isActive && event.date.isAfter(DateTime.now())
    ).take(5).toList());
  }

  // Ticket Operations
  Future<String> createTicket(TicketModel ticket) async {
    try {
      final docRef = await _firestore.collection('tickets').add(ticket.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create ticket: $e');
    }
  }

  Future<String> createTicketFromMap(Map<String, dynamic> ticketData) async {
    try {
      final docRef = await _firestore.collection('tickets').add(ticketData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create ticket: $e');
    }
  }

  Future<void> updateTicket(String ticketId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('tickets').doc(ticketId).update(updates);
    } catch (e) {
      throw Exception('Failed to update ticket: $e');
    }
  }

  Stream<List<TicketModel>> getUserTickets(String userId) {
    // Avoid orderBy to prevent index requirement; sort client-side
    return _firestore
        .collection('tickets')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => TicketModel.fromMap(doc.data()..['id'] = doc.id))
              .toList();
          list.sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
          return list;
        });
  }

  Stream<List<TicketModel>> getEventTickets(String eventId) {
    try {
      return _firestore
          .collection('tickets')
          .where('eventId', isEqualTo: eventId)
          .orderBy('purchasedAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => TicketModel.fromMap(doc.data()..['id'] = doc.id))
              .toList());
    } catch (e) {
      debugPrint('Error getting event tickets: $e');
      // If there's an index error, try without ordering
      if (e.toString().contains('failed-precondition') || e.toString().contains('index')) {
        try {
          return _firestore
              .collection('tickets')
              .where('eventId', isEqualTo: eventId)
              .snapshots()
              .map((snapshot) => snapshot.docs
                  .map((doc) => TicketModel.fromMap(doc.data()..['id'] = doc.id))
                  .toList()
                ..sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt)));
        } catch (e2) {
          debugPrint('Error getting event tickets without ordering: $e2');
          return Stream.value([]);
        }
      }
      // Return empty stream on error
      return Stream.value([]);
    }
  }

  // Add a Future version for easier use in some screens
  Future<List<TicketModel>> getEventTicketsFuture(String eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection('tickets')
          .where('eventId', isEqualTo: eventId)
          .orderBy('purchasedAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => TicketModel.fromMap(doc.data()..['id'] = doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting event tickets: $e');
      // If there's an index error, try without ordering
      if (e.toString().contains('failed-precondition') || e.toString().contains('index')) {
        try {
          final querySnapshot = await _firestore
              .collection('tickets')
              .where('eventId', isEqualTo: eventId)
              .get();
          
          final tickets = querySnapshot.docs
              .map((doc) => TicketModel.fromMap(doc.data()..['id'] = doc.id))
              .toList();
          
          // Sort manually
          tickets.sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
          return tickets;
        } catch (e2) {
          debugPrint('Error getting event tickets without ordering: $e2');
          return [];
        }
      }
      // Return empty list on error
      return [];
    }
  }

  Future<TicketModel?> getTicketByQRCode(String qrCode) async {
    try {
      final query = await _firestore
          .collection('tickets')
          .where('qrCode', isEqualTo: qrCode)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return TicketModel.fromMap(doc.data()..['id'] = doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get ticket: $e');
    }
  }

  /// Check if a user already has a ticket for a specific event
  Future<bool> hasUserTicketForEvent(String userId, String eventId) async {
    try {
      final query = await _firestore
          .collection('tickets')
          .where('userId', isEqualTo: userId)
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking user ticket for event: $e');
      // Return false on error to allow purchase attempt
      return false;
    }
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

  // Bulk ticket operations
  Future<void> bulkUpdateTickets(List<String> ticketIds, Map<String, dynamic> updates) async {
    try {
      // Update multiple tickets in Firestore
      final batch = _firestore.batch();
      
      for (final ticketId in ticketIds) {
        final ticketRef = _firestore.collection('tickets').doc(ticketId);
        batch.update(ticketRef, updates);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to bulk update tickets: $e');
    }
  }

  // Get ticket statistics for an event
  Future<Map<String, dynamic>> getTicketStatistics(String eventId) async {
    try {
      // Get tickets directly from Firestore for real-time data
      final ticketsQuery = await _firestore
          .collection('tickets')
          .where('eventId', isEqualTo: eventId)
          .get();
      
      final tickets = ticketsQuery.docs
          .map((doc) => TicketModel.fromMap(doc.data()..['id'] = doc.id))
          .toList();
      
      final totalTickets = tickets.length;
      final usedTickets = tickets.where((ticket) => ticket.isUsed).length;
      final pendingTickets = totalTickets - usedTickets;
      
      // Group tickets by purchase date for trend analysis
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));
      
      final recentTickets = tickets.where((ticket) => 
        ticket.purchasedAt.isAfter(weekAgo)
      ).length;
      
      final monthlyTickets = tickets.where((ticket) => 
        ticket.purchasedAt.isAfter(monthAgo)
      ).length;
      
      // Calculate daily ticket sales for the last 7 days
      final dailySales = <String, int>{};
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final dayTickets = tickets.where((ticket) => 
          ticket.purchasedAt.year == date.year &&
          ticket.purchasedAt.month == date.month &&
          ticket.purchasedAt.day == date.day
        ).length;
        dailySales[dayKey] = dayTickets;
      }
      
      return {
        'totalTickets': totalTickets,
        'usedTickets': usedTickets,
        'pendingTickets': pendingTickets,
        'recentSales': recentTickets,
        'monthlySales': monthlyTickets,
        'usageRate': totalTickets > 0 ? (usedTickets / totalTickets) * 100 : 0.0,
        'dailySales': dailySales,
        'lastUpdated': DateTime.now(),
      };
    } catch (e) {
      debugPrint('Error getting ticket statistics: $e');
      return {
        'totalTickets': 0,
        'usedTickets': 0,
        'pendingTickets': 0,
        'recentSales': 0,
        'monthlySales': 0,
        'usageRate': 0.0,
        'dailySales': <String, int>{},
        'lastUpdated': DateTime.now(),
      };
    }
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

  // Get events created by a specific user
  Future<List<EventModel>> getUserEvents(String userId) async {
    try {
      // Get events from Firestore with fallback if composite index is missing
      QuerySnapshot<Map<String, dynamic>> querySnapshot;
      try {
        querySnapshot = await _firestore
            .collection('events')
            .where('organiserId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();
      } catch (e) {
        debugPrint('Primary getUserEvents query failed, retrying without orderBy: $e');
        querySnapshot = await _firestore
            .collection('events')
            .where('organiserId', isEqualTo: userId)
            .get();
      }
      
      final results = querySnapshot.docs
          .map((doc) => EventModel.fromMap(doc.data()..['id'] = doc.id))
          .where((e) => e.isActive)
          .toList();
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    } catch (e) {
      debugPrint('Error getting user events: $e');
      // Return mock events for now
      return _mockEvents
          .where((event) => event.organiserId == userId && event.isActive)
          .toList();
    }
  }

  // Event Statistics
  Future<Map<String, dynamic>> getEventStatistics(String eventId) async {
    try {
      // Get event details
      final event = await getEvent(eventId);
      if (event == null) {
        throw Exception('Event not found');
      }
      
      // Get tickets for this event from Firestore
      List<TicketModel> tickets = [];
      try {
        final ticketsQuery = await _firestore
            .collection('tickets')
            .where('eventId', isEqualTo: eventId)
            .get();
        
        tickets = ticketsQuery.docs
            .map((doc) => TicketModel.fromMap(doc.data()..['id'] = doc.id))
            .toList();
      } catch (e) {
        debugPrint('Error fetching tickets for statistics: $e');
        // If there's an index error, return empty list but continue with event data
        tickets = [];
      }
      
      // Calculate real statistics from Firebase data
      final totalTickets = tickets.length;
      final usedTickets = tickets.where((ticket) => ticket.isUsed).length;
      final unusedTickets = totalTickets - usedTickets;
      
      // Calculate revenue (if event is not free)
      double totalRevenue = 0.0;
      if (!event.isFree) {
        totalRevenue = totalTickets * event.price;
      }
      
      // Calculate attendance rate
      final attendanceRate = totalTickets > 0 ? (usedTickets / totalTickets) * 100 : 0.0;
      
      // Get recent ticket sales (last 7 days)
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final recentTickets = tickets.where((ticket) => 
        ticket.purchasedAt.isAfter(weekAgo)
      ).length;
      
      // Get monthly ticket sales
      final monthAgo = now.subtract(const Duration(days: 30));
      final monthlyTickets = tickets.where((ticket) => 
        ticket.purchasedAt.isAfter(monthAgo)
      ).length;
      
      // Calculate average tickets per day
      final daysSinceCreation = event.createdAt != null 
          ? DateTime.now().difference(event.createdAt!).inDays 
          : 30;
      final avgTicketsPerDay = daysSinceCreation > 0 ? totalTickets / daysSinceCreation : 0.0;
      
      return {
        'totalTickets': totalTickets,
        'soldTickets': totalTickets,
        'usedTickets': usedTickets,
        'unusedTickets': unusedTickets,
        'totalRevenue': totalRevenue,
        'attendanceRate': attendanceRate,
        'recentSales': recentTickets,
        'monthlySales': monthlyTickets,
        'avgTicketsPerDay': avgTicketsPerDay,
        'eventCapacity': event.totalTickets,
        'availableTickets': event.availableTickets,
        'isSoldOut': event.isSoldOut,
        'eventDate': event.date,
        'eventStatus': event.status,
        'isActive': event.isActive,
        'daysSinceCreation': daysSinceCreation,
      };
    } catch (e) {
      debugPrint('Error getting event statistics: $e');
      // Return mock data on error
      return {
        'totalTickets': 0,
        'soldTickets': 0,
        'usedTickets': 0,
        'unusedTickets': 0,
        'totalRevenue': 0.0,
        'attendanceRate': 0.0,
        'recentSales': 0,
        'monthlySales': 0,
        'avgTicketsPerDay': 0.0,
        'eventCapacity': 0,
        'availableTickets': 0,
        'isSoldOut': false,
        'eventDate': DateTime.now(),
        'eventStatus': 'Unknown',
        'isActive': false,
        'daysSinceCreation': 0,
      };
    }
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

  // Access Control Operations
  Future<void> submitAccessAppeal(Map<String, dynamic> appealData) async {
    try {
      // Debug information
      debugPrint('=== FIRESTORE APPEAL DEBUG ===');
      debugPrint('Appeal Data: $appealData');
      debugPrint('User ID from data: ${appealData['userId']}');
      debugPrint('Event ID from data: ${appealData['eventId']}');
      debugPrint('Access Control ID from data: ${appealData['accessControlId']}');
      debugPrint('Current user: ${FirebaseAuth.instance.currentUser?.uid}');
      debugPrint('Is user signed in: ${FirebaseAuth.instance.currentUser != null}');
      debugPrint('==============================');

      // Validate required fields
      if (appealData['eventId'] == null || appealData['eventId'].toString().isEmpty) {
        throw Exception('Event ID is required');
      }
      if (appealData['userId'] == null || appealData['userId'].toString().isEmpty) {
        throw Exception('User ID is required');
      }
      if (appealData['reason'] == null || appealData['reason'].toString().trim().isEmpty) {
        throw Exception('Reason for appeal is required');
      }
      if (appealData['accessControlId'] == null || appealData['accessControlId'].toString().isEmpty) {
        throw Exception('Access control ID is required');
      }

      final String eventId = appealData['eventId'].toString();
      final String userId = appealData['userId'].toString();
      final String docId = '${eventId}_${userId}';
      final ref = _firestore.collection('access_appeals').doc(docId);
      
      debugPrint('Document ID: $docId');
      debugPrint('Collection: access_appeals');

      // Check if user already has an appeal for this event
      try {
        final existing = await ref.get();
        if (existing.exists) {
          final existingData = existing.data() as Map<String, dynamic>;
          final existingStatus = (existingData['status'] ?? 'pending') as String;
          debugPrint('Existing appeal found with status: $existingStatus');
          
          if (existingStatus == 'pending') {
            throw Exception('You already have a pending appeal for this event. Please wait for the organizer to review it.');
          } else if (existingStatus == 'approved') {
            throw Exception('Your appeal has already been approved for this event.');
          } else if (existingStatus == 'rejected') {
            // Allow resubmission after rejection
            debugPrint('Previous appeal was rejected, allowing new submission');
          }
        } else {
          debugPrint('No existing appeal found, proceeding with new submission');
        }
      } catch (e) {
        debugPrint('Error checking existing appeal: $e');
        // If we can't read existing appeals due to permissions, skip the check and proceed
        debugPrint('Skipping existing appeal check due to permission error');
      }

      final data = {
        ...appealData,
        'status': 'pending',
        'submittedAt': DateTime.now().toIso8601String(),
      };
      
      debugPrint('Attempting to write to Firestore...');
      debugPrint('Data to write: $data');
      
      // Use set() with the specific document ID to ensure consistency
      await ref.set(data);
      debugPrint('Successfully wrote to Firestore using set()');
    } catch (e) {
      throw Exception('Failed to submit access appeal: $e');
    }
  }

  Stream<String?> streamUserAppealStatus({
    required String eventId,
    required String userId,
  }) {
    final docId = '${eventId}_${userId}';
    return _firestore
        .collection('access_appeals')
        .doc(docId)
        .snapshots()
        .map((snap) => snap.exists ? (snap.data()!['status'] as String?) : null);
  }

  Stream<List<Map<String, dynamic>>> streamAppealsForEvent(String eventId) {
    try {
      return _firestore
          .collection('access_appeals')
          .where('eventId', isEqualTo: eventId)
          .snapshots()
          .map((snapshot) {
            final appeals = snapshot.docs
                .map((d) => (d.data()..['id'] = d.id))
                .toList();
            
            // Sort by submittedAt in descending order (newest first)
            appeals.sort((a, b) {
              final aDate = a['submittedAt'] as String?;
              final bDate = b['submittedAt'] as String?;
              if (aDate == null && bDate == null) return 0;
              if (aDate == null) return 1;
              if (bDate == null) return -1;
              return bDate.compareTo(aDate);
            });
            
            return appeals;
          });
    } catch (e) {
      // If permission denied, return empty stream with error handling
      debugPrint('Permission denied for appeals: $e');
      return Stream.value(<Map<String, dynamic>>[]);
    }
  }

  Future<String?> getAppealStatusOnce({
    required String eventId,
    required String userId,
  }) async {
    final docId = '${eventId}_${userId}';
    final snap = await _firestore.collection('access_appeals').doc(docId).get();
    if (snap.exists) {
      return (snap.data()!['status'] as String?);
    }
    return null;
  }

  Future<void> updateAppealStatus({
    required String eventId,
    required String userId,
    required String status, // 'approved' | 'rejected'
    String? reviewedBy,
    String? reviewerName,
    String? notes,
  }) async {
    try {
      final docId = '${eventId}_${userId}';
      
      // Debug information
      debugPrint('=== UPDATE APPEAL DEBUG ===');
      debugPrint('Event ID: $eventId');
      debugPrint('User ID: $userId');
      debugPrint('Document ID: $docId');
      debugPrint('Status: $status');
      debugPrint('Reviewed By: $reviewedBy');
      debugPrint('Current User: ${FirebaseAuth.instance.currentUser?.uid}');
      debugPrint('==========================');
      
      // First, check if the document exists and get the event info
      final docRef = _firestore.collection('access_appeals').doc(docId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        throw Exception('Appeal document not found');
      }
      
      final appealData = doc.data() as Map<String, dynamic>;
      final appealEventId = appealData['eventId'] as String?;
      
      debugPrint('Appeal Event ID: $appealEventId');
      
      // Check if current user is the organizer of this event
      if (appealEventId != null) {
        final eventDoc = await _firestore.collection('events').doc(appealEventId).get();
        if (eventDoc.exists) {
          final eventData = eventDoc.data() as Map<String, dynamic>;
          final organizerId = eventData['organiserId'] as String?;
          debugPrint('Event Organizer ID: $organizerId');
          debugPrint('Current User is Organizer: ${FirebaseAuth.instance.currentUser?.uid == organizerId}');
        }
      }
      
      // Try update first
      try {
        await docRef.update({
          'status': status,
          'reviewedAt': FieldValue.serverTimestamp(),
          if (reviewedBy != null) 'reviewedBy': reviewedBy,
          if (reviewerName != null) 'reviewerName': reviewerName,
          if (notes != null) 'reviewNotes': notes,
        });
        debugPrint('Successfully updated appeal status using update()');
      } catch (e) {
        debugPrint('Update failed, trying set() with merge: $e');
        // If update fails, try set with merge
        await docRef.set({
          'status': status,
          'reviewedAt': FieldValue.serverTimestamp(),
          if (reviewedBy != null) 'reviewedBy': reviewedBy,
          if (reviewerName != null) 'reviewerName': reviewerName,
          if (notes != null) 'reviewNotes': notes,
        }, SetOptions(merge: true));
        debugPrint('Successfully updated appeal status using set() with merge');
      }
      
      debugPrint('Successfully updated appeal status');
    } catch (e) {
      debugPrint('Error updating appeal status: $e');
      throw Exception('Failed to update appeal status: $e');
    }
  }

  // Mock data generation
  List<EventModel> _generateMockEvents() {
    final staticUpcomingEvents = [
      EventModel(
        id: 'upcoming-1',
        title: 'Summer Music Festival',
        description: 'A fantastic summer music festival featuring top artists from around the world.',
        location: 'Central Park, NY',
        latitude: 40.7829,
        longitude: -73.9654,
        date: DateTime(2024, 8, 15, 18, 0), // August 15, 2024 at 6:00 PM
        time: DateTime(2024, 8, 15, 18, 0), // August 15, 2024 at 6:00 PM
        totalTickets: 1000,
        soldTickets: 750,
        price: 50.0,
        isFree: false,
        organiserId: 'mock-organiser-1',
        organiserName: 'Music Events Inc',
        bannerImage: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800&h=600&fit=crop',
        category: 'Music',
        tags: ['music', 'festival', 'summer', 'outdoor'],
        isActive: true,
        isFeatured: true,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      EventModel(
        id: 'upcoming-2',
        title: 'Tech Startup Meetup',
        description: 'Connect with fellow entrepreneurs and tech enthusiasts.',
        location: 'Innovation Hub, SF',
        latitude: 37.7749,
        longitude: -122.4194,
        date: DateTime(2024, 7, 20, 19, 0), // July 20, 2024 at 7:00 PM
        time: DateTime(2024, 7, 20, 19, 0), // July 20, 2024 at 7:00 PM
        totalTickets: 200,
        soldTickets: 150,
        price: 25.0,
        isFree: false,
        organiserId: 'mock-organiser-2',
        organiserName: 'Tech Community',
        bannerImage: 'https://images.unsplash.com/photo-1515187029135-18ee286d815b?w=800&h=600&fit=crop',
        category: 'Technology',
        tags: ['tech', 'startup', 'networking', 'business'],
        isActive: true,
        isFeatured: true,
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      EventModel(
        id: 'upcoming-3',
        title: 'Food & Wine Expo',
        description: 'Experience the finest cuisines and wines from around the world.',
        location: 'Convention Center, LA',
        latitude: 34.0522,
        longitude: -118.2437,
        date: DateTime(2024, 9, 10, 16, 0), // September 10, 2024 at 4:00 PM
        time: DateTime(2024, 9, 10, 16, 0), // September 10, 2024 at 4:00 PM
        totalTickets: 500,
        soldTickets: 300,
        price: 75.0,
        isFree: false,
        organiserId: 'mock-organiser-3',
        organiserName: 'Culinary Arts Society',
        bannerImage: 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800&h=600&fit=crop',
        category: 'Food & Drink',
        tags: ['food', 'wine', 'culinary', 'expo'],
        isActive: true,
        isFeatured: false,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      EventModel(
        id: 'upcoming-4',
        title: 'Art Gallery Opening',
        description: 'Exclusive opening of contemporary art exhibition.',
        location: 'Modern Art Museum, Chicago',
        latitude: 41.8781,
        longitude: -87.6298,
        date: DateTime(2024, 7, 25, 18, 0), // July 25, 2024 at 6:00 PM
        time: DateTime(2024, 7, 25, 18, 0), // July 25, 2024 at 6:00 PM
        totalTickets: 150,
        soldTickets: 100,
        price: 30.0,
        isFree: false,
        organiserId: 'mock-organiser-4',
        organiserName: 'Art Society',
        bannerImage: 'https://images.unsplash.com/photo-1541961017774-22349e4a1263?w=800&h=600&fit=crop',
        category: 'Arts & Culture',
        tags: ['art', 'gallery', 'exhibition', 'culture'],
        isActive: true,
        isFeatured: false,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      EventModel(
        id: 'upcoming-5',
        title: 'Free Community Workshop',
        description: 'Learn new skills in this free community workshop.',
        location: 'Community Center, Austin',
        latitude: 30.2672,
        longitude: -97.7431,
        date: DateTime(2024, 7, 15, 14, 0), // July 15, 2024 at 2:00 PM
        time: DateTime(2024, 7, 15, 14, 0), // July 15, 2024 at 2:00 PM
        totalTickets: 100,
        soldTickets: 80,
        price: 0.0,
        isFree: true,
        organiserId: 'mock-organiser-5',
        organiserName: 'Community Events',
        bannerImage: 'https://images.unsplash.com/photo-1515187029135-18ee286d815b?w=800&h=600&fit=crop',
        category: 'Education',
        tags: ['workshop', 'free', 'community', 'learning'],
        isActive: true,
        isFeatured: true,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];

    final staticPastEvents = [
      EventModel(
        id: 'past-1',
        title: 'Winter Music Festival',
        description: 'A memorable winter music festival that brought together amazing artists.',
        location: 'Central Park, NY',
        latitude: 40.7829,
        longitude: -73.9654,
        date: DateTime(2024, 1, 15, 18, 0), // January 15, 2024 at 6:00 PM
        time: DateTime(2024, 1, 15, 18, 0), // January 15, 2024 at 6:00 PM
        totalTickets: 800,
        soldTickets: 800,
        price: 45.0,
        isFree: false,
        organiserId: 'mock-organiser-1',
        organiserName: 'Music Events Inc',
        bannerImage: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800&h=600&fit=crop',
        category: 'Music',
        tags: ['music', 'festival', 'past', 'completed'],
        isActive: true,
        isFeatured: false,
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
      ),
      EventModel(
        id: 'past-2',
        title: 'Tech Conference',
        description: 'A successful technology conference that brought together industry leaders.',
        location: 'Convention Center, SF',
        latitude: 37.7749,
        longitude: -122.4194,
        date: DateTime(2024, 2, 20, 9, 0), // February 20, 2024 at 9:00 AM
        time: DateTime(2024, 2, 20, 9, 0), // February 20, 2024 at 9:00 AM
        totalTickets: 300,
        soldTickets: 300,
        price: 100.0,
        isFree: false,
        organiserId: 'mock-organiser-5',
        organiserName: 'Tech Events Corp',
        bannerImage: 'https://images.unsplash.com/photo-1515187029135-18ee286d815b?w=800&h=600&fit=crop',
        category: 'Technology',
        tags: ['tech', 'conference', 'past', 'completed'],
        isActive: true,
        isFeatured: false,
        createdAt: DateTime.now().subtract(const Duration(days: 150)),
      ),
      EventModel(
        id: 'past-3',
        title: 'Food & Wine Expo',
        description: 'A memorable culinary experience that showcased the best of food and wine.',
        location: 'Downtown Plaza, LA',
        latitude: 34.0522,
        longitude: -118.2437,
        date: DateTime(2024, 3, 10, 16, 0), // March 10, 2024 at 4:00 PM
        time: DateTime(2024, 3, 10, 16, 0), // March 10, 2024 at 4:00 PM
        totalTickets: 200,
        soldTickets: 200,
        price: 75.0,
        isFree: false,
        organiserId: 'mock-organiser-6',
        organiserName: 'Culinary Arts Society',
        bannerImage: 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800&h=600&fit=crop',
        category: 'Food & Drink',
        tags: ['food', 'wine', 'past', 'completed'],
        isActive: true,
        isFeatured: false,
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
      ),
      EventModel(
        id: 'past-4',
        title: 'Art Gallery Opening',
        description: 'A beautiful art exhibition that featured local artists.',
        location: 'Modern Art Museum, Chicago',
        latitude: 41.8781,
        longitude: -87.6298,
        date: DateTime(2024, 2, 25, 18, 0), // February 25, 2024 at 6:00 PM
        time: DateTime(2024, 2, 25, 18, 0), // February 25, 2024 at 6:00 PM
        totalTickets: 150,
        soldTickets: 150,
        price: 25.0,
        isFree: false,
        organiserId: 'mock-organiser-7',
        organiserName: 'Art Society',
        bannerImage: 'https://images.unsplash.com/photo-1541961017774-22349e4a1263?w=800&h=600&fit=crop',
        category: 'Arts & Culture',
        tags: ['art', 'gallery', 'exhibition', 'past', 'completed'],
        isActive: true,
        isFeatured: false,
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
      ),
      EventModel(
        id: 'past-5',
        title: 'Startup Meetup',
        description: 'An inspiring startup meetup that connected entrepreneurs.',
        location: 'Innovation Hub, Austin',
        latitude: 30.2672,
        longitude: -97.7431,
        date: DateTime(2024, 1, 30, 19, 0), // January 30, 2024 at 7:00 PM
        time: DateTime(2024, 1, 30, 19, 0), // January 30, 2024 at 7:00 PM
        totalTickets: 80,
        soldTickets: 80,
        price: 15.0,
        isFree: false,
        organiserId: 'mock-organiser-8',
        organiserName: 'Startup Community',
        bannerImage: 'https://images.unsplash.com/photo-1515187029135-18ee286d815b?w=800&h=600&fit=crop',
        category: 'Business',
        tags: ['startup', 'business', 'networking', 'past', 'completed'],
        isActive: true,
        isFeatured: false,
        createdAt: DateTime.now().subtract(const Duration(days: 220)),
      ),
    ];

    return [...staticUpcomingEvents, ...staticPastEvents];
  }
} 