import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  }) : _firestoreService = firestoreService ?? FirestoreService(),
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
          reqDate =
              DateTime.tryParse(map['requestedAt'] as String) ?? DateTime.now();
        }
        final req = RideRequestModel.fromMap(
          map,
          map['requestId'] ?? map['id'] ?? '',
        ).copyWith(requestedAt: reqDate);
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
      final reqId = request.requestId.isNotEmpty
          ? request.requestId
          : docRef.id;
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

        unawaited(
          _analytics.logEvent(
            name: 'ride_joined',
            parameters: {
              'rideId': request.rideId,
              'passengerId': request.requesterUid,
            },
          ),
        );
      } on FirebaseException catch (e) {
        debugPrint(
          'Firestore request submit error (${e.code}); request saved locally.',
        );
      } catch (e) {
        debugPrint('Remote request submit error ($e); request saved locally.');
      }

      // 3. Resolve targetOwnerUid & notify ride owner
      String targetOwnerUid = request.ownerUid;
      if (targetOwnerUid.isEmpty) {
        try {
          final rideDoc = await _firestoreService.ridesCollection
              .doc(request.rideId)
              .get()
              .timeout(const Duration(seconds: 2));
          if (rideDoc.exists) {
            final rData = rideDoc.data() as Map<String, dynamic>?;
            targetOwnerUid = rData?['driverId'] as String? ??
                rData?['creatorId'] as String? ??
                rData?['ownerId'] as String? ??
                '';
          }
        } catch (_) {}
      }

      String passengerName = FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
      if (passengerName.isEmpty || passengerName.toLowerCase() == 'user') {
        try {
          final userDoc = await _firestoreService.usersCollection
              .doc(request.requesterUid)
              .get()
              .timeout(const Duration(seconds: 2));
          if (userDoc.exists) {
            final uData = userDoc.data() as Map<String, dynamic>?;
            passengerName = uData?['name'] as String? ??
                uData?['fullName'] as String? ??
                '';
          }
        } catch (_) {}
      }
      if (passengerName.isEmpty) passengerName = 'A passenger';

      if (targetOwnerUid.isNotEmpty) {
        try {
          await _notificationRepo.createNotification(
            NotificationModel(
              id: '',
              userId: targetOwnerUid,
              title: 'New Ride Request 🚗',
              body: '$passengerName requested ${request.requestedSeats} seat(s) on your ride.',
              type: 'new_request',
              isRead: false,
              createdAt: DateTime.now(),
              relatedId: withId.requestId,
            ),
          );
        } catch (e) {
          debugPrint('[RideRequestRepository] submitRequest notif error: $e');
        }
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
          (r.status == RideRequestStatus.pending ||
              r.status == RideRequestStatus.accepted)) {
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
      DocumentSnapshot doc;
      try {
        doc = await _firestoreService.ridesCollection
            .doc(rideId)
            .get()
            .timeout(const Duration(seconds: 8));
      } catch (e) {
        try {
          doc = await _firestoreService.ridesCollection
              .doc(rideId)
              .get(const GetOptions(source: Source.cache));
        } catch (_) {
          rethrow;
        }
      }

      if (!doc.exists) {
        try {
          final querySnap = await _firestoreService.ridesCollection
              .where('id', isEqualTo: rideId)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 8));
          if (querySnap.docs.isNotEmpty) {
            final fDoc = querySnap.docs.first;
            final data = fDoc.data() as Map<String, dynamic>;
            return Success(RideModel.fromMap(data, fDoc.id));
          }
        } catch (_) {}

        return const Failure(
          'Ride not found.',
          FirestoreException('Ride document does not exist.'),
        );
      }
      final data = doc.data() as Map<String, dynamic>;
      return Success(RideModel.fromMap(data, doc.id));
    } on FirebaseException catch (e) {
      return Failure(
        e.message ?? 'Failed to fetch ride.',
        FirestoreException(e.code),
      );
    } catch (e) {
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  /// Streams all requests for a specific ride.
  Stream<List<RideRequestModel>> streamRequestsByRide(String rideId) {
    return _firestoreService.rideRequestsCollection
        .where('rideId', isEqualTo: rideId)
        .snapshots()
        .map((snapshot) {
          final Map<String, RideRequestModel> merged = Map.from(
            _locallySubmittedRequests,
          );

          for (final doc in snapshot.docs) {
            final req = RideRequestModel.fromDocument(doc);
            merged[req.requestId] = req;
          }

          final list = merged.values
              .where((r) => r.rideId == rideId)
              .toList();
          list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
          return list;
        })
        .handleError((error) {
          debugPrint(
            'streamRequestsByRide error ($error); falling back to local requests.',
          );
          final list = _locallySubmittedRequests.values
              .where((r) => r.rideId == rideId)
              .toList();
          list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
          return list;
        });
  }

  /// Streams all requests for rides owned by [ownerUid].
  Stream<List<RideRequestModel>> streamRequestsForOwner(String ownerUid) {
    return _firestoreService.rideRequestsCollection
        .where('ownerUid', isEqualTo: ownerUid)
        .snapshots()
        .map((snapshot) {
          final Map<String, RideRequestModel> merged = Map.from(
            _locallySubmittedRequests,
          );

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
          debugPrint(
            'streamRequestsForOwner error ($error); falling back to local requests.',
          );
          final list = _locallySubmittedRequests.values
              .where((r) => r.ownerUid == ownerUid || ownerUid.isEmpty)
              .toList();
          list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
          return list;
        });
  }

  Future<String> _resolveUserName(String uid) async {
    if (uid.isEmpty) return 'The passenger';
    try {
      final userDoc = await _firestoreService.usersCollection
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 2));
      if (userDoc.exists) {
        final uData = userDoc.data() as Map<String, dynamic>?;
        final name = (uData?['name'] as String? ??
                uData?['fullName'] as String? ??
                '')
            .trim();
        if (name.isNotEmpty &&
            name.toLowerCase() != 'user' &&
            name.toLowerCase() != 'driver') {
          return name;
        }
      }
    } catch (_) {}
    return 'The passenger';
  }

  /// Accepts a request (by the ride owner).
  Future<Result<void>> acceptRequest(RideRequestModel request) async {
    try {
      final reqRef =
          _firestoreService.rideRequestsCollection.doc(request.requestId);
      final rideRef = _firestoreService.ridesCollection.doc(request.rideId);

      int updatedRemainingSeats = 0;
      int updatedAcceptedCount = 0;
      double updatedFarePerPerson = 0.0;
      String rideOwnerUid = request.ownerUid;

      // 1. Transactional update for concurrency safety
      try {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final reqSnap = await transaction.get(reqRef);
          if (!reqSnap.exists) {
            throw Exception('Request does not exist.');
          }
          final reqData = reqSnap.data() as Map<String, dynamic>? ?? {};
          final currentReqStatus = reqData['status'] as String? ?? '';
          if (currentReqStatus == RideRequestStatus.accepted.name) {
            return; // Idempotent
          }
          if (currentReqStatus != RideRequestStatus.pending.name) {
            throw Exception('Request is no longer pending.');
          }

          final rideSnap = await transaction.get(rideRef);
          if (!rideSnap.exists) {
            throw Exception('Ride does not exist.');
          }
          final rideData = rideSnap.data() as Map<String, dynamic>? ?? {};
          final totalSeats = (rideData['totalSeats'] ??
                  rideData['availableSeats']) as int? ??
              1;
          final currentAvailable =
              (rideData['availableSeats'] as int?) ?? totalSeats;
          final currentAccepted =
              (rideData['acceptedPassengerCount'] as int?) ??
                  (totalSeats - currentAvailable).clamp(0, totalSeats);
          final requestedSeats = request.requestedSeats;

          if (currentAvailable < requestedSeats || currentAvailable <= 0) {
            throw Exception('This ride is already full.');
          }

          rideOwnerUid =
              (rideData['driverId'] as String? ?? request.ownerUid).trim();
          updatedAcceptedCount = currentAccepted + requestedSeats;
          updatedRemainingSeats =
              (currentAvailable - requestedSeats).clamp(0, totalSeats);

          final totalFare =
              ((rideData['totalFare'] ?? rideData['farePerSeat']) as num?)
                      ?.toDouble() ??
                  0.0;
          final totalPeople = 1 + updatedAcceptedCount;
          updatedFarePerPerson =
              totalPeople > 0 ? (totalFare / totalPeople) : totalFare;

          transaction.update(rideRef, {
            'availableSeats': updatedRemainingSeats,
            'acceptedPassengerCount': updatedAcceptedCount,
            'totalSeats': totalSeats,
            'currentFarePerPerson': updatedFarePerPerson,
            'farePerSeat': updatedFarePerPerson,
          });

          transaction.update(reqRef, {
            'status': RideRequestStatus.accepted.name,
          });
        });
      } on FirebaseException catch (fe) {
        debugPrint(
            '[RideRequestRepository] acceptRequest transaction error: $fe');
        if (fe.message?.contains('already full') == true) {
          return const Failure('This ride is already full.', null);
        }
        return Failure(fe.message ?? 'Failed to accept request.', fe);
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('already full')) {
          return const Failure('This ride is already full.', null);
        }
        return Failure('Failed to accept request: $e', Exception(msg));
      }

      // 2. Update local state
      final updatedReq = request.copyWith(status: RideRequestStatus.accepted);
      _locallySubmittedRequests[request.requestId] = updatedReq;
      unawaited(_saveLocalRequests());

      // 3. Dispatch real-time notifications to CURRENT participants (creator, newly accepted, existing accepted)
      unawaited(() async {
        try {
          final passengerName = await _resolveUserName(request.requesterUid);
          final seatText = updatedRemainingSeats == 0
              ? 'No seats remaining.'
              : (updatedRemainingSeats == 1
                  ? '1 seat remaining.'
                  : '$updatedRemainingSeats seats remaining.');
          final notifTitle = 'Ride Updated';
          final notifBody =
              '$passengerName joined the ride. $seatText Current fare: ₹${updatedFarePerPerson.round()}/person.';

          final Set<String> recipientUids = {
            if (rideOwnerUid.isNotEmpty) rideOwnerUid,
            if (request.requesterUid.isNotEmpty) request.requesterUid,
          };

          try {
            final otherAcceptedSnaps = await _firestoreService
                .rideRequestsCollection
                .where('rideId', isEqualTo: request.rideId)
                .where('status', isEqualTo: 'accepted')
                .get()
                .timeout(const Duration(seconds: 3));
            for (final doc in otherAcceptedSnaps.docs) {
              final uid =
                  (doc.data() as Map<String, dynamic>?)?['requesterUid']
                      as String?;
              if (uid != null && uid.isNotEmpty) {
                recipientUids.add(uid);
              }
            }
          } catch (_) {}

          final dataPayload = {
            'type': 'ride_updated',
            'rideId': request.rideId,
            'remainingSeats': '$updatedRemainingSeats',
            'acceptedPassengerCount': '$updatedAcceptedCount',
            'currentFarePerPerson': '${updatedFarePerPerson.round()}',
            'triggerUserId': request.requesterUid,
            'event': 'joined',
          };

          await _notificationRepo.queuePushNotification(
            recipientUids: recipientUids.toList(),
            title: notifTitle,
            body: notifBody,
            type: 'ride_updated',
            relatedId: request.rideId,
            dataPayload: dataPayload,
          );
        } catch (e) {
          debugPrint(
              '[RideRequestRepository] acceptRequest notification note: $e');
        }
      }());

      return const Success(null);
    } catch (e) {
      debugPrint('acceptRequest error: $e');
      return Failure('Failed to accept request.', Exception(e.toString()));
    }
  }

  /// Rejects a ride request (by the ride owner).
  Future<Result<void>> rejectRequest(
    String requestId, {
    required String requesterUid,
  }) async {
    try {
      if (_locallySubmittedRequests.containsKey(requestId)) {
        _locallySubmittedRequests[requestId] =
            _locallySubmittedRequests[requestId]!.copyWith(
          status: RideRequestStatus.rejected,
        );
        unawaited(_saveLocalRequests());
      }

      try {
        await _firestoreService.rideRequestsCollection
            .doc(requestId)
            .update({'status': RideRequestStatus.rejected.name})
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('Remote rejectRequest error ($e); rejected locally.');
      }

      unawaited(
        _notificationRepo.createNotification(
          NotificationModel(
            id: '',
            userId: requesterUid,
            title: 'Ride Request Declined',
            body:
                'Your ride request was not accepted. Try looking for another ride.',
            type: 'rejected',
            isRead: false,
            createdAt: DateTime.now(),
            relatedId: requestId,
          ),
        ),
      );

      return const Success(null);
    } catch (e) {
      debugPrint('rejectRequest error: $e');
      return const Success(null);
    }
  }

  /// Cancels a ride request (by the passenger).
  Future<Result<void>> cancelRequest(RideRequestModel request) async {
    try {
      final reqRef =
          _firestoreService.rideRequestsCollection.doc(request.requestId);
      final rideRef = _firestoreService.ridesCollection.doc(request.rideId);

      bool wasAccepted = request.status == RideRequestStatus.accepted;
      bool wasAlreadyCancelled = false;
      int updatedRemainingSeats = 0;
      int updatedAcceptedCount = 0;
      double updatedFarePerPerson = 0.0;
      String rideOwnerUid = request.ownerUid;

      // 1. Transactional update to prevent double cancellations & handle seat restoration safely
      try {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          // READ 1: Read the request document first
          final reqSnap = await transaction.get(reqRef);
          if (!reqSnap.exists) {
            return;
          }
          final reqData = reqSnap.data() as Map<String, dynamic>? ?? {};
          final currentReqStatus = reqData['status'] as String? ?? '';
          if (currentReqStatus == RideRequestStatus.cancelled.name) {
            wasAlreadyCancelled = true;
            return;
          }
          wasAccepted = currentReqStatus == RideRequestStatus.accepted.name;

          // READ 2: If was accepted, read the ride document BEFORE performing ANY writes
          DocumentSnapshot<Map<String, dynamic>>? rideSnap;
          if (wasAccepted) {
            rideSnap = await transaction.get(rideRef)
                as DocumentSnapshot<Map<String, dynamic>>?;
          }

          // ALL READS ARE COMPLETE. NOW PERFORM ALL WRITES:

          // WRITE 1: Update request status
          transaction.update(reqRef, {
            'status': RideRequestStatus.cancelled.name,
          });

          // WRITE 2: Restore seats and update fare if previously accepted
          if (wasAccepted && rideSnap != null && rideSnap.exists) {
            final rideData = rideSnap.data() ?? {};
            final totalSeats = (rideData['totalSeats'] ??
                    rideData['availableSeats']) as int? ??
                2;
            final currentAvailable =
                (rideData['availableSeats'] as int?) ?? 0;
            final currentAccepted =
                (rideData['acceptedPassengerCount'] as int?) ??
                    (totalSeats - currentAvailable).clamp(0, totalSeats);
            final requestedSeats = request.requestedSeats;

            rideOwnerUid =
                (rideData['driverId'] as String? ?? request.ownerUid).trim();
            updatedAcceptedCount =
                (currentAccepted - requestedSeats).clamp(0, totalSeats);
            updatedRemainingSeats =
                (currentAvailable + requestedSeats).clamp(0, totalSeats);

            final totalFare =
                ((rideData['totalFare'] ?? rideData['farePerSeat']) as num?)
                        ?.toDouble() ??
                    0.0;
            final totalPeople = 1 + updatedAcceptedCount;
            updatedFarePerPerson =
                totalPeople > 0 ? (totalFare / totalPeople) : totalFare;

            transaction.update(rideRef, {
              'availableSeats': updatedRemainingSeats,
              'acceptedPassengerCount': updatedAcceptedCount,
              'totalSeats': totalSeats,
              'currentFarePerPerson': updatedFarePerPerson,
              'farePerSeat': updatedFarePerPerson,
            });
          }
        });
      } on FirebaseException catch (fe) {
        debugPrint(
            '[RideRequestRepository] cancelRequest transaction note: $fe');
        await reqRef
            .update({'status': RideRequestStatus.cancelled.name})
            .catchError((_) {});
      } catch (e) {
        debugPrint(
            '[RideRequestRepository] cancelRequest transaction error: $e');
        await reqRef
            .update({'status': RideRequestStatus.cancelled.name})
            .catchError((_) {});
      }

      if (wasAlreadyCancelled) {
        return const Success(null);
      }

      // 2. Update local storage
      final updatedReq = request.copyWith(status: RideRequestStatus.cancelled);
      _locallySubmittedRequests[request.requestId] = updatedReq;
      unawaited(_saveLocalRequests());

      // 3. Dispatch notifications
      unawaited(() async {
        try {
          final passengerName = await _resolveUserName(request.requesterUid);

          if (wasAccepted) {
            final seatWord =
                updatedRemainingSeats == 1 ? 'seat' : 'seats';
            final notifTitle = 'Ride Updated';
            final notifBody =
                '$passengerName left the ride. $updatedRemainingSeats $seatWord available. Current fare: ₹${updatedFarePerPerson.round()}/person.';

            final Set<String> remainingRecipients = {
              if (rideOwnerUid.isNotEmpty &&
                  rideOwnerUid != request.requesterUid)
                rideOwnerUid,
            };

            try {
              final otherAcceptedSnaps = await _firestoreService
                  .rideRequestsCollection
                  .where('rideId', isEqualTo: request.rideId)
                  .where('status', isEqualTo: 'accepted')
                  .get()
                  .timeout(const Duration(seconds: 3));
              for (final doc in otherAcceptedSnaps.docs) {
                if (doc.id == request.requestId) continue;
                final uid =
                    (doc.data() as Map<String, dynamic>?)?['requesterUid']
                        as String?;
                if (uid != null &&
                    uid.isNotEmpty &&
                    uid != request.requesterUid) {
                  remainingRecipients.add(uid);
                }
              }
            } catch (_) {}

            if (remainingRecipients.isNotEmpty) {
              final dataPayload = {
                'type': 'ride_updated',
                'rideId': request.rideId,
                'remainingSeats': '$updatedRemainingSeats',
                'acceptedPassengerCount': '$updatedAcceptedCount',
                'currentFarePerPerson': '${updatedFarePerPerson.round()}',
                'triggerUserId': request.requesterUid,
                'event': 'cancelled',
              };

              await _notificationRepo.queuePushNotification(
                recipientUids: remainingRecipients.toList(),
                title: notifTitle,
                body: notifBody,
                type: 'ride_updated',
                relatedId: request.rideId,
                dataPayload: dataPayload,
              );
            }
          } else {
            if (rideOwnerUid.isNotEmpty) {
              await _notificationRepo.createNotification(
                NotificationModel(
                  id: '',
                  userId: rideOwnerUid,
                  title: 'Ride Request Cancelled ❌',
                  body: '$passengerName cancelled their ride request.',
                  type: 'cancelled',
                  isRead: false,
                  createdAt: DateTime.now(),
                  relatedId: request.requestId,
                ),
              );
            }
          }
        } catch (e) {
          debugPrint(
              '[RideRequestRepository] cancelRequest notif dispatch note: $e');
        }
      }());

      return const Success(null);
    } catch (e) {
      return Failure('Failed to cancel request.', Exception(e.toString()));
    }
  }

  /// Streams all requests made by [requesterUid].
  Stream<List<RideRequestModel>> streamRequestsByPassenger(
    String requesterUid,
  ) {
    return _firestoreService.rideRequestsCollection
        .where('requesterUid', isEqualTo: requesterUid)
        .snapshots()
        .map((snapshot) {
          final Map<String, RideRequestModel> merged = Map.from(
            _locallySubmittedRequests,
          );

          for (final doc in snapshot.docs) {
            final req = RideRequestModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
            merged[req.requestId] = req;
          }

          final list = merged.values
              .where(
                (r) => r.requesterUid == requesterUid || requesterUid.isEmpty,
              )
              .toList();
          list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
          return list;
        })
        .handleError((error) {
          debugPrint(
            'streamRequestsByPassenger error ($error); returning local requests.',
          );
          final list = _locallySubmittedRequests.values
              .where(
                (r) => r.requesterUid == requesterUid || requesterUid.isEmpty,
              )
              .toList();
          list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
          return list;
        });
  }

  Future<List<RideRequestModel>> getRequestsByPassenger(
    String requesterUid,
  ) async {
    final Map<String, RideRequestModel> merged = Map.from(
      _locallySubmittedRequests,
    );
    try {
      final snapshot = await _firestoreService.rideRequestsCollection
          .where('requesterUid', isEqualTo: requesterUid)
          .get()
          .timeout(const Duration(seconds: 3));

      for (final doc in snapshot.docs) {
        final req = RideRequestModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
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
