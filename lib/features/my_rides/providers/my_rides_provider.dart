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

  const MyRideData({required this.ride, this.request, required this.role});

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
  final requestRepo = ref.read(rideRequestRepositoryProvider);

  // Silently audit rides in the background to handle client-side expiry
  unawaited(rideRepo.auditRides(user.uid));

  final driverStream = rideRepo.streamRidesByDriver(user.uid);
  final passengerStream = requestRepo.streamRequestsByPassenger(user.uid);

  final controller = StreamController<List<MyRideData>>();

  List<RideModel> latestDriverRides = [];
  List<RideRequestModel> latestPassengerRequests = [];

  Future<void> emitCombined() async {
    final List<MyRideData> allRides = [];

    // Add Driver Rides
    for (final ride in latestDriverRides) {
      allRides.add(MyRideData(ride: ride, role: 'driver'));
    }

    // Add Passenger Rides
    for (final req in latestPassengerRequests) {
      final result = await requestRepo.getRide(req.rideId);
      final rideModel = result is Success<RideModel>
          ? result.data
          : RideModel.empty().copyWith(
              id: req.rideId,
              boardingLocation: 'Requested Ride',
            );

      allRides.add(
        MyRideData(ride: rideModel, request: req, role: 'passenger'),
      );
    }

    allRides.sort(
      (a, b) => b.ride.departureTime.compareTo(a.ride.departureTime),
    );
    if (!controller.isClosed) {
      controller.add(allRides);
    }
  }

  final sub1 = driverStream.listen((driverRides) {
    latestDriverRides = driverRides;
    emitCombined();
  }, onError: (e) => emitCombined());

  final sub2 = passengerStream.listen((passengerRequests) {
    latestPassengerRequests = passengerRequests;
    emitCombined();
  }, onError: (e) => emitCombined());

  ref.onDispose(() {
    sub1.cancel();
    sub2.cancel();
    controller.close();
  });

  return controller.stream;
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
    final res = await ref
        .read(rideRequestRepositoryProvider)
        .cancelRequest(request);
    state = false;
    return res;
  }
}

final rideActionProvider = NotifierProvider<RideActionNotifier, bool>(
  RideActionNotifier.new,
);
