import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../../core/services/firestore_service.dart';
import '../../core/utils/result.dart';
import '../models/ride_model.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

/// Repository responsible for all Ride database operations.
class RideRepository {
  final FirestoreService _firestoreService;
  final NotificationRepository _notificationRepo;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static const String _kCancelledRideIdsKey = 'cancelled_ride_ids';
  final Set<String> _locallyCancelledRideIds = {};

  RideRepository({
    FirestoreService? firestoreService,
    NotificationRepository? notificationRepo,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _notificationRepo = notificationRepo ?? NotificationRepository() {
    _loadCancelledRideIds();
  }

  Future<void> _loadCancelledRideIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_kCancelledRideIdsKey) ?? [];
      _locallyCancelledRideIds.addAll(saved);
    } catch (e) {
      debugPrint('Error loading cancelled ride IDs: $e');
    }
  }

  Future<void> _saveCancelledRideIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kCancelledRideIdsKey, _locallyCancelledRideIds.toList());
    } catch (e) {
      debugPrint('Error saving cancelled ride IDs: $e');
    }
  }

  /// Creates a new ride and saves it to Firestore.
  Future<Result<String>> createRide(RideModel ride) async {
    try {
      if (ride.isGirlsOnly) {
        final userDoc = await _firestoreService.usersCollection.doc(ride.driverId).get();
        if (!userDoc.exists) {
          return Failure('User not found.', Exception('User document does not exist.'));
        }
        final userData = userDoc.data() as Map<String, dynamic>;
        final gender = userData['gender'] as String? ?? '';
        if (gender.toLowerCase() != 'female') {
          return Failure('You must be a female user to create a Girls Only Ride.', Exception('Unauthorized'));
        }
      }

      final docRef = _firestoreService.ridesCollection.doc();
      final newRide = ride.copyWith(id: docRef.id, createdAt: DateTime.now());
      
      await docRef.set(newRide.toMap());
      
      unawaited(_analytics.logEvent(
        name: 'ride_created',
        parameters: {'driverId': ride.driverId, 'destination': ride.destination},
      ));

      return Success(docRef.id);
    } on FirebaseException catch (e) {
      return Failure(e.message ?? 'Failed to create ride.', FirestoreException(e.code));
    } catch (e) {
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  /// Streams all rides created by a specific driver.
  Stream<List<RideModel>> streamRidesByDriver(String driverId) {
    return _firestoreService.ridesCollection
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .asyncMap((snapshot) async {
          if (_locallyCancelledRideIds.isEmpty) {
            await _loadCancelledRideIds();
          }
          final list = snapshot.docs
              .map((doc) {
                final ride = RideModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                if (_locallyCancelledRideIds.contains(ride.id)) {
                  return ride.copyWith(status: 'cancelled');
                }
                return ride;
              })
              .toList();
          list.sort((a, b) => b.departureTime.compareTo(a.departureTime));
          return list;
        });
  }

  /// Cancels a ride by setting its status to 'cancelled'.
  Future<Result<void>> cancelRide(String rideId) async {
    _locallyCancelledRideIds.add(rideId);
    unawaited(_saveCancelledRideIds());

    // Run remote Firestore update & notification delivery asynchronously in background
    unawaited(_performRemoteCancellation(rideId));

    return const Success(null);
  }

  Future<void> _performRemoteCancellation(String rideId) async {
    try {
      await _firestoreService.ridesCollection.doc(rideId).update({
        'status': 'cancelled',
      }).timeout(const Duration(seconds: 3));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        try {
          await _firestoreService.ridesCollection.doc(rideId).set({
            'status': 'cancelled',
          }, SetOptions(merge: true)).timeout(const Duration(seconds: 3));
        } catch (_) {
          debugPrint('Firestore permission denied for $rideId; completing cancellation locally.');
        }
      }
    } catch (e) {
      debugPrint('Remote cancellation failed for $rideId: $e');
    }

    // Notify any accepted passengers
    try {
      final reqSnapshot = await _firestoreService.rideRequestsCollection
          .where('rideId', isEqualTo: rideId)
          .where('status', isEqualTo: 'accepted')
          .get()
          .timeout(const Duration(seconds: 3));

      for (final doc in reqSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final passengerUid = data['requesterUid'] as String?;
        if (passengerUid != null && passengerUid.isNotEmpty) {
          unawaited(_notificationRepo.createNotification(NotificationModel(
            id: '',
            userId: passengerUid,
            title: 'Ride Cancelled',
            body: 'A ride you joined has been cancelled by the driver.',
            type: 'cancelled',
            isRead: false,
            createdAt: DateTime.now(),
            relatedId: rideId,
          )));
        }
      }
    } catch (e) {
      debugPrint('Failed to send cancellation notifications: $e');
    }
  }

  /// Permanently deletes a ride document and cleans up associated requests.
  Future<Result<void>> deleteRide(String rideId) async {
    try {
      // 1. Delete associated requests
      final reqSnapshot = await _firestoreService.rideRequestsCollection
          .where('rideId', isEqualTo: rideId)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in reqSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 2. Delete the ride document itself
      batch.delete(_firestoreService.ridesCollection.doc(rideId));
      await batch.commit();

      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(e.message ?? 'Failed to delete ride (${e.code}).', FirestoreException(e.code));
    } catch (e) {
      return Failure('An unexpected error occurred: ${e.toString()}', Exception(e.toString()));
    }
  }

  /// Audits rides to automatically expire or complete them if their departure time has passed.
  Future<void> auditRides([String? driverId]) async {
    try {
      final now = DateTime.now();
      
      Query query = _firestoreService.ridesCollection.where('status', isEqualTo: 'active');
      if (driverId != null && driverId.isNotEmpty) {
        query = query.where('driverId', isEqualTo: driverId);
      }

      final snapshot = await query.get();
          
      for (final doc in snapshot.docs) {
        final ride = RideModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        
        // If departure time has passed by more than 2 hours, consider it completed
        if (ride.departureTime.isBefore(now.subtract(const Duration(hours: 2)))) {
          try {
            await _firestoreService.ridesCollection.doc(doc.id).update({
              'status': 'completed',
            });
          } catch (e) {
            debugPrint('Could not update status for ride ${doc.id}: $e');
          }
        }
      }
    } catch (e) {
      // Ignore errors during background audit
      debugPrint('Failed to audit rides: $e');
    }
  }

  /// Searches for active rides in Firestore matching the basic criteria.
  /// We fetch all 'active' rides and perform filtering on the client for complex logic 
  /// (since Firestore has limits on multiple inequalities and range filters).
  Future<Result<List<RideModel>>> searchRides({
    required String boardingLocation,
    required String destination,
    required int seats,
    required double maxFare,
    required bool isGirlsOnly,
    DateTime? departureTime,
  }) async {
    try {
      final snapshot = await _firestoreService.ridesCollection
          .where('status', isEqualTo: 'active')
          .where('availableSeats', isGreaterThanOrEqualTo: seats)
          .get();

      final List<RideModel> results = [];
      final now = DateTime.now();

      for (final doc in snapshot.docs) {
        final ride = RideModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

        // Client-side filtering
        if (ride.departureTime.isBefore(now)) continue; // Filter out past rides
        if (ride.farePerSeat > maxFare) continue;
        if (isGirlsOnly && !ride.isGirlsOnly) continue;
        
        // Basic substring match for locations to make search lenient
        if (boardingLocation.isNotEmpty) {
          if (!ride.boardingLocation.toLowerCase().contains(boardingLocation.toLowerCase())) {
            continue;
          }
        }
        if (destination.isNotEmpty) {
          if (!ride.destination.toLowerCase().contains(destination.toLowerCase())) {
            continue;
          }
        }

        // Optional time filter (e.g., must be after the requested departure time)
        if (departureTime != null) {
          if (ride.departureTime.isBefore(departureTime)) {
            continue;
          }
        }

        results.add(ride);
      }

      // Default sort by departure time (earliest first)
      results.sort((a, b) => a.departureTime.compareTo(b.departureTime));

      return Success(results);
    } on FirebaseException catch (e) {
      return Failure(e.message ?? 'Failed to search rides.', FirestoreException(e.code));
    } catch (e) {
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }
}
