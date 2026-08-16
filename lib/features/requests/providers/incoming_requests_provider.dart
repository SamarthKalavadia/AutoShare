import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/request_model.dart';
import '../../../data/models/ride_model.dart';
import '../../../data/models/user_model.dart';
import '../../../core/utils/result.dart';
import '../../../shared/providers.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

/// Bundles a request with its associated ride and passenger (requester) data.
class IncomingRequestData {
  final RideRequestModel request;
  final RideModel ride;
  final UserModel passenger;

  const IncomingRequestData({
    required this.request,
    required this.ride,
    required this.passenger,
  });
}

/// Provider to fetch and group incoming requests for the current user.
final incomingRequestsProvider =
    StreamProvider.autoDispose<List<IncomingRequestData>>((ref) async* {
      final currentUser = ref.watch(authControllerProvider).value;
      if (currentUser == null) {
        yield [];
        return;
      }

      final requestRepo = ref.watch(rideRequestRepositoryProvider);
      final userRepo = ref.watch(userRepositoryProvider);

      // Watch the raw Firestore stream of requests for this owner.
      final requestsStream = requestRepo.streamRequestsForOwner(
        currentUser.uid,
      );

      // Use a cache to avoid repeatedly fetching the same user/ride documents.
      final userCache = <String, UserModel>{};
      final rideCache = <String, RideModel>{};

      await for (final requests in requestsStream) {
        final List<IncomingRequestData> populatedRequests = [];

        for (final req in requests) {
          // 1. Fetch Passenger (Requester)
          UserModel? passenger = userCache[req.requesterUid];
          if (passenger == null) {
            final result = await userRepo.getUser(req.requesterUid);
            if (result is Success<UserModel>) {
              passenger = result.data;
              userCache[req.requesterUid] = passenger;
            } else {
              passenger = UserModel.empty().copyWith(
                uid: req.requesterUid,
                name: 'Unknown',
              );
            }
          }

          // 2. Fetch Ride
          RideModel? ride = rideCache[req.rideId];
          if (ride == null) {
            final result = await requestRepo.getRide(req.rideId);
            if (result is Success<RideModel>) {
              ride = result.data;
              rideCache[req.rideId] = ride;
            } else {
              ride = RideModel.empty().copyWith(
                id: req.rideId,
                boardingLocation: 'Requested Ride',
              );
            }
          }

          populatedRequests.add(
            IncomingRequestData(request: req, ride: ride, passenger: passenger),
          );
        }

        yield populatedRequests;
      }
    });

/// A state notifier to handle accepting/rejecting requests with loading states.
class RequestActionNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false; // isLoading
  }

  Future<void> accept(RideRequestModel request) async {
    state = true;
    final repo = ref.read(rideRequestRepositoryProvider);
    final result = await repo.acceptRequest(request);
    state = false;

    if (result is Failure) {
      throw result.exception ?? Exception(result.message);
    }
  }

  Future<void> reject(RideRequestModel request) async {
    state = true;
    final repo = ref.read(rideRequestRepositoryProvider);
    final result = await repo.rejectRequest(
      request.requestId,
      requesterUid: request.requesterUid,
    );
    state = false;

    if (result is Failure) {
      throw result.exception ?? Exception(result.message);
    }
  }
}

final requestActionProvider = NotifierProvider<RequestActionNotifier, bool>(
  RequestActionNotifier.new,
);
