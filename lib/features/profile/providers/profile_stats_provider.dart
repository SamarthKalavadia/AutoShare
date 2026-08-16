import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../my_rides/providers/my_rides_provider.dart';

class ProfileStats {
  final int createdRides;
  final int joinedRides;
  final int completedRides;
  final int cancelledRides;

  const ProfileStats({
    this.createdRides = 0,
    this.joinedRides = 0,
    this.completedRides = 0,
    this.cancelledRides = 0,
  });
}

final profileStatsProvider = FutureProvider.autoDispose<ProfileStats>((
  ref,
) async {
  final allRides = await ref.watch(myRidesProvider.future);

  int createdRides = 0;
  int joinedRides = 0;
  int completedRides = 0;
  int cancelledRides = 0;

  for (final rideData in allRides) {
    if (rideData.role == 'driver') {
      createdRides++;
    } else if (rideData.role == 'passenger') {
      // Joined rides are passenger requests that are accepted/joined/completed/active
      if (rideData.request != null &&
          ['joined', 'active', 'completed'].contains(rideData.displayStatus)) {
        joinedRides++;
      }
    }

    if (rideData.displayStatus == 'completed') {
      completedRides++;
    } else if (rideData.displayStatus == 'cancelled') {
      cancelledRides++;
    }
  }

  return ProfileStats(
    createdRides: createdRides,
    joinedRides: joinedRides,
    completedRides: completedRides,
    cancelledRides: cancelledRides,
  );
});
