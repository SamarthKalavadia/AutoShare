import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../my_rides/providers/my_rides_provider.dart';
import '../../../data/repositories/rating_repository.dart';
import '../../../data/models/ride_model.dart';
import '../../../data/models/user_model.dart';
import '../../../core/utils/result.dart';

class PendingRatingPrompt {
  final RideModel ride;
  final String toUserId;
  final String toUserName;

  PendingRatingPrompt({
    required this.ride,
    required this.toUserId,
    required this.toUserName,
  });
}

final ratingsPromptProvider = FutureProvider.autoDispose<PendingRatingPrompt?>((ref) async {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return null;

  final allRides = await ref.watch(myRidesProvider.future);
  final completedRides = allRides.where((r) =>
      r.displayStatus == 'completed' ||
      (r.isPast && !['cancelled', 'rejected'].contains(r.displayStatus))).toList();

  final ratingRepo = ref.watch(ratingRepositoryProvider);

  for (final rideData in completedRides) {
    final ride = rideData.ride;
    final isDriver = ride.driverId == user.uid;

    String toUserId = '';
    String toUserName = '';

    if (isDriver) {
      if (rideData.request != null) {
        toUserId = rideData.request!.requesterUid;
        final result = await ref.read(userRepositoryProvider).getUser(toUserId);
        if (result is Success<UserModel>) {
          toUserName = result.data.name;
        } else {
          toUserName = 'Passenger';
        }
      }
    } else {
      toUserId = ride.driverId;
      toUserName = ride.driverName;
    }

    if (toUserId.isNotEmpty && toUserId != user.uid) {
      final hasRated = await ratingRepo.hasRated(ride.id, user.uid, toUserId);
      if (!hasRated) {
        return PendingRatingPrompt(
          ride: ride,
          toUserId: toUserId,
          toUserName: toUserName,
        );
      }
    }
  }

  return null;
});
