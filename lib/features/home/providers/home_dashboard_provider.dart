import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../my_rides/providers/my_rides_provider.dart';
import '../../notifications/providers/notification_provider.dart';

/// Provides the single most imminent active ride for the Home Dashboard.
final activeRideProvider = FutureProvider.autoDispose<MyRideData?>((ref) async {
  final allRides = await ref.watch(myRidesProvider.future);

  // Find the first upcoming ride that is active (driver) or joined (passenger)
  final upcomingRides = allRides.where((r) {
    if (r.isPast) return false;
    final status = r.displayStatus;
    return status == 'active' || status == 'joined';
  }).toList();

  // Sort upcoming rides ascending (closest in time first)
  upcomingRides.sort(
    (a, b) => a.ride.departureTime.compareTo(b.ride.departureTime),
  );

  if (upcomingRides.isNotEmpty) {
    return upcomingRides.first;
  }

  return null;
});

/// Provides the realtime count of unread chat messages
final unreadChatCountProvider = Provider.autoDispose<int>((ref) {
  final notifs = ref.watch(rawNotificationsStreamProvider).value ?? [];
  return notifs.where((n) => !n.isRead && n.type == 'chat').length;
});
