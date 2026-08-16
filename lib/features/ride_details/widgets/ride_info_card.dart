import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/ride_model.dart';
import '../providers/ride_request_provider.dart';

class RideInfoCard extends ConsumerWidget {
  final RideModel ride;

  const RideInfoCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final blackColor = theme.colorScheme.onSurface;
    final borderColor = isDark
        ? const Color(0xFF333333)
        : const Color(0xFFEAE5DD);
    final mutedText = isDark ? Colors.white60 : const Color(0xFF6F6F72);
    final cardBg =
        theme.cardTheme.color ??
        (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    final state = ref.watch(rideRequestProvider);

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
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.currency_rupee_rounded,
                  label: 'Fare / Seat',
                  value: '₹${ride.farePerSeat.toStringAsFixed(0)}',
                  highlight: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  icon: Icons.event_seat_rounded,
                  label: 'Available Seats',
                  value: '${ride.availableSeats}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Requested seats stepper
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF28282A) : const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.people_alt_rounded, size: 18, color: mutedText),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Requested Seats',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${state.requestedSeats}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: blackColor,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _StepperButton(
                  icon: Icons.remove_rounded,
                  onTap: state.requestedSeats > 1
                      ? () => ref
                            .read(rideRequestProvider.notifier)
                            .decrementSeats()
                      : null,
                ),
                const SizedBox(width: 8),
                _StepperButton(
                  icon: Icons.add_rounded,
                  onTap:
                      state.requestedSeats < ride.availableSeats &&
                          state.requestedSeats < 4
                      ? () => ref
                            .read(rideRequestProvider.notifier)
                            .incrementSeats(ride.availableSeats)
                      : null,
                ),
              ],
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
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _InfoTile({
    required this.icon,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: highlight
            ? primaryColor.withValues(alpha: 0.1)
            : (isDark ? const Color(0xFF28282A) : const Color(0xFFF3F3F3)),
        borderRadius: BorderRadius.circular(14),
        border: highlight
            ? Border.all(color: primaryColor.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: highlight
                ? primaryColor
                : (isDark ? Colors.white60 : const Color(0xFF6F6F72)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark ? Colors.white54 : const Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isEnabled
              ? (isDark ? const Color(0xFF38383A) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isEnabled
              ? (isDark
                    ? []
                    : const [
                        BoxShadow(
                          color: Color(0x15000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ])
              : [],
        ),
        child: Icon(
          icon,
          size: 18,
          color: isEnabled
              ? Theme.of(context).colorScheme.onSurface
              : (isDark ? Colors.white24 : const Color(0xFFD0D0D0)),
        ),
      ),
    );
  }
}
