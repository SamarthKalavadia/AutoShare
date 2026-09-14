import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/ride_model.dart';

class DriverInfoCard extends StatelessWidget {
  final RideModel ride;

  const DriverInfoCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final blackColor = theme.colorScheme.onSurface;
    final borderColor = isDark
        ? const Color(0xFF2D3F37)
        : const Color(0xFFE3EBE6);
    final mutedText = isDark ? const Color(0xFFA0B2AA) : const Color(0xFF6B7E75);
    final cardBg =
        theme.cardTheme.color ??
        (isDark ? const Color(0xFF18221D) : Colors.white);

    final initials = _getInitials(ride.driverName);
    final rating = ride.driverRating;

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
                  color: Color(0x0A121212),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          // Coral Avatar
          Hero(
            tag: 'driver-avatar-${ride.id}',
            child: Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Color(0xFFD85A30),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Driver details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + verified badge
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        ride.driverName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: blackColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _VerifiedBadge(),
                  ],
                ),
                const SizedBox(height: 6),

                // Star rating
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Color(0xFFFFB800),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating > 0 ? rating.toStringAsFixed(1) : 'New',
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

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1B2F25) : const Color(0xFFF0F7F4);
    final iconColor = isDark
        ? const Color(0xFF10B981)
        : const Color(0xFF084E31);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 12, color: iconColor),
          const SizedBox(width: 3),
          Text(
            'Verified',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _GirlsOnlyBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? const Color(0xFF10B981)
        : const Color(0xFF084E31);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2F25) : const Color(0xFFF0F7F4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2E4D3D) : const Color(0xFFC4E3D4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.female_rounded, size: 14, color: primaryColor),
          const SizedBox(width: 4),
          Text(
            'Girls Only',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
