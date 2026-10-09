import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_seat_icon.dart';
import '../../../data/models/ride_model.dart';
import '../providers/ride_request_provider.dart';

class RideInfoCard extends ConsumerWidget {
  final RideModel ride;

  const RideInfoCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = theme.colorScheme.primary;
    final blackColor = theme.colorScheme.onSurface;
    final borderColor = isDark
        ? const Color(0xFF333333)
        : const Color(0xFFEAE5DD);
    final mutedText = isDark ? Colors.white60 : const Color(0xFF6F6F72);
    final cardBg =
        theme.cardTheme.color ??
        (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    final dynamicFare = ref.watch(dynamicFareProvider(ride));
    final liveSeats = ref.watch(liveAvailableSeatsProvider(ride));

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RIDE DETAILS',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: mutedText,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),

          // Fare + Available seats
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _InfoTile(
                    iconWidget: Icon(
                      Icons.currency_rupee_rounded,
                      size: 16,
                      color: primaryColor,
                    ),
                    label: 'Fare / Seat',
                    value: '₹${dynamicFare.round()}',
                    highlight: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoTile(
                    iconWidget: AppSeatIcon(
                      size: 16,
                      color: isDark ? Colors.white70 : const Color(0xFF6F6F72),
                    ),
                    label: 'Available Seats',
                    value: '$liveSeats',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              liveSeats == 0
                  ? 'Ride full • ₹${dynamicFare.round()} / person'
                  : 'Current fare: ₹${dynamicFare.round()} / person (Fare decreases as more riders join)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Vehicle number (if present)
          if (ride.vehicleNumber.isNotEmpty) ...[
            const SizedBox(height: 12),
            _VehicleNumberTile(vehicleNumber: ride.vehicleNumber),
          ],

          // Description (if present)
          if (ride.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
            ),
            const SizedBox(height: 14),
            Text(
              'RIDE NOTE',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: mutedText,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ride.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: blackColor,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final Widget iconWidget;
  final String label;
  final String value;
  final bool highlight;

  const _InfoTile({
    required this.iconWidget,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final blackColor = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: highlight
            ? primaryColor.withValues(alpha: 0.1)
            : (isDark ? const Color(0xFF28282A) : const Color(0xFFF3F3F3)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? primaryColor.withValues(alpha: 0.35)
              : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE2E2E2)),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 16,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: Center(child: iconWidget),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 16,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark ? Colors.white54 : const Color(0xFF9E9E9E),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: 1.2,
                    color: highlight ? primaryColor : blackColor,
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

class _VehicleNumberTile extends StatelessWidget {
  final String vehicleNumber;

  const _VehicleNumberTile({required this.vehicleNumber});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C223A) : const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF283593) : const Color(0xFFBBCBFF),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.directions_car_rounded,
            size: 18,
            color: isDark ? const Color(0xFF7986CB) : const Color(0xFF3D5AFE),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vehicle',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark ? Colors.white54 : const Color(0xFF9E9E9E),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                vehicleNumber,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
