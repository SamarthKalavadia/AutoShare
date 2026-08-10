import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:autoshare/data/models/ride_model.dart';

/// Pinned ride summary banner shown at the top of the chat.
class RideSummaryBanner extends StatelessWidget {
  final RideModel ride;

  const RideSummaryBanner({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF6C000);
    const blackColor = Color(0xFF121212);
    const mutedText = Color(0xFF6F6F72);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withAlpha(100), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: blackColor.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(30),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.directions_car, color: primaryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ride.boardingLocation} → ${ride.destination}',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: blackColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d • h:mm a').format(ride.departureTime),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: mutedText,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${ride.farePerSeat.toInt()}',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: blackColor,
                ),
              ),
              Text(
                'per seat',
                style: GoogleFonts.inter(fontSize: 10, color: mutedText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
