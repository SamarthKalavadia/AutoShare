import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_seat_icon.dart';
import '../../../data/models/ride_model.dart';
import '../../../shared/utils/avatar_utils.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../ride_details/providers/driver_profile_provider.dart';
import '../../ride_details/providers/ride_request_provider.dart';

class RideCard extends ConsumerWidget {
  final RideModel ride;

  const RideCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const primaryColor = Color(0xFFF6C000);
    final blackColor = theme.colorScheme.onSurface;
    final borderColor = isDark
        ? const Color(0xFF333333)
        : const Color(0xFFEAE5DD);
    final mutedText = isDark ? Colors.white60 : const Color(0xFF6F6F72);
    final cardBg =
        theme.cardTheme.color ??
        (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    final driverUser = ref.watch(userProfileProvider(ride.driverId)).value;
    String resolvedDriverName = '';
    if (driverUser != null &&
        driverUser.name.trim().isNotEmpty &&
        driverUser.name.trim().toLowerCase() != 'driver' &&
        driverUser.name.trim().toLowerCase() != 'user') {
      resolvedDriverName = driverUser.name.trim();
    } else if (ride.driverName.trim().isNotEmpty &&
        ride.driverName.trim().toLowerCase() != 'driver' &&
        ride.driverName.trim().toLowerCase() != 'unknown driver' &&
        ride.driverName.trim().toLowerCase() != 'user') {
      resolvedDriverName = ride.driverName.trim();
    } else if (driverUser != null && driverUser.email.trim().isNotEmpty) {
      final emailPart = driverUser.email.trim().split('@').first;
      if (emailPart.isNotEmpty && emailPart.toLowerCase() != 'driver') {
        resolvedDriverName =
            emailPart[0].toUpperCase() + emailPart.substring(1);
      }
    }
    if (resolvedDriverName.isEmpty) {
      resolvedDriverName =
          driverUser?.name.isNotEmpty == true ? driverUser!.name : 'User';
    }

    final liveRide = ref.watch(liveRideProvider(ride)).value ?? ride;
    final dynamicFare = ref.watch(dynamicFareProvider(ride));
    final liveSeats = ref.watch(liveAvailableSeatsProvider(ride));
    final isFull = liveSeats <= 0;

    final avatarProvider = getAvatarImageProvider(driverUser?.profileImage);

    final currentUserId = ref.read(authControllerProvider).value?.uid ?? '';
    final isOwner = liveRide.driverId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: borderColor, width: 1.1) : null,
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            context.push('/ride-details', extra: liveRide);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route, Time and Price Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline and Locations
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('h:mm a').format(liveRide.departureTime),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                DateFormat('h:mm a').format(
                                  liveRide.departureTime.add(
                                    _parseDuration(liveRide.estimatedDuration),
                                  ),
                                ),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Column(
                            children: [
                              const SizedBox(height: 10),
                              Icon(
                                Icons.circle_outlined,
                                color: blackColor,
                                size: 12,
                              ),
                              Container(
                                width: 2,
                                height: 28,
                                color: isDark ? Colors.white24 : Colors.black12,
                                margin: const EdgeInsets.symmetric(vertical: 2),
                              ),
                              Icon(Icons.circle, color: blackColor, size: 12),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  liveRide.boardingLocation,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  liveRide.destination,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${dynamicFare.round()}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          '/ person',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Current fare',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: mutedText,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 6),
                // Fare Explanation Helper Text
                if (!isFull)
                  Text(
                    'Fare decreases as more riders join',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: mutedText,
                      fontSize: 11,
                    ),
                  )
                else
                  Text(
                    'Ride full',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFFD32F2F),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                ),
                const SizedBox(height: 14),

                // Driver Footer & Seats / Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isDark
                              ? const Color(0xFF2A2A2C)
                              : const Color(0xFFF3F3F3),
                          backgroundImage: avatarProvider,
                          child: avatarProvider == null
                              ? Text(
                                  resolvedDriverName.isNotEmpty
                                      ? resolvedDriverName[0].toUpperCase()
                                      : 'U',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  resolvedDriverName.split(' ').first,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.star_rounded,
                                  color: primaryColor,
                                  size: 14,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  liveRide.driverRating.toStringAsFixed(1),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (liveRide.isGirlsOnly)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.female_rounded,
                              color: primaryColor,
                              size: 16,
                            ),
                          ),
                        if (isFull)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFF3F3F3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Ride Full',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFD32F2F),
                              ),
                            ),
                          )
                        else
                          Row(
                            children: [
                              AppSeatIcon(
                                size: 16,
                                color: mutedText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$liveSeats ${liveSeats == 1 ? "seat" : "seats"} available',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: mutedText,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                // Join / Full Button State
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isOwner)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Your Ride',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: mutedText,
                          ),
                        ),
                      )
                    else if (isFull)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF28282A)
                              : const Color(0xFFE8E8E8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Full',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: mutedText,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Request to Join',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF121212),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Duration _parseDuration(String durationStr) {
    if (durationStr.isEmpty) return const Duration(hours: 1); // fallback

    int hours = 0;
    int minutes = 0;

    final hMatch = RegExp(r'(\d+)\s*h').firstMatch(durationStr);
    if (hMatch != null) hours = int.tryParse(hMatch.group(1) ?? '0') ?? 0;

    final mMatch = RegExp(r'(\d+)\s*m').firstMatch(durationStr);
    if (mMatch != null) minutes = int.tryParse(mMatch.group(1) ?? '0') ?? 0;

    if (hours == 0 && minutes == 0) {
      // Just try to get any number and assume minutes
      final anyNum = RegExp(r'(\d+)').firstMatch(durationStr);
      if (anyNum != null) {
        minutes = int.tryParse(anyNum.group(1) ?? '0') ?? 0;
      } else {
        return const Duration(hours: 1); // fallback
      }
    }

    return Duration(hours: hours, minutes: minutes);
  }
}
