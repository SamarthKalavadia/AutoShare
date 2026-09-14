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

    final primaryGreen = isDark
        ? const Color(0xFF10B981)
        : const Color(0xFF084E31);
    final blackColor = theme.colorScheme.onSurface;
    final borderColor = isDark
        ? const Color(0xFF2D3F37)
        : const Color(0xFFE3EBE6);
    final mutedText = isDark ? const Color(0xFFA0B2AA) : const Color(0xFF6B7E75);
    final cardBg =
        theme.cardTheme.color ??
        (isDark ? const Color(0xFF18221D) : Colors.white);

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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('h:mm a').format(ride.departureTime),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: blackColor,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                DateFormat('h:mm a').format(
                                  ride.departureTime.add(
                                    _parseDuration(ride.estimatedDuration),
                                  ),
                                ),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: blackColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Column(
                            children: [
                              const SizedBox(height: 8),
                              const Icon(
                                Icons.adjust_rounded,
                                color: Color(0xFFE5A93C),
                                size: 14,
                              ),
                              Container(
                                width: 2,
                                height: 28,
                                color: borderColor,
                                margin: const EdgeInsets.symmetric(vertical: 2),
                              ),
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFFE53935),
                                size: 14,
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  ride.boardingLocation,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: blackColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 22),
                                Text(
                                  ride.destination,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: blackColor,
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
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            color: primaryGreen,
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
                                  ? const Color(0xFF1F2D26)
                                  : const Color(0xFFF0F7F4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Your Ride',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: primaryGreen,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 18),
                Divider(
                  height: 1,
                  color: borderColor,
                ),
                const SizedBox(height: 14),

                // Driver Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFFD85A30),
                          child: Text(
                            ride.driverName.isNotEmpty
                                ? ride.driverName[0].toUpperCase()
                                : 'U',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  ride.driverName.split(' ').first,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: blackColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFB800),
                                  size: 16,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  ride.driverRating.toStringAsFixed(1),
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
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
                              color: isDark
                                  ? const Color(0xFF1F2D26)
                                  : const Color(0xFFF0F7F4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.female_rounded,
                              color: primaryGreen,
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
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
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
      final anyNum = RegExp(r'(\d+)').firstMatch(durationStr);
      if (anyNum != null) {
        minutes = int.tryParse(anyNum.group(1) ?? '0') ?? 0;
      } else {
        return const Duration(hours: 1);
      }
    }

    return Duration(hours: hours, minutes: minutes);
  }
}
