import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/services/firestore_service.dart';
import '../../core/utils/result.dart';
import '../models/ride_model.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

/// Repository responsible for all Ride Firestore operations.
///
/// Firestore `rides` is the single source of truth.
/// There is NO local device cache for ride records — all reads/writes go directly to Firestore.
class RideRepository {
  final FirestoreService _firestoreService;
  final NotificationRepository _notificationRepo;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  RideRepository({
    FirestoreService? firestoreService,
    NotificationRepository? notificationRepo,
  }) : _firestoreService = firestoreService ?? FirestoreService(),
       _notificationRepo = notificationRepo ?? NotificationRepository();

  // ---------------------------------------------------------------------------
  // CREATE
  // ---------------------------------------------------------------------------

  /// Creates a new ride document in Firestore.
  ///
  /// Returns [Success] with the generated document ID, or [Failure] if the write fails.
  Future<Result<String>> createRide(RideModel ride) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return Failure(
          'User is not authenticated. Please sign in to create a ride.',
          Exception('Unauthenticated'),
        );
      }

      // Always use the authenticated UID — never a fallback string
      final driverId = currentUser.uid;

      final docRef = _firestoreService.ridesCollection.doc();
      final newRide = ride.copyWith(
        id: docRef.id,
        driverId: driverId,
        createdAt: DateTime.now(),
        status: 'active',
      );

      // Write to Firestore and AWAIT the result — the write IS the source of truth
      await docRef.set(newRide.toMap());

      debugPrint(
        '[RideRepository] CREATE success | collection: rides | documentId: ${newRide.id} | driverId: $driverId',
      );

      unawaited(
        _analytics.logEvent(
          name: 'ride_created',
          parameters: {'driverId': driverId, 'destination': ride.destination},
        ),
      );

      return Success(newRide.id);
    } on FirebaseException catch (e) {
      debugPrint('[RideRepository] CREATE failed | [${e.code}] ${e.message}');
      return Failure(
        'Could not save ride (${e.code}). Please try again.',
        FirestoreException(e.code),
      );
    } catch (e) {
      debugPrint('[RideRepository] CREATE unexpected error: $e');
      return Failure(
        'Could not create ride. Please try again.',
        Exception(e.toString()),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // READ — Stream (My Rides)
  // ---------------------------------------------------------------------------

  /// Streams all rides where [driverId] matches the authenticated creator.
  /// Uses a real Firestore snapshot listener — updates appear automatically.
  Stream<List<RideModel>> streamRidesByDriver(String driverId) {
    debugPrint(
      '[RideRepository] MY RIDES stream started | driverId: $driverId',
    );

    return _firestoreService.ridesCollection
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
          final rides = snapshot.docs
              .map(
                (doc) => RideModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
          rides.sort((a, b) => b.departureTime.compareTo(a.departureTime));
          debugPrint(
            '[RideRepository] MY RIDES update | driverId: $driverId | resultCount: ${rides.length}',
          );
          return rides;
        })
        .handleError((error) {
          debugPrint('[RideRepository] MY RIDES stream error: $error');
          // Re-throw so the StreamProvider surfaces the error properly
          throw error;
        });
  }

  /// Streams a single ride by ID.
  Stream<RideModel?> streamRide(String rideId) {
    return _firestoreService.ridesCollection
        .doc(rideId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return RideModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        })
        .handleError((error) {
          debugPrint('[RideRepository] streamRide error: $error');
          return null;
        });
  }

  // ---------------------------------------------------------------------------
  // CANCEL (status update)
  // ---------------------------------------------------------------------------

  /// Cancels a ride by updating its Firestore status to 'cancelled'.
  ///
  /// Awaits Firestore confirmation before returning Success.
  Future<Result<void>> cancelRide(String rideId) async {
    try {
      await _firestoreService.ridesCollection.doc(rideId).update({
        'status': 'cancelled',
      });

      debugPrint('[RideRepository] CANCEL success | documentId: $rideId');

      // Notify accepted passengers asynchronously — does not block cancel result
      unawaited(_notifyPassengersOfCancellation(rideId));

      return const Success(null);
    } on FirebaseException catch (e) {
      debugPrint('[RideRepository] CANCEL failed | [${e.code}] ${e.message}');
      return Failure(
        'Unable to cancel this ride (${e.code}). Please try again.',
        FirestoreException(e.code),
      );
    } catch (e) {
      debugPrint('[RideRepository] CANCEL unexpected error: $e');
      return Failure(
        'An unexpected error occurred. Please try again.',
        Exception(e.toString()),
      );
    }
  }

  Future<void> _notifyPassengersOfCancellation(String rideId) async {
    try {
      final reqSnapshot = await _firestoreService.rideRequestsCollection
          .where('rideId', isEqualTo: rideId)
          .where('status', isEqualTo: 'accepted')
          .get()
          .timeout(const Duration(seconds: 5));

      for (final doc in reqSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final passengerUid = data['requesterUid'] as String?;
        if (passengerUid != null && passengerUid.isNotEmpty) {
          unawaited(
            _notificationRepo.createNotification(
              NotificationModel(
                id: '',
                userId: passengerUid,
                title: 'Ride Cancelled',
                body: 'A ride you joined has been cancelled by the driver.',
                type: 'cancelled',
                isRead: false,
                createdAt: DateTime.now(),
                relatedId: rideId,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint(
        '[RideRepository] Failed to send cancellation notifications: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE (permanent)
  // ---------------------------------------------------------------------------

  /// Permanently deletes a ride document and all associated ride requests.
  ///
  /// Uses a Firestore batch to atomically delete the ride + its requests.
  /// Returns [Failure] with a user-facing message if the delete fails —
  /// the UI should display this message and NOT optimistically remove the card.
  Future<Result<void>> deleteRide(String rideId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return Failure(
          'You must be signed in to delete a ride.',
          Exception('Unauthenticated'),
        );
      }

      // 1. Fetch associated ride requests
      final reqSnapshot = await _firestoreService.rideRequestsCollection
          .where('rideId', isEqualTo: rideId)
          .get();

      // 2. Batch delete: requests + the ride document itself
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in reqSnapshot.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_firestoreService.ridesCollection.doc(rideId));

      // 3. Commit and AWAIT — only report success after Firestore confirms
      await batch.commit();

      debugPrint(
        '[RideRepository] DELETE success | documentId: $rideId | uid: ${currentUser.uid}',
      );
      return const Success(null);
    } on FirebaseException catch (e) {
      debugPrint(
        '[RideRepository] DELETE failed | documentId: $rideId | [${e.code}] ${e.message}',
      );
      return Failure(
        'Unable to delete this ride (${e.code}). Please try again.',
        FirestoreException(e.code),
      );
    } catch (e) {
      debugPrint('[RideRepository] DELETE unexpected error: $e');
      return Failure(
        'An unexpected error occurred while deleting. Please try again.',
        Exception(e.toString()),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // AUDIT (background task)
  // ---------------------------------------------------------------------------

  /// Silently marks rides as 'completed' if their departure time was more than 2 hours ago.
  Future<void> auditRides([String? driverId]) async {
    try {
      final now = DateTime.now();

      Query query = _firestoreService.ridesCollection.where(
        'status',
        isEqualTo: 'active',
      );
      if (driverId != null && driverId.isNotEmpty) {
        query = query.where('driverId', isEqualTo: driverId);
      }

      final snapshot = await query.get();

      for (final doc in snapshot.docs) {
        final ride = RideModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        if (ride.departureTime.isBefore(
          now.subtract(const Duration(hours: 2)),
        )) {
          try {
            await _firestoreService.ridesCollection.doc(doc.id).update({
              'status': 'completed',
            });
            debugPrint('[RideRepository] AUDIT completed ride ${doc.id}');
          } catch (e) {
            debugPrint(
              '[RideRepository] AUDIT could not update ride ${doc.id}: $e',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[RideRepository] AUDIT failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // SEARCH (Find Ride)
  // ---------------------------------------------------------------------------

  /// Searches for active rides in Firestore matching the user-specified criteria.
  ///
  /// All filtering is client-side after a single Firestore query on `status == 'active'`,
  /// which avoids composite index requirements.
  Future<Result<List<RideModel>>> searchRides({
    required String boardingLocation,
    required String destination,
    required int seats,
    required double maxFare,
    required bool isGirlsOnly,
    DateTime? departureTime,
  }) async {
    try {
      // Allow rides departing up to 1 hour ago — so a ride created "right now" remains searchable
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 1));

      QuerySnapshot snapshot;
      try {
        snapshot = await _firestoreService.ridesCollection
            .where('status', isEqualTo: 'active')
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 6));
      } on FirebaseException catch (e) {
        debugPrint(
          '[RideRepository] SEARCH Firestore error | [${e.code}] ${e.message}',
        );
        return Failure(
          'Could not reach the server (${e.code}). Please check your connection.',
          FirestoreException(e.code),
        );
      }

      debugPrint(
        '[RideRepository] SEARCH raw results from Firestore: ${snapshot.docs.length}',
      );

      final List<RideModel> results = [];

      for (final doc in snapshot.docs) {
        final ride = RideModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

        // Client-side filters (in order of cheapest to most expensive)
        if (ride.availableSeats < seats) continue;
        if (ride.farePerSeat > maxFare) continue;
        if (ride.departureTime.isBefore(cutoffTime)) continue;
        if (isGirlsOnly && !ride.isGirlsOnly) continue;

        if (boardingLocation.isNotEmpty &&
            !ride.boardingLocation.toLowerCase().contains(
              boardingLocation.toLowerCase(),
            )) {
          continue;
        }
        if (destination.isNotEmpty &&
            !ride.destination.toLowerCase().contains(
              destination.toLowerCase(),
            )) {
          continue;
        }
        if (departureTime != null &&
            ride.departureTime.isBefore(departureTime)) {
          continue;
        }

        results.add(ride);
      }

      results.sort((a, b) => a.departureTime.compareTo(b.departureTime));

      debugPrint(
        '[RideRepository] SEARCH final results: ${results.length} | query: "$boardingLocation → $destination"',
      );
      return Success(results);
    } catch (e) {
      debugPrint('[RideRepository] SEARCH unexpected error: $e');
      return Failure(
        'An unexpected error occurred during search.',
        Exception(e.toString()),
      );
    }
  }
}
