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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final primaryColor = theme.colorScheme.primary;
    final blackColor = theme.colorScheme.onSurface;
    final mutedText = isDark ? Colors.white60 : const Color(0xFF6F6F72);
    final cardBg = theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final iconBg = primaryColor.withValues(alpha: isDark ? 0.2 : 0.3);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: const Color(0xFF333333), width: 1.1) : Border.all(color: primaryColor.withValues(alpha: 0.1), width: 1.5),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: const Color(0xFF121212).withValues(alpha: 0.08),
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
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.directions_car, color: primaryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ride.boardingLocation} → ${ride.destination}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: blackColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d • h:mm a').format(ride.departureTime),
                  style: theme.textTheme.labelSmall?.copyWith(
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
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: blackColor,
                ),
              ),
              Text(
                'per seat',
                style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: mutedText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
