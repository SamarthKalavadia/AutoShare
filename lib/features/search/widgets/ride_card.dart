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
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFEAE5DD);
    final mutedText = isDark ? Colors.white60 : const Color(0xFF6F6F72);
    final cardBg = theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final footerBg = isDark ? const Color(0xFF242424) : const Color(0xFFF6F5F3);
    final avatarBg = isDark ? const Color(0xFF2A2A2C) : const Color(0xFFF6F5F3);
    
    final currentUserId = ref.read(authControllerProvider).value?.uid ?? '';
    final isOwner = ride.driverId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x33000000) : const Color(0x0A121212),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header: Driver Info and Badges
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Driver Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: avatarBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: Text(
                      ride.driverName.isNotEmpty ? ride.driverName[0].toUpperCase() : 'U',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: blackColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Driver Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              ride.driverName,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: blackColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded, color: Color(0xFF2E7D32), size: 16),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: primaryColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            ride.driverRating.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: blackColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.circle, size: 4, color: Color(0xFFD0D0D0)),
                          const SizedBox(width: 12),
                          Text(
                            ride.distance,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: mutedText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Badges
                if (ride.isGirlsOnly)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF3D1C28) : const Color(0xFFFDF0F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.female_rounded, color: Color(0xFFD81B60), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Girls Only',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFD81B60),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          Divider(height: 1, color: borderColor),
          
          // Route and Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Timeline Graphics
                Column(
                  children: [
                    const Icon(Icons.trip_origin_rounded, color: Color(0xFF2E7D32), size: 14),
                    Container(
                      width: 2,
                      height: 24,
                      color: borderColor,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    const Icon(Icons.location_on_rounded, color: Color(0xFFD32F2F), size: 14),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Locations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.boardingLocation,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: blackColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        ride.destination,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: blackColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Time & Seats
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('hh:mm a').format(ride.departureTime),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: blackColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd').format(ride.departureTime),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: mutedText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.airline_seat_recline_normal_rounded, color: mutedText, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${ride.availableSeats} seats',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: blackColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: footerBg,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Fare',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: mutedText,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '₹${ride.farePerSeat.toInt()}',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: blackColor,
                          ),
                        ),
                        Text(
                          ' / seat',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: mutedText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                if (isOwner)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      'Your Ride',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : const Color(0xFF4C4C4F),
                      ),
                    ),
                  )
                else
                  FilledButton(
                    onPressed: () {
                      context.push('/ride-details', extra: ride);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: blackColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      'View Details',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
