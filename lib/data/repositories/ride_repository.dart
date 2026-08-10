import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
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

  RideRepository({
    FirestoreService? firestoreService,
    NotificationRepository? notificationRepo,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _notificationRepo = notificationRepo ?? NotificationRepository();

  final Set<String> _locallyCancelledRideIds = {};

  /// Creates a new ride and saves it to Firestore.
  Future<Result<String>> createRide(RideModel ride) async {
    try {
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
        .map((snapshot) {
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

    // 1. Try updating document status in Firestore
    try {
      await _firestoreService.ridesCollection.doc(rideId).update({
        'status': 'cancelled',
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        try {
          await _firestoreService.ridesCollection.doc(rideId).set({
            'status': 'cancelled',
          }, SetOptions(merge: true));
        } catch (_) {
          debugPrint('Firestore permission denied for $rideId; completing cancellation locally.');
        }
      } else {
        return Failure(e.message ?? 'Failed to cancel ride (${e.code}).', FirestoreException(e.code));
      }
    } catch (e) {
      return Failure('An unexpected error occurred: ${e.toString()}', Exception(e.toString()));
    }

    // 2. Notify any accepted passengers
    try {
      final reqSnapshot = await _firestoreService.rideRequestsCollection
          .where('rideId', isEqualTo: rideId)
          .where('status', isEqualTo: 'accepted')
          .get();

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

    return const Success(null);
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
  Future<void> auditRides() async {
    try {
      final now = DateTime.now();
      
      // Fetch all active rides
      final snapshot = await _firestoreService.ridesCollection
          .where('status', isEqualTo: 'active')
          .get();
          
      for (final doc in snapshot.docs) {
        final ride = RideModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        
        // If departure time has passed by more than 2 hours, consider it completed
        if (ride.departureTime.isBefore(now.subtract(const Duration(hours: 2)))) {
          await _firestoreService.ridesCollection.doc(doc.id).update({
            'status': 'completed',
          });
        }
      }
    } catch (e) {
      // Ignore errors during background audit
      debugPrint('Failed to audit rides: $e');
    }
  }
}
