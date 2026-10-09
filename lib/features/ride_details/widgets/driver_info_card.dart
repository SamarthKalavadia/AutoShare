import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/ride_model.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/utils/avatar_utils.dart';
import '../../my_rides/providers/my_rides_provider.dart';
import '../providers/driver_profile_provider.dart';
import '../providers/ride_request_provider.dart';

class DriverInfoCard extends ConsumerWidget {
  final RideModel ride;

  const DriverInfoCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final blackColor = theme.colorScheme.onSurface;
    final borderColor = isDark
        ? const Color(0xFF333333)
        : const Color(0xFFEAE5DD);
    final cardBg =
        theme.cardTheme.color ??
        (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    final liveRide = ref.watch(liveRideProvider(ride)).value ?? ride;

    // Resolve effective driver ID from ride, live ride, or matching ride/request
    String effectiveDriverId = ride.driverId.isNotEmpty ? ride.driverId : liveRide.driverId;
    if (effectiveDriverId.isEmpty) {
      final myRides = ref.watch(myRidesProvider).value ?? [];
      final match = myRides.where((m) => m.ride.id == ride.id || m.request?.rideId == ride.id).firstOrNull;
      if (match != null) {
        if (match.role == 'driver' && match.ride.driverId.isNotEmpty) {
          effectiveDriverId = match.ride.driverId;
        } else if (match.request?.ownerUid != null && match.request!.ownerUid.isNotEmpty) {
          effectiveDriverId = match.request!.ownerUid;
        } else if (match.ride.driverId.isNotEmpty) {
          effectiveDriverId = match.ride.driverId;
        }
      }
    }

    // Fetch the actual user profile for the driver
    final driverUserAsync = effectiveDriverId.isNotEmpty
        ? ref.watch(userProfileProvider(effectiveDriverId))
        : const AsyncValue<UserModel?>.data(null);
    final driverUser = driverUserAsync.value;

    String resolvedDriverName = '';
    if (driverUser != null &&
        driverUser.name.trim().isNotEmpty &&
        driverUser.name.trim().toLowerCase() != 'driver' &&
        driverUser.name.trim().toLowerCase() != 'user' &&
        driverUser.name.trim().toLowerCase() != 'ride partner') {
      resolvedDriverName = driverUser.name.trim();
    } else if (liveRide.driverName.trim().isNotEmpty &&
        liveRide.driverName.trim().toLowerCase() != 'driver' &&
        liveRide.driverName.trim().toLowerCase() != 'unknown driver' &&
        liveRide.driverName.trim().toLowerCase() != 'user' &&
        liveRide.driverName.trim().toLowerCase() != 'ride partner') {
      resolvedDriverName = liveRide.driverName.trim();
    } else if (ride.driverName.trim().isNotEmpty &&
        ride.driverName.trim().toLowerCase() != 'driver' &&
        ride.driverName.trim().toLowerCase() != 'unknown driver' &&
        ride.driverName.trim().toLowerCase() != 'user' &&
        ride.driverName.trim().toLowerCase() != 'ride partner') {
      resolvedDriverName = ride.driverName.trim();
    } else if (driverUser != null && driverUser.email.trim().isNotEmpty) {
      final emailPart = driverUser.email.trim().split('@').first;
      if (emailPart.isNotEmpty && emailPart.toLowerCase() != 'driver') {
        resolvedDriverName =
            emailPart[0].toUpperCase() + emailPart.substring(1);
      }
    }

    if (resolvedDriverName.isEmpty) {
      resolvedDriverName = driverUserAsync.isLoading
          ? 'Loading...'
          : (driverUser != null &&
                  driverUser.name.isNotEmpty &&
                  driverUser.name.trim().toLowerCase() != 'ride partner'
              ? driverUser.name
              : 'Ride Partner');
    }

    final initials = _getInitials(resolvedDriverName);
    final avatarProvider = getAvatarImageProvider(driverUser?.profileImage);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: borderColor, width: 1.1) : null,
        boxShadow: isDark
            ? []
            : const [
                BoxShadow(
                  color: Color(0x0F121212),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          // Avatar
          Hero(
            tag: 'driver-avatar-${ride.id}',
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2A2C)
                    : const Color(0xFFF3F3F3),
                shape: BoxShape.circle,
                image: avatarProvider != null
                    ? DecorationImage(
                        image: avatarProvider,
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: avatarProvider == null
                  ? Center(
                      child: Text(
                        initials,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: blackColor,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),

          // Driver details
          Expanded(
            child: Text(
              resolvedDriverName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: blackColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Girls Only badge (right side)
          if (ride.isGirlsOnly) ...[
            const SizedBox(width: 12),
            _GirlsOnlyBadge(),
          ],
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _GirlsOnlyBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.female_rounded, size: 14, color: primaryColor),
          const SizedBox(width: 4),
          Text(
            'Girls Only',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
