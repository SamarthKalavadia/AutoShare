import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/ride_model.dart';
import '../../../shared/utils/avatar_utils.dart';
import '../providers/driver_profile_provider.dart';

class DriverInfoCard extends ConsumerWidget {
  final RideModel ride;

  const DriverInfoCard({super.key, required this.ride});

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

    // Fetch the actual user profile for the driver
    final driverUserAsync = ref.watch(userProfileProvider(ride.driverId));
    final driverUser = driverUserAsync.value;

    String resolvedDriverName = '';
    if (driverUser != null &&
        driverUser.name.trim().isNotEmpty &&
        driverUser.name.trim().toLowerCase() != 'driver' &&
        driverUser.name.trim().toLowerCase() != 'user') {
      resolvedDriverName = driverUser.name.trim();
    } else if (ride.driverName.trim().isNotEmpty &&
        ride.driverName.trim().toLowerCase() != 'driver' &&
        ride.driverName.trim().toLowerCase() != 'unknown driver' &&
        ride.driverName.trim().toLowerCase() != 'user') {
      resolvedDriverName = ride.driverName.trim();
    } else if (driverUser != null && driverUser.email.trim().isNotEmpty) {
      final emailPart = driverUser.email.trim().split('@').first;
      if (emailPart.isNotEmpty && emailPart.toLowerCase() != 'driver') {
        resolvedDriverName =
            emailPart[0].toUpperCase() + emailPart.substring(1);
      }
    }

    if (resolvedDriverName.isEmpty) {
      resolvedDriverName = driverUserAsync.isLoading
          ? 'Loading...'
          : (driverUser?.name.isNotEmpty == true
              ? driverUser!.name
              : 'Ride Partner');
    }

    final initials = _getInitials(resolvedDriverName);
    final rating = (driverUser != null && driverUser.averageRating > 0)
        ? driverUser.averageRating
        : ride.driverRating;

    final avatarProvider = getAvatarImageProvider(driverUser?.profileImage);

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
          // Avatar
          Hero(
            tag: 'driver-avatar-${ride.id}',
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2A2C)
                    : const Color(0xFFF3F3F3),
                shape: BoxShape.circle,
                image: avatarProvider != null
                    ? DecorationImage(
                        image: avatarProvider,
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: avatarProvider == null
                  ? Center(
                      child: Text(
                        initials,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: blackColor,
                        ),
                      ),
                    )
                  : null,
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
                        resolvedDriverName,
                        style: theme.textTheme.titleMedium?.copyWith(
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
                      rating > 0 ? rating.toStringAsFixed(1) : 'New',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
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
    final bgColor = isDark ? const Color(0xFF1B3D23) : const Color(0xFFE8F5E9);
    final iconColor = isDark
        ? const Color(0xFF81C784)
        : const Color(0xFF2E7D32);

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
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.female_rounded, size: 14, color: primaryColor),
          const SizedBox(width: 4),
          Text(
            'Girls Only',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: primaryColor,
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(1, (i) {
        // Show just 1 star in BlaBlaCar style instead of 5
        return Icon(Icons.star_rounded, size: 16, color: primaryColor);
      }),
    );
  }
}
