import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/ride_model.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

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

    final currentUserId = ref.read(authControllerProvider).value?.uid ?? '';
    final isOwner = ride.driverId == currentUserId;

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
            context.push('/ride-details', extra: ride);
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
                                DateFormat('h:mm a').format(ride.departureTime),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                DateFormat('h:mm a').format(
                                  ride.departureTime.add(
                                    _parseDuration(ride.estimatedDuration),
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
                                  ride.boardingLocation,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  ride.destination,
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
                          '₹${ride.farePerSeat.toInt()}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                          ),
                        ),
                        if (isOwner)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Your Ride',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                ),
                const SizedBox(height: 16),

                // Driver Footer
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
                          child: Text(
                            ride.driverName.isNotEmpty
                                ? ride.driverName[0].toUpperCase()
                                : 'U',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  ride.driverName.split(' ').first,
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
                                  ride.driverRating.toStringAsFixed(1),
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
                        if (ride.isGirlsOnly)
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
                        Icon(
                          Icons.airline_seat_recline_normal_rounded,
                          color: mutedText,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${ride.availableSeats}',
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
