import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../notifications/providers/notification_provider.dart';
import '../../providers/home_dashboard_provider.dart';
import '../../providers/home_search_provider.dart';
import '../../../profile/providers/user_profile_provider.dart';
import '../../../../shared/utils/avatar_utils.dart';
import '../../../ride_details/providers/create_ride_provider.dart';
import '../../../../shared/widgets/location_autocomplete_field.dart';
import '../../../../services/location_service.dart' show LocationService, PermissionException, HttpException;


class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = isDark
        ? const Color(0xFFFFC400)
        : theme.colorScheme.primary;
    final backgroundColor = isDark
        ? const Color(0xFF0F0F0F)
        : theme.scaffoldBackgroundColor;
    final cardColor = isDark
        ? const Color(0xFF181818)
        : (theme.cardTheme.color ?? const Color(0xFFFFFFFF));
    final borderColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFEAE5DD);
    final textPrimary = isDark
        ? const Color(0xFFFFFFFF)
        : theme.colorScheme.onSurface;
    final textSecondary = isDark
        ? const Color(0xFFA1A1A1)
        : const Color(0xFF6F6F72);

    final user = ref.watch(authControllerProvider).value;
    final searchState = ref.watch(homeSearchProvider);
    final isFemale = user?.gender.toLowerCase() == 'female';

    String greeting = 'Good Morning,';
    final hour = DateTime.now().hour;
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon,';
    } else if (hour >= 17) {
      greeting = 'Good Evening,';
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 92,
        titleSpacing: 12,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/images/logo.png',
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    greeting,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.name.split(' ').first ?? 'Guest',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF202020)
                        : const Color(0xFFF7F4EE),
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor),
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: textPrimary,
                    size: 20,
                  ),
                ),
                Consumer(
                  builder: (ctx, ref, _) {
                    final count = ref.watch(unreadNotificationCountProvider);
                    if (count == 0) return const SizedBox.shrink();
                    return Positioned(
                      right: 4,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4444),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: backgroundColor,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 18),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF202020)
                    : const Color(0xFFF7F4EE),
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: getAvatarImageProvider(user?.profileImage) != null
                  ? Image(
                      image: getAvatarImageProvider(user!.profileImage)!,
                      fit: BoxFit.cover,
                    )
                  : Center(
                      child: Text(
                        user?.name.isNotEmpty == true
                            ? user!.name[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.inter(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                const SizedBox(height: 10),
                AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 400),
                  child: AnimatedSlide(
                    offset: const Offset(0, 0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    child: Text(
                      'Where to next?',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _animatedCard(
                  duration: 500,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: isDark ? Border.all(color: borderColor, width: 1.1) : null,
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    child: Column(
                      children: [
                        // Uber-style stacked location inputs
                        InkWell(
                          onTap: () => context.push('/create-ride'),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF202020) : const Color(0xFFF3F3F3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  // Visual Route Line
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white70 : Colors.black87,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            width: 2,
                                            color: isDark ? Colors.white24 : Colors.black12,
                                            margin: const EdgeInsets.symmetric(vertical: 6),
                                          ),
                                        ),
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.rectangle,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  // Inputs
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _uberInput(
                                          context: context,
                                          label: searchState.boarding.isEmpty
                                              ? 'Pickup location'
                                              : searchState.boarding,
                                          isBold: searchState.boarding.isNotEmpty,
                                          onTap: () => context.push('/create-ride'),
                                        ),
                                        Divider(
                                          height: 24,
                                          thickness: 1,
                                          color: isDark ? Colors.white12 : Colors.black12,
                                        ),
                                        _uberInput(
                                          context: context,
                                          label: searchState.destination.isEmpty
                                              ? 'Dropoff location'
                                              : searchState.destination,
                                          isBold: searchState.destination.isNotEmpty,
                                          onTap: () => context.push('/create-ride'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _uberActionButton(
                                context: context,
                                icon: Icons.calendar_today_rounded,
                                label: searchState.departureDate == null
                                    ? 'Today'
                                    : DateFormat('MMM d').format(searchState.departureDate!),
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: searchState.departureDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 30)),
                                  );
                                  if (date != null) {
                                    ref.read(homeSearchProvider.notifier).updateDate(date);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _uberActionButton(
                                context: context,
                                icon: Icons.person_rounded,
                                label: '${searchState.passengers} ${searchState.passengers > 1 ? 'Seats' : 'Seat'}',
                                onTap: () {
                                  int p = searchState.passengers % 4 + 1;
                                  ref.read(homeSearchProvider.notifier).updatePassengers(p);
                                },
                              ),
                            ),
                          ],
                        ),
                        if (isFemale) const SizedBox(height: 16),
                        if (isFemale)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF202020) : const Color(0xFFF3F3F3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.female_rounded, size: 18, color: primaryColor),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Girls Only Ride',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                Switch.adaptive(
                                  value: searchState.girlsOnly,
                                  onChanged: (val) => ref
                                      .read(homeSearchProvider.notifier)
                                      .toggleGirlsOnly(val),
                                  activeThumbColor: primaryColor,
                                  activeTrackColor: primaryColor.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => _handleCreateRideCTA(context, ref, searchState),
                            child: const Text('Create Ride'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleLarge?.copyWith(color: textPrimary),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.search_rounded,
                        label: 'Find a Ride',
                        onTap: () => context.push('/search-ride'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.directions_car_rounded,
                        label: 'My Rides',
                        onTap: () => context.push('/my-rides'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.directions_car_rounded,
                        label: 'Driver Directory',
                        onTap: () => context.push('/driver-directory'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Active Ride',
                  style: theme.textTheme.titleLarge?.copyWith(color: textPrimary),
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, _) {
                    final activeRideAsync = ref.watch(activeRideProvider);
                    return activeRideAsync.when(
                      skipLoadingOnReload: true,
                      data: (activeRideData) {
                    if (activeRideData == null) {
                      return _animatedCard(
                        duration: 550,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                            border: isDark ? Border.all(color: borderColor, width: 1.1) : null,
                            boxShadow: isDark
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.directions_car_filled_rounded,
                                size: 48,
                                color: textSecondary.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No active rides',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(color: textPrimary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your current or upcoming trips will appear here.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final ride = activeRideData.ride;
                    return _animatedCard(
                      duration: 600,
                      child: InkWell(
                        onTap: () => context.push('/ride-details', extra: ride),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                            border: isDark ? Border.all(color: borderColor, width: 1.1) : null,
                            boxShadow: isDark
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 24,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'UPCOMING',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    DateFormat('MMM d, h:mm a').format(ride.departureTime),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              IntrinsicHeight(
                                child: Row(
                                  children: [
                                    Column(
                                      children: [
                                        Icon(Icons.circle, size: 10, color: textSecondary),
                                        Expanded(
                                          child: Container(
                                            width: 2,
                                            color: textSecondary.withValues(alpha: 0.3),
                                            margin: const EdgeInsets.symmetric(vertical: 4),
                                          ),
                                        ),
                                        Icon(Icons.location_on, size: 14, color: primaryColor),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ride.boardingLocation,
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              color: textPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            ride.destination,
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              color: textPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Divider(height: 1),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Consumer(
                                    builder: (ctx, ref, _) {
                                      final driverProfileAsync = ref.watch(userProfileProvider(ride.driverId));
                                      final name = driverProfileAsync.value?.name ?? 'Driver';
                                      return Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                            child: Icon(Icons.person, size: 16, color: theme.colorScheme.onSurface),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            name,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: textPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const Spacer(),
                                  Text(
                                    '₹${ride.farePerSeat.toInt()}',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: textPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                );
              },
            ),
            const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCreateRideCTA(
    BuildContext context,
    WidgetRef ref,
    HomeSearchState searchState,
  ) {
    final boarding = searchState.boarding.trim();
    final destination = searchState.destination.trim();

    if (boarding.isNotEmpty &&
        destination.isNotEmpty &&
        boarding.toLowerCase() == destination.toLowerCase()) {
      _showValidationMessage(
        context,
        'Boarding and destination should be different locations.',
      );
      return;
    }

    final notifier = ref.read(createRideProvider.notifier);
    if (boarding.isNotEmpty) {
      notifier.updateBoardingLocation(boarding);
      if (searchState.boardingPlaceId != null && searchState.boardingAddress != null) {
        notifier.updateBoardingDetails(
          placeId: searchState.boardingPlaceId!,
          address: searchState.boardingAddress!,
          lat: searchState.boardingLat,
          lng: searchState.boardingLng,
        );
      }
    }
    if (destination.isNotEmpty) {
      notifier.updateDestinationLocation(destination);
      if (searchState.destinationPlaceId != null && searchState.destinationAddress != null) {
        notifier.updateDestinationDetails(
          placeId: searchState.destinationPlaceId!,
          address: searchState.destinationAddress!,
          lat: searchState.destinationLat,
          lng: searchState.destinationLng,
        );
      }
    }
    if (searchState.departureDate != null) {
      notifier.updateDepartureDate(searchState.departureDate!);
    }
    notifier.updateAvailableSeats(searchState.passengers);
    notifier.toggleGirlsOnly(searchState.girlsOnly);

    context.push('/create-ride');
  }

  void _showValidationMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF202020),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Okay',
          textColor: const Color(0xFFFFC400),
          onPressed: () {},
        ),
      ),
    );
  }

  void _showLocationPicker(
    BuildContext context,
    WidgetRef ref,
    String field,
  ) {
    final isBoarding = field == 'boarding';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LocationPickerSheet(
        title: isBoarding ? 'Boarding Location' : 'Destination',
        isBoarding: isBoarding,
        onSelected: (label, details) {
          if (isBoarding) {
            ref.read(homeSearchProvider.notifier).updateBoarding(
              label,
              placeId: details?.placeId,
              address: details?.address,
              lat: details?.latitude,
              lng: details?.longitude,
            );
          } else {
            ref.read(homeSearchProvider.notifier).updateDestination(
              label,
              placeId: details?.placeId,
              address: details?.address,
              lat: details?.latitude,
              lng: details?.longitude,
            );
          }
        },
      ),
    );
  }

  Widget _animatedCard({required int duration, required Widget child}) {
    return AnimatedOpacity(
      opacity: 1,
      duration: Duration(milliseconds: duration),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: const Offset(0, 0),
        duration: Duration(milliseconds: duration),
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }

  Widget _uberInput({
    required BuildContext context,
    required String label,
    required bool isBold,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  color: isBold
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uberActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF202020) : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurface),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF181818) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: isDark ? Border.all(color: const Color(0xFF2A2A2A), width: 1.1) : null,
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
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isDark ? const Color(0xFFFFC400) : theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationPickerSheet extends StatefulWidget {
  final String title;
  final bool isBoarding;
  final void Function(String label, dynamic details) onSelected;

  const _LocationPickerSheet({
    required this.title,
    required this.isBoarding,
    required this.onSelected,
  });

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  bool _isLoadingCurrentLocation = false;
  String? _errorMessage;

  Future<void> _handleCurrentLocation() async {
    setState(() {
      _isLoadingCurrentLocation = true;
      _errorMessage = null;
    });

    try {
      final location = await LocationService.getCurrentLocation();
      widget.onSelected(location.description, location);
      if (mounted) {
        Navigator.pop(context);
      }
    } on PermissionException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      debugPrint('Technical failure in getCurrentLocation: $e');
      setState(() {
        _errorMessage = 'Unable to get your current location. Please try again or search manually.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCurrentLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF181818) : Colors.white;
    final primaryColor = isDark ? const Color(0xFFFFC400) : theme.colorScheme.primary;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.title,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          if (widget.isBoarding) ...[
            InkWell(
              onTap: _isLoadingCurrentLocation ? null : _handleCurrentLocation,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF202020) : const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.my_location_rounded,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Current Location',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    if (_isLoadingCurrentLocation)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: LocationAutocompleteField(
              fieldKey: widget.isBoarding ? 'home_boarding' : 'home_destination',
              hint: 'Search location...',
              icon: widget.isBoarding ? Icons.circle_outlined : Icons.location_on,
              iconColor: widget.isBoarding ? (isDark ? Colors.white : Colors.black) : primaryColor,
              onPlaceSelected: (prediction, details) async {
                widget.onSelected(prediction.description, details);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
