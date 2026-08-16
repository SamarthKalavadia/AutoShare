import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/firestore_service.dart';
import '../../core/utils/result.dart';
import '../models/notification_model.dart';
import '../models/request_model.dart';
import '../models/ride_model.dart';
import '../repositories/notification_repository.dart';

/// Repository responsible for all Ride Request database operations with local persistence fallback.
class RideRequestRepository {
  final FirestoreService _firestoreService;
  final NotificationRepository _notificationRepo;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static const String _kLocalRequestsKey = 'local_ride_requests_json';
  final Map<String, RideRequestModel> _locallySubmittedRequests = {};

  RideRequestRepository({
    FirestoreService? firestoreService,
    NotificationRepository? notificationRepo,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _notificationRepo = notificationRepo ?? NotificationRepository() {
    _loadLocalRequests();
  }

  Future<void> _loadLocalRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getStringList(_kLocalRequestsKey) ?? [];
      for (final str in savedJson) {
        final map = json.decode(str) as Map<String, dynamic>;
        DateTime reqDate = DateTime.now();
        if (map['requestedAt'] is String) {
          reqDate = DateTime.tryParse(map['requestedAt'] as String) ?? DateTime.now();
        }
        final req = RideRequestModel.fromMap(map, map['requestId'] ?? map['id'] ?? '')
            .copyWith(requestedAt: reqDate);
        _locallySubmittedRequests[req.requestId] = req;
      }
    } catch (e) {
      debugPrint('Error loading local ride requests: $e');
    }
  }

  Future<void> _saveLocalRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _locallySubmittedRequests.values.map((r) {
        final map = r.toMap();
        map['requestedAt'] = r.requestedAt.toIso8601String();
        return json.encode(map);
      }).toList();
      await prefs.setStringList(_kLocalRequestsKey, list);
    } catch (e) {
      debugPrint('Error saving local ride requests: $e');
    }
  }

  /// Submits a new ride request to Firestore & local storage.
  Future<Result<String>> submitRequest(RideRequestModel request) async {
    try {
      final docRef = _firestoreService.rideRequestsCollection.doc();
      final reqId = request.requestId.isNotEmpty ? request.requestId : docRef.id;
      final withId = request.copyWith(requestId: reqId);

      // 1. Instantly persist locally so it ALWAYS shows in Requested tab & prevents duplicates
      _locallySubmittedRequests[withId.requestId] = withId;
      unawaited(_saveLocalRequests());

      // 2. Try remote Firestore sync
      try {
        await _firestoreService.rideRequestsCollection
            .doc(withId.requestId)
            .set(withId.toMap())
            .timeout(const Duration(seconds: 4));

        unawaited(_analytics.logEvent(
          name: 'ride_joined',
          parameters: {
            'rideId': request.rideId,
            'passengerId': request.requesterUid
          },
        ));

        unawaited(_notificationRepo.createNotification(NotificationModel(
          id: '',
          userId: request.ownerUid,
          title: 'New Ride Request',
          body: 'Someone has requested to join your ride.',
          type: 'new_request',
          isRead: false,
          createdAt: DateTime.now(),
          relatedId: withId.requestId,
        )));
      } on FirebaseException catch (e) {
        debugPrint('Firestore request submit error (${e.code}); request saved locally.');
      } catch (e) {
        debugPrint('Remote request submit error ($e); request saved locally.');
      }

      return Success(withId.requestId);
    } catch (e) {
      debugPrint('submitRequest unexpected error: $e');
      return Failure('Could not submit request.', Exception(e.toString()));
    }
  }

  /// Checks whether [requesterUid] has already sent a non-cancelled request
  /// for [rideId]. Returns the existing model if found, null otherwise.
  Future<Result<RideRequestModel?>> getExistingRequest({
    required String rideId,
    required String requesterUid,
  }) async {
    // 1. Check local memory cache first
    for (final r in _locallySubmittedRequests.values) {
      if (r.rideId == rideId &&
          r.requesterUid == requesterUid &&
          (r.status == RideRequestStatus.pending || r.status == RideRequestStatus.accepted)) {
        return Success(r);
      }
    }

    // 2. Check Firestore
    try {
      final snapshot = await _firestoreService.rideRequestsCollection
          .where('rideId', isEqualTo: rideId)
          .where('requesterUid', isEqualTo: requesterUid)
          .where('status', whereIn: ['pending', 'accepted'])
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 3));

      if (snapshot.docs.isNotEmpty) {
        final found = RideRequestModel.fromDocument(snapshot.docs.first);
        _locallySubmittedRequests[found.requestId] = found;
        unawaited(_saveLocalRequests());
        return Success(found);
      }
      return const Success(null);
    } catch (e) {
      debugPrint('getExistingRequest error: $e');
      return const Success(null);
    }
  }

  /// Fetches a fresh copy of a [RideModel] for validation before submission.
  Future<Result<RideModel>> getRide(String rideId) async {
    try {
      final doc = await _firestoreService.ridesCollection
          .doc(rideId)
          .get()
          .timeout(const Duration(seconds: 3));

      if (!doc.exists) {
        return const Failure('Ride not found.', FirestoreException('Ride document does not exist.'));
      }
      final data = doc.data() as Map<String, dynamic>;
      return Success(RideModel.fromMap(data, doc.id));
    } on FirebaseException catch (e) {
      return Failure(e.message ?? 'Failed to fetch ride.', FirestoreException(e.code));
    } catch (e) {
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  /// Streams all requests for rides owned by [ownerUid].
  Stream<List<RideRequestModel>> streamRequestsForOwner(String ownerUid) {
    return _firestoreService.rideRequestsCollection
        .where('ownerUid', isEqualTo: ownerUid)
        .snapshots()
        .map((snapshot) {
          final Map<String, RideRequestModel> merged = Map.from(_locallySubmittedRequests);

          for (final doc in snapshot.docs) {
            final req = RideRequestModel.fromDocument(doc);
            merged[req.requestId] = req;
          }

          final list = merged.values
              .where((r) => r.ownerUid == ownerUid || ownerUid.isEmpty)
              .toList();
          list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
          return list;
        })
        .handleError((error) {
          debugPrint('streamRequestsForOwner error ($error); falling back to local requests.');
          final list = _locallySubmittedRequests.values
              .where((r) => r.ownerUid == ownerUid || ownerUid.isEmpty)
              .toList();
          list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
          return list;
        });
  }

  /// Accepts a request (by the ride owner).
  Future<Result<void>> acceptRequest(RideRequestModel request) async {
    try {
      final updatedReq = request.copyWith(status: RideRequestStatus.accepted);
      _locallySubmittedRequests[request.requestId] = updatedReq;
      unawaited(_saveLocalRequests());

      // Attempt remote Firestore update
      try {
        final reqRef = _firestoreService.rideRequestsCollection.doc(request.requestId);
        await reqRef.update({'status': RideRequestStatus.accepted.name}).timeout(const Duration(seconds: 3));

        // Decrement ride available seats remotely if possible
        final rideRef = _firestoreService.ridesCollection.doc(request.rideId);
        final rideDoc = await rideRef.get().timeout(const Duration(seconds: 3));
        if (rideDoc.exists) {
          final currentSeats = (rideDoc.data() as Map<String, dynamic>?)?['availableSeats'] as int? ?? 1;
          if (currentSeats > 0) {
            await rideRef.update({'availableSeats': currentSeats - request.requestedSeats});
          }
        }
      } on FirebaseException catch (e) {
        debugPrint('Firestore acceptRequest warning (${e.code}); accepted locally.');
      } catch (e) {
        debugPrint('Remote acceptRequest warning ($e); accepted locally.');
      }

      // Send acceptance notification asynchronously
      unawaited(_notificationRepo.createNotification(NotificationModel(
        id: '',
        userId: request.requesterUid,
        title: 'Ride Request Accepted! 🎉',
        body: 'Your ride request has been accepted. Contact details are now available.',
        type: 'accepted',
        isRead: false,
        createdAt: DateTime.now(),
        relatedId: request.requestId,
      )));

      return const Success(null);
    } catch (e) {
      debugPrint('acceptRequest error: $e');
      return const Success(null);
    }
  }

  /// Rejects a ride request (by the ride owner).
  Future<Result<void>> rejectRequest(String requestId, {required String requesterUid}) async {
    try {
      if (_locallySubmittedRequests.containsKey(requestId)) {
        _locallySubmittedRequests[requestId] =
            _locallySubmittedRequests[requestId]!.copyWith(status: RideRequestStatus.rejected);
        unawaited(_saveLocalRequests());
      }

      try {
        await _firestoreService.rideRequestsCollection.doc(requestId).update({
          'status': RideRequestStatus.rejected.name,
        }).timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('Remote rejectRequest error ($e); rejected locally.');
      }

      unawaited(_notificationRepo.createNotification(NotificationModel(
        id: '',
        userId: requesterUid,
        title: 'Ride Request Declined',
        body: 'Your ride request was not accepted. Try looking for another ride.',
        type: 'rejected',
        isRead: false,
        createdAt: DateTime.now(),
        relatedId: requestId,
      )));

      return const Success(null);
    } catch (e) {
      debugPrint('rejectRequest error: $e');
      return const Success(null);
    }
  }

  /// Cancels a ride request (by the passenger).
  Future<Result<void>> cancelRequest(RideRequestModel request) async {
    try {
      final updatedReq = request.copyWith(status: RideRequestStatus.cancelled);
      _locallySubmittedRequests[request.requestId] = updatedReq;
      unawaited(_saveLocalRequests());

      try {
        await _firestoreService.rideRequestsCollection.doc(request.requestId).update({
          'status': RideRequestStatus.cancelled.name,
        }).timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('Remote cancelRequest error ($e); cancelled locally.');
      }

      return const Success(null);
    } catch (e) {
      return Failure('Failed to cancel request.', Exception(e.toString()));
    }
  }

  /// Streams all requests made by [requesterUid].
  Stream<List<RideRequestModel>> streamRequestsByPassenger(String requesterUid) {
    return _firestoreService.rideRequestsCollection
        .where('requesterUid', isEqualTo: requesterUid)
        .snapshots()
        .map((snapshot) {
          final Map<String, RideRequestModel> merged = Map.from(_locallySubmittedRequests);

          for (final doc in snapshot.docs) {
            final req = RideRequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            merged[req.requestId] = req;
          }

          final list = merged.values
              .where((r) => r.requesterUid == requesterUid || requesterUid.isEmpty)
              .toList();
          list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
          return list;
        })
        .handleError((error) {
          debugPrint('streamRequestsByPassenger error ($error); returning local requests.');
          final list = _locallySubmittedRequests.values
              .where((r) => r.requesterUid == requesterUid || requesterUid.isEmpty)
              .toList();
          list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
          return list;
        });
  }

  Future<List<RideRequestModel>> getRequestsByPassenger(String requesterUid) async {
    final Map<String, RideRequestModel> merged = Map.from(_locallySubmittedRequests);
    try {
      final snapshot = await _firestoreService.rideRequestsCollection
          .where('requesterUid', isEqualTo: requesterUid)
          .get()
          .timeout(const Duration(seconds: 3));

      for (final doc in snapshot.docs) {
        final req = RideRequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        merged[req.requestId] = req;
      }
    } catch (e) {
      debugPrint('getRequestsByPassenger remote error: $e');
    }

    final list = merged.values
        .where((r) => r.requesterUid == requesterUid || requesterUid.isEmpty)
        .toList();
    list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return list;
  }
}
