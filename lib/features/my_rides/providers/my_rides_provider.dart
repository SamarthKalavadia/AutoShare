import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/result.dart';
import '../../../data/models/request_model.dart';
import '../../../data/models/ride_model.dart';
import '../../../shared/providers.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

class MyRideData {
  final RideModel ride;
  final RideRequestModel? request;
  final String role; // 'driver' or 'passenger'

  const MyRideData({
    required this.ride,
    this.request,
    required this.role,
  });

  /// Computed status based on role and underlying entities.
  String get displayStatus {
    if (role == 'driver') {
      return ride.status;
    } else {
      if (request != null) {
        if (request!.status == RideRequestStatus.pending) return 'pending';
        if (request!.status == RideRequestStatus.rejected) return 'rejected';
        if (request!.status == RideRequestStatus.cancelled) return 'cancelled';
        if (request!.status == RideRequestStatus.accepted) {
          return ride.status == 'active' ? 'joined' : ride.status;
        }
      }
      return 'unknown';
    }
  }

  bool get isPast {
    return ride.departureTime.isBefore(DateTime.now());
  }
}

final myRidesProvider = StreamProvider.autoDispose<List<MyRideData>>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) {
    return Stream.value([]);
  }

  final rideRepo = ref.read(rideRepositoryProvider);

  // Silently audit rides in the background to handle client-side expiry
  unawaited(rideRepo.auditRides(user.uid));

  return ref.watch(rideRepositoryProvider).streamRidesByDriver(user.uid).asyncMap((driverRides) async {
    final requestRepo = ref.read(rideRequestRepositoryProvider);
    final passengerRequests = await requestRepo.getRequestsByPassenger(user.uid);

    final List<MyRideData> allRides = [];

    // Add Driver Rides
    for (final ride in driverRides) {
      allRides.add(MyRideData(ride: ride, role: 'driver'));
    }

    // Add Passenger Rides
    for (final req in passengerRequests) {
      final result = await requestRepo.getRide(req.rideId);
      if (result is Success<RideModel>) {
        allRides.add(MyRideData(
          ride: result.data,
          request: req,
          role: 'passenger',
        ));
      }
    }

    allRides.sort((a, b) => b.ride.departureTime.compareTo(a.ride.departureTime));
    return allRides;
  });
});

class RideActionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<Result<void>> cancelMyRide(String rideId) async {
    state = true;
    final res = await ref.read(rideRepositoryProvider).cancelRide(rideId);
    state = false;
    return res;
  }

  Future<Result<void>> deleteMyRide(String rideId) async {
    state = true;
    final res = await ref.read(rideRepositoryProvider).deleteRide(rideId);
    state = false;
    return res;
  }

  Future<Result<void>> cancelMyRequest(RideRequestModel request) async {
    state = true;
    final res = await ref.read(rideRequestRepositoryProvider).cancelRequest(request);
    state = false;
    return res;
  }
}

final rideActionProvider = NotifierProvider<RideActionNotifier, bool>(RideActionNotifier.new);

