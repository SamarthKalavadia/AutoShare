import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/request_model.dart';
import '../../../data/models/ride_model.dart';
import '../../../data/repositories/ride_request_repository.dart';
import '../../../core/utils/result.dart';
import '../../../shared/providers.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

/// UI state for the ride request flow on the Ride Details page.
class RideRequestState {
  final int requestedSeats;
  final bool isLoading;
  final bool isSuccess;
  final String? error;

  const RideRequestState({
    this.requestedSeats = 1,
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
  });

  RideRequestState copyWith({
    int? requestedSeats,
    bool? isLoading,
    bool? isSuccess,
    String? error,
    bool clearError = false,
  }) {
    return RideRequestState(
      requestedSeats: requestedSeats ?? this.requestedSeats,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Simple Notifier for the Ride Request flow.
class RideRequestNotifier extends Notifier<RideRequestState> {
  @override
  RideRequestState build() {
    return const RideRequestState();
  }

  RideRequestRepository get _repo => ref.read(rideRequestRepositoryProvider);

  void incrementSeats(int maxSeats) {
    final current = state.requestedSeats;
    if (current < maxSeats && current < 4) {
      state = state.copyWith(requestedSeats: current + 1, clearError: true);
    }
  }

  void decrementSeats() {
    if (state.requestedSeats > 1) {
      state = state.copyWith(
        requestedSeats: state.requestedSeats - 1,
        clearError: true,
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> submitRequest(RideModel ride) async {
    final currentUser = ref.read(authControllerProvider).value;
    if (currentUser == null) {
      state = state.copyWith(error: 'You must be signed in to request a ride.');
      return;
    }

    final uid = currentUser.uid;

    // ── Validation 1: Cannot request own ride ──────────────────────────
    if (ride.driverId == uid) {
      state = state.copyWith(error: 'You cannot request your own ride.');
      return;
    }

    // ── Validation 2: Ride must be active ─────────────────────────────
    if (ride.status != 'active') {
      state = state.copyWith(
        error: ride.status == 'completed'
            ? 'This ride has already been completed.'
            : 'This ride has been cancelled.',
      );
      return;
    }

    // ── Validation 3: Cannot request expired ride ──────────────────────
    if (ride.departureTime.isBefore(DateTime.now())) {
      state = state.copyWith(error: 'This ride has already departed.');
      return;
    }

    // ── Validation 4: Seats availability ──────────────────────────────
    if (state.requestedSeats > ride.availableSeats) {
      state = state.copyWith(
        error: 'Only ${ride.availableSeats} seat(s) available.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    // ── Validation 5: Duplicate request (live Firestore check) ─────────
    final existingResult = await _repo.getExistingRequest(
      rideId: ride.id,
      requesterUid: uid,
    );

    if (existingResult is Failure) {
      state = state.copyWith(
        isLoading: false,
        error: (existingResult as Failure).message,
      );
      return;
    }

    final existing = (existingResult as Success<RideRequestModel?>).data;
    if (existing != null) {
      final statusLabel = existing.status == RideRequestStatus.pending
          ? 'pending'
          : 'already accepted';
      state = state.copyWith(
        isLoading: false,
        error: 'You already have a $statusLabel request for this ride.',
      );
      return;
    }

    // ── Fetch fresh ride snapshot to re-validate seats server-side ─────
    final freshRideResult = await _repo.getRide(ride.id);
    if (freshRideResult is Failure) {
      state = state.copyWith(
        isLoading: false,
        error: (freshRideResult as Failure).message,
      );
      return;
    }

    final freshRide = (freshRideResult as Success<RideModel>).data;
    if (state.requestedSeats > freshRide.availableSeats) {
      state = state.copyWith(
        isLoading: false,
        error:
            'Seats were just filled. Only ${freshRide.availableSeats} seat(s) remain.',
      );
      return;
    }

    // ── Submit ─────────────────────────────────────────────────────────
    final request = RideRequestModel.create(
      requestId: '',
      rideId: ride.id,
      ownerUid: ride.driverId,
      requesterUid: uid,
      requestedSeats: state.requestedSeats,
    );

    final submitResult = await _repo.submitRequest(request);

    if (submitResult is Failure) {
      state = state.copyWith(
        isLoading: false,
        error: (submitResult as Failure).message,
      );
      return;
    }

    state = state.copyWith(isLoading: false, isSuccess: true);
  }
}

final rideRequestProvider =
    NotifierProvider<RideRequestNotifier, RideRequestState>(
      RideRequestNotifier.new,
    );

final currentRideRequestProvider = FutureProvider.autoDispose
    .family<RideRequestModel?, String>((ref, rideId) async {
      final currentUser = ref.watch(authControllerProvider).value;
      if (currentUser == null) return null;
      final repo = ref.watch(rideRequestRepositoryProvider);
      final result = await repo.getExistingRequest(
        rideId: rideId,
        requesterUid: currentUser.uid,
      );
      if (result is Success<RideRequestModel?>) {
        return result.data;
      }
      return null;
    });
