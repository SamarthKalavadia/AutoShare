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
import '../../../../shared/widgets/location_autocomplete_field.dart';
import '../../../../services/location_service.dart'
    show LocationService, PermissionException;
import 'home_page.dart' show homeNavigationProvider;

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryGreen = isDark
        ? const Color(0xFF10B981)
        : const Color(0xFF084E31);
    final heroHeaderColor = isDark
        ? const Color(0xFF0D2319)
        : const Color(0xFF084E31);
    final backgroundColor = isDark
        ? const Color(0xFF101714)
        : const Color(0xFFF6F9F7);
    final cardColor = isDark
        ? const Color(0xFF18221D)
        : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2D3F37)
        : const Color(0xFFE3EBE6);
    final textPrimary = isDark
        ? Colors.white
        : const Color(0xFF0F1713);
    final textSecondary = isDark
        ? const Color(0xFFA0B2AA)
        : const Color(0xFF6B7E75);
    final mintBg = isDark
        ? const Color(0xFF1B2F25)
        : const Color(0xFFF0F7F4);
    final mintBorder = isDark
        ? const Color(0xFF2E4D3D)
        : const Color(0xFFC4E3D4);
    final inputBg = isDark
        ? const Color(0xFF1F2D26)
        : const Color(0xFFF5F7F6);

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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP GREEN HERO BANNER
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: heroHeaderColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Greeting & Name with Logo
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/appicon.png',
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                greeting,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  letterSpacing: -0.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.name.isNotEmpty == true
                                    ? user!.name.split(' ').first
                                    : 'Sanidhya',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Right Actions: Notification Bell + Avatar
                      Row(
                        children: [
                          // Notification Button (Glass Circle)
                          GestureDetector(
                            onTap: () => context.push('/notifications'),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_none_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                Consumer(
                                  builder: (ctx, ref, _) {
                                    final count =
                                        ref.watch(unreadNotificationCountProvider);
                                    if (count == 0) return const SizedBox.shrink();
                                    return Positioned(
                                      right: -2,
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
                                            color: heroHeaderColor,
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
                          const SizedBox(width: 12),

                          // Avatar Circle (Coral / Orange Circle with Initial 'S')
                          GestureDetector(
                            onTap: () => context.push('/profile'),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD85A30), // Coral Avatar
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: getAvatarImageProvider(user?.profileImage) != null
                                    ? Image(
                                        image: getAvatarImageProvider(user!.profileImage)!,
                                        fit: BoxFit.cover,
                                        alignment: Alignment.center,
                                      )
                                    : Center(
                                        child: Text(
                                          user?.name.isNotEmpty == true
                                              ? user!.name[0].toUpperCase()
                                              : 'S',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // MAIN SEARCH CARD
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _animatedCard(
                duration: 500,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(28),
                    border: isDark
                        ? Border.all(color: borderColor, width: 1.1)
                        : null,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card Title
                      Text(
                        'Where to next?',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Stacked Inputs Container
                      InkWell(
                        onTap: () => _showLocationPicker(context, ref, 'boarding'),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor),
                          ),
                          child: Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Pickup Input Row
                                  InkWell(
                                    onTap: () => _showLocationPicker(
                                      context,
                                      ref,
                                      'boarding',
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.adjust_rounded,
                                            color: Color(0xFFE5A93C), // Gold Target
                                            size: 22,
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Text(
                                              searchState.boarding.isNotEmpty
                                                  ? searchState.boarding
                                                  : 'Enter pickup location',
                                              style: GoogleFonts.inter(
                                                fontSize: 15,
                                                fontWeight: searchState.boarding.isNotEmpty
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                                color: searchState.boarding.isNotEmpty
                                                    ? textPrimary
                                                    : textSecondary.withValues(alpha: 0.8),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.my_location_rounded,
                                              color: Color(0xFFE5A93C),
                                              size: 20,
                                            ),
                                            tooltip: 'Use current location',
                                            onPressed: () async {
                                              try {
                                                final loc =
                                                    await LocationService.getCurrentLocation();
                                                ref
                                                    .read(homeSearchProvider.notifier)
                                                    .updateBoarding(
                                                      loc.description,
                                                      placeId: loc.placeId,
                                                      address: loc.description,
                                                      lat: loc.latitude,
                                                      lng: loc.longitude,
                                                    );
                                              } catch (e) {
                                                if (context.mounted) {
                                                  _showValidationMessage(
                                                    context,
                                                    'Could not get current location.',
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Thin Horizontal Divider
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    indent: 16,
                                    endIndent: 60,
                                    color: borderColor,
                                  ),

                                  // Drop Input Row
                                  InkWell(
                                    onTap: () => _showLocationPicker(
                                      context,
                                      ref,
                                      'destination',
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(20),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            color: Color(0xFFE53935), // Red Pin
                                            size: 22,
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Text(
                                              searchState.destination.isNotEmpty
                                                  ? searchState.destination
                                                  : 'Enter drop location',
                                              style: GoogleFonts.inter(
                                                fontSize: 15,
                                                fontWeight: searchState.destination.isNotEmpty
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                                color: searchState.destination.isNotEmpty
                                                    ? textPrimary
                                                    : textSecondary.withValues(alpha: 0.8),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 48),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Floating Circular Swap Button
                              Positioned(
                                right: 14,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      final curB = searchState.boarding;
                                      final curD = searchState.destination;
                                      ref.read(homeSearchProvider.notifier).updateBoarding(curD);
                                      ref.read(homeSearchProvider.notifier).updateDestination(curB);
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF263730) : Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: borderColor),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.swap_vert_rounded,
                                        color: textPrimary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Selection Pills: Today & Seats
                      Row(
                        children: [
                          // Date Pill
                          Expanded(
                            child: _mintPillButton(
                              context: context,
                              icon: Icons.calendar_today_outlined,
                              label: searchState.departureDate == null
                                  ? 'Today'
                                  : DateFormat('MMM d').format(searchState.departureDate!),
                              mintBg: mintBg,
                              mintBorder: mintBorder,
                              primaryGreen: primaryGreen,
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

                          // Seat Pill
                          Expanded(
                            child: _mintPillButton(
                              context: context,
                              icon: Icons.event_seat_rounded,
                              label:
                                  '${searchState.passengers} ${searchState.passengers > 1 ? 'Seats' : 'Seat'}',
                              mintBg: mintBg,
                              mintBorder: mintBorder,
                              primaryGreen: primaryGreen,
                              onTap: () {
                                int p = searchState.passengers % 4 + 1;
                                ref.read(homeSearchProvider.notifier).updatePassengers(p);
                              },
                            ),
                          ),
                        ],
                      ),

                      if (isFemale) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: mintBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: mintBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.female_rounded,
                                size: 20,
                                color: primaryGreen,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Girls Only Ride',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              Switch.adaptive(
                                value: searchState.girlsOnly,
                                onChanged: (val) => ref
                                    .read(homeSearchProvider.notifier)
                                    .toggleGirlsOnly(val),
                                activeColor: primaryGreen,
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Solid Forest Green Find a Ride Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            if (searchState.boarding.isNotEmpty ||
                                searchState.destination.isNotEmpty) {
                              _handleCreateOrFindRideCTA(context, ref, searchState);
                            } else {
                              ref.read(homeNavigationProvider.notifier).setIndex(1);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 2,
                            shadowColor: primaryGreen.withValues(alpha: 0.3),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Find a Ride',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // QUICK ACTIONS
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Text(
                'Quick Actions',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.search_rounded,
                      label: 'Find Ride',
                      primaryColor: primaryGreen,
                      mintBg: mintBg,
                      borderColor: borderColor,
                      onTap: () {
                        ref.read(homeNavigationProvider.notifier).setIndex(1);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.directions_car_filled_rounded,
                      label: 'My Rides',
                      primaryColor: primaryGreen,
                      mintBg: mintBg,
                      borderColor: borderColor,
                      onTap: () => context.push('/my-rides'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.people_alt_rounded,
                      label: 'Drivers',
                      primaryColor: primaryGreen,
                      mintBg: mintBg,
                      borderColor: borderColor,
                      onTap: () => context.push('/driver-directory'),
                    ),
                  ),
                ],
              ),
            ),

            // ACTIVE RIDE SECTION
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Text(
                'Active Ride',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Consumer(
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
                            padding: const EdgeInsets.symmetric(
                              vertical: 32,
                              horizontal: 24,
                            ),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
                              border: isDark
                                  ? Border.all(color: borderColor, width: 1.1)
                                  : null,
                              boxShadow: isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
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
                                  color: textSecondary.withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'No active rides',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Your current or upcoming trips will appear here.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: textSecondary,
                                  ),
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
                          onTap: () =>
                              context.push('/ride-details', extra: ride),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
                              border: isDark
                                  ? Border.all(color: borderColor, width: 1.1)
                                  : null,
                              boxShadow: isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: mintBg,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: mintBorder),
                                      ),
                                      child: Text(
                                        'UPCOMING',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: primaryGreen,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      DateFormat(
                                        'MMM d, h:mm a',
                                      ).format(ride.departureTime),
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      Column(
                                        children: [
                                          const Icon(
                                            Icons.adjust_rounded,
                                            size: 14,
                                            color: Color(0xFFE5A93C),
                                          ),
                                          Expanded(
                                            child: Container(
                                              width: 2,
                                              color: borderColor,
                                              margin: const EdgeInsets.symmetric(
                                                vertical: 4,
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: Color(0xFFE53935),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ride.boardingLocation,
                                              style: GoogleFonts.inter(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 14),
                                            Text(
                                              ride.destination,
                                              style: GoogleFonts.inter(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Divider(height: 1, color: borderColor),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Consumer(
                                      builder: (ctx, ref, _) {
                                        final driverProfileAsync = ref.watch(
                                          userProfileProvider(ride.driverId),
                                        );
                                        final name =
                                            driverProfileAsync.value?.name ??
                                            'Driver';
                                        return Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 14,
                                              backgroundColor: mintBg,
                                              child: Icon(
                                                Icons.person,
                                                size: 16,
                                                color: primaryGreen,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              name,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: textPrimary,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    const Spacer(),
                                    Text(
                                      '₹${ride.farePerSeat.toInt()}',
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: primaryGreen,
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
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err')),
                  );
                },
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _mintPillButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color mintBg,
    required Color mintBorder,
    required Color primaryGreen,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: mintBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: mintBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: primaryGreen),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryGreen,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCreateOrFindRideCTA(
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

    // Switch to search tab or create ride with prefilled query
    ref.read(homeNavigationProvider.notifier).setIndex(1);
  }

  void _showValidationMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF084E31),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Okay',
          textColor: const Color(0xFFFFB800),
          onPressed: () {},
        ),
      ),
    );
  }

  void _showLocationPicker(BuildContext context, WidgetRef ref, String field) {
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
            ref
                .read(homeSearchProvider.notifier)
                .updateBoarding(
                  label,
                  placeId: details?.placeId,
                  address: details?.address,
                  lat: details?.latitude,
                  lng: details?.longitude,
                );
          } else {
            ref
                .read(homeSearchProvider.notifier)
                .updateDestination(
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
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.primaryColor,
    required this.mintBg,
    required this.borderColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color primaryColor;
  final Color mintBg;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF18221D) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: mintBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: -0.2,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
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
        _errorMessage =
            'Unable to get your current location. Please try again or search manually.';
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
    final backgroundColor = isDark ? const Color(0xFF18221D) : Colors.white;
    final primaryColor = isDark
        ? const Color(0xFF10B981)
        : const Color(0xFF084E31);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          if (widget.isBoarding) ...[
            InkWell(
              onTap: _isLoadingCurrentLocation ? null : _handleCurrentLocation,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1F2D26)
                      : const Color(0xFFF0F7F4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2E4D3D)
                        : const Color(0xFFC4E3D4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.my_location_rounded,
                      color: const Color(0xFFE5A93C),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Current Location',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
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
                style: GoogleFonts.inter(fontSize: 12, color: Colors.red),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: LocationAutocompleteField(
              fieldKey: widget.isBoarding
                  ? 'home_boarding'
                  : 'home_destination',
              hint: 'Search location...',
              icon: widget.isBoarding
                  ? Icons.adjust_rounded
                  : Icons.location_on,
              iconColor: widget.isBoarding
                  ? const Color(0xFFE5A93C)
                  : const Color(0xFFE53935),
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
