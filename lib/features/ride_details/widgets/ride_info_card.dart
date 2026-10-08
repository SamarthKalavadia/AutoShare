import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_seat_icon.dart';
import '../../../core/utils/result.dart';
import '../../../data/models/ride_model.dart';
import '../../../shared/providers.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../providers/ride_request_provider.dart';
import '../../my_rides/providers/my_rides_provider.dart';
import '../../search/providers/search_ride_provider.dart';

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
    final liveRide = ref.watch(liveRideProvider(ride)).value ?? ride;
    final liveSeats = ref.watch(liveAvailableSeatsProvider(ride));
    final currentUid = ref.watch(authControllerProvider).value?.uid;
    final isOwner = currentUid != null && currentUid == liveRide.driverId;
    final isExpired = liveRide.departureTime.isBefore(DateTime.now());
    final isClosed =
        liveRide.status == 'completed' || liveRide.status == 'cancelled';

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
          const SizedBox(height: 12),

          // Stepper: Available Seats (Only ride creator can edit/change the number of seats: 1 or 2 only)
          if (isOwner) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF28282A) : const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AppSeatIcon(
                            size: 15,
                            color: mutedText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Available Seats',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: mutedText,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 21),
                        child: Text(
                          '${liveRide.availableSeats.clamp(1, 2)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: blackColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _StepperButton(
                    icon: Icons.remove_rounded,
                    onTap: (!isClosed && !isExpired && liveRide.availableSeats > 1)
                        ? () => _updateSeats(
                              context,
                              ref,
                              liveRide,
                              (liveRide.availableSeats - 1).clamp(1, 2),
                            )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  _StepperButton(
                    icon: Icons.add_rounded,
                    onTap: (!isClosed && !isExpired && liveRide.availableSeats < 2)
                        ? () => _updateSeats(
                              context,
                              ref,
                              liveRide,
                              liveRide.availableSeats < 1 ? 1 : 2,
                            )
                        : null,
                  ),
                ],
              ),
            ),
          ],

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

  Future<void> _updateSeats(
    BuildContext context,
    WidgetRef ref,
    RideModel ride,
    int newSeats,
  ) async {
    final clampedSeats = newSeats.clamp(1, 2);
    HapticFeedback.mediumImpact();
    final res = await ref.read(rideRepositoryProvider).updateAvailableSeats(
      ride.id,
      clampedSeats,
    );
    if (!context.mounted) return;
    if (res is Success) {
      ref.invalidate(liveRideProvider(ride));
      ref.invalidate(dynamicFareProvider(ride));
      ref.invalidate(myRidesProvider);
      if (ref.read(searchRideProvider).hasSearched) {
        ref.read(searchRideProvider.notifier).searchRides();
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Available seats updated to $newSeats'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } else if (res is Failure) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
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
