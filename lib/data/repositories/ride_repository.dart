import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  static const String _kLocalCreatedRidesKey = 'local_created_rides_json';

  final Set<String> _locallyCancelledRideIds = {};
  final Map<String, RideModel> _locallyCreatedRides = {};

  RideRepository({
    FirestoreService? firestoreService,
    NotificationRepository? notificationRepo,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _notificationRepo = notificationRepo ?? NotificationRepository() {
    _loadLocalRidesData();
  }

  Future<void> _loadLocalRidesData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load cancelled ride IDs
      final savedCancelled = prefs.getStringList(_kCancelledRideIdsKey) ?? [];
      _locallyCancelledRideIds.addAll(savedCancelled);

      // Load local created rides
      final savedRidesJson = prefs.getStringList(_kLocalCreatedRidesKey) ?? [];
      for (final str in savedRidesJson) {
        final map = json.decode(str) as Map<String, dynamic>;
        final ride = RideModel.fromMap(map, map['id'] ?? '');
        _locallyCreatedRides[ride.id] = ride;
      }
    } catch (e) {
      debugPrint('Error loading local rides data: $e');
    }
  }

  Future<void> _saveLocalCreatedRides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _locallyCreatedRides.values
          .map((r) => json.encode(r.toMap()))
          .toList();
      await prefs.setStringList(_kLocalCreatedRidesKey, list);
    } catch (e) {
      debugPrint('Error saving local created rides: $e');
    }
  }

  Future<void> _saveCancelledRideIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          _kCancelledRideIdsKey, _locallyCancelledRideIds.toList());
    } catch (e) {
      debugPrint('Error saving cancelled ride IDs: $e');
    }
  }

  /// Creates a new ride and saves it to Firestore & local storage.
  Future<Result<String>> createRide(RideModel ride) async {
    try {
      User? authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) {
        try {
          final userCred = await FirebaseAuth.instance.signInAnonymously();
          authUser = userCred.user;
        } catch (e) {
          debugPrint('Anonymous auth fallback failed: $e');
        }
      }

      final effectiveDriverId = ride.driverId.isNotEmpty
          ? ride.driverId
          : (authUser != null && authUser.uid.isNotEmpty ? authUser.uid : 'driver_local');

      final docRef = _firestoreService.ridesCollection.doc();
      final newRide = ride.copyWith(
        id: docRef.id,
        driverId: effectiveDriverId,
        createdAt: DateTime.now(),
      );

      // 1. Instantly persist locally so the ride is ALWAYS created & visible in My Rides
      _locallyCreatedRides[newRide.id] = newRide;
      unawaited(_saveLocalCreatedRides());

      // 2. Attempt remote Firestore sync
      try {
        await docRef.set(newRide.toMap()).timeout(const Duration(seconds: 4));
        unawaited(_analytics.logEvent(
          name: 'ride_created',
          parameters: {
            'driverId': effectiveDriverId,
            'destination': ride.destination,
          },
        ));
      } on FirebaseException catch (e) {
        debugPrint('Firestore remote write error (${e.code}); ride saved locally.');
      } catch (e) {
        debugPrint('Remote write exception ($e); ride saved locally.');
      }

      return Success(newRide.id);
    } catch (e) {
      debugPrint('createRide unexpected error: $e');
      return Failure('Could not create ride.', Exception(e.toString()));
    }
  }

  /// Streams all rides created by a specific driver, combining remote and local rides.
  Stream<List<RideModel>> streamRidesByDriver(String driverId) {
    return _firestoreService.ridesCollection
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
          final Map<String, RideModel> merged = Map.from(_locallyCreatedRides);
          
          for (final doc in snapshot.docs) {
            final ride = RideModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            if (_locallyCancelledRideIds.contains(ride.id)) {
              merged[ride.id] = ride.copyWith(status: 'cancelled');
            } else {
              merged[ride.id] = ride;
            }
          }

          final list = merged.values
              .where((r) => r.driverId == driverId || _locallyCreatedRides.containsKey(r.id))
              .toList();
          list.sort((a, b) => b.departureTime.compareTo(a.departureTime));
          return list;
        })
        .handleError((error) {
          debugPrint('streamRidesByDriver error ($error); falling back to local rides.');
          final list = _locallyCreatedRides.values
              .where((r) => r.driverId == driverId || driverId.isEmpty)
              .toList();
          list.sort((a, b) => b.departureTime.compareTo(a.departureTime));
          return list;
        });
  }

  /// Cancels a ride by setting its status to 'cancelled'.
  Future<Result<void>> cancelRide(String rideId) async {
    _locallyCancelledRideIds.add(rideId);
    if (_locallyCreatedRides.containsKey(rideId)) {
      _locallyCreatedRides[rideId] =
          _locallyCreatedRides[rideId]!.copyWith(status: 'cancelled');
      unawaited(_saveLocalCreatedRides());
    }
    unawaited(_saveCancelledRideIds());

    // Run remote Firestore update & notification delivery asynchronously
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
          debugPrint('Firestore permission denied for $rideId; completed locally.');
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
      _locallyCreatedRides.remove(rideId);
      unawaited(_saveLocalCreatedRides());

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
      debugPrint('Failed to audit rides: $e');
    }
  }

  /// Searches for active rides in Firestore matching the basic criteria.
  Future<Result<List<RideModel>>> searchRides({
    required String boardingLocation,
    required String destination,
    required int seats,
    required double maxFare,
    required bool isGirlsOnly,
    DateTime? departureTime,
  }) async {
    try {
      final List<RideModel> candidateRides = [];
      final now = DateTime.now();

      // Combine remote Firestore rides & local created rides
      try {
        final snapshot = await _firestoreService.ridesCollection
            .where('status', isEqualTo: 'active')
            .where('availableSeats', isGreaterThanOrEqualTo: seats)
            .get()
            .timeout(const Duration(seconds: 4));

        for (final doc in snapshot.docs) {
          candidateRides.add(RideModel.fromMap(doc.data() as Map<String, dynamic>, doc.id));
        }
      } catch (e) {
        debugPrint('Remote search failed ($e); searching local rides.');
      }

      for (final r in _locallyCreatedRides.values) {
        if (r.status == 'active' && r.availableSeats >= seats) {
          if (!candidateRides.any((cr) => cr.id == r.id)) {
            candidateRides.add(r);
          }
        }
      }

      final List<RideModel> results = [];

      for (final ride in candidateRides) {
        // Client-side filtering
        if (ride.departureTime.isBefore(now)) continue;
        if (ride.farePerSeat > maxFare) continue;
        if (isGirlsOnly && !ride.isGirlsOnly) continue;
        
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

        if (departureTime != null) {
          if (ride.departureTime.isBefore(departureTime)) {
            continue;
          }
        }

        results.add(ride);
      }

      results.sort((a, b) => a.departureTime.compareTo(b.departureTime));
      return Success(results);
    } catch (e) {
      debugPrint('searchRides error: $e');
      final fallback = _locallyCreatedRides.values.where((r) => r.status == 'active').toList();
      return Success(fallback);
    }
  }
}
