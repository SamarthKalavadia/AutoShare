import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/ride_model.dart';

class DriverInfoCard extends StatelessWidget {
  final RideModel ride;

  const DriverInfoCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    const blackColor = Color(0xFF121212);
    const borderColor = Color(0xFFEAE5DD);
    const mutedText = Color(0xFF6F6F72);

    final initials = _getInitials(ride.driverName);
    final rating = ride.driverRating;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(color: Color(0x0A121212), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Hero(
            tag: 'driver-avatar-${ride.id}',
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF6C000), Color(0xFFE6A800)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Color(0x33F6C000), blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: blackColor,
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
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
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
                    _StarRating(rating: rating),
                    const SizedBox(width: 6),
                    Text(
                      rating > 0 ? rating.toStringAsFixed(1) : 'No rating yet',
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF2E7D32)),
          const SizedBox(width: 3),
          Text(
            'Verified',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2E7D32),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF48FB1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.female_rounded, size: 14, color: Color(0xFFC2185B)),
          const SizedBox(width: 4),
          Text(
            'Girls Only',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFC2185B),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final double rating;

  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half = !filled && (i < rating);
        return Icon(
          filled
              ? Icons.star_rounded
              : half
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
          size: 15,
          color: const Color(0xFFF6C000),
        );
      }),
    );
  }
}
