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

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = theme.colorScheme.primary;
    final blackColor = theme.colorScheme.onSurface;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF));
    const successColor = Color(0xFF2E7D32);
    const dangerColor = Color(0xFFD32F2F);
    final mutedText = isDark ? Colors.white60 : const Color(0xFF6F6F72);
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFEAE5DD);
    final softShadow = BoxShadow(
      color: isDark ? const Color(0x33000000) : const Color(0x1A121212),
      blurRadius: 18,
      offset: const Offset(0, 8),
    );

    final user = ref.watch(authControllerProvider).value;
    final searchState = ref.watch(homeSearchProvider);
    final activeRideAsync = ref.watch(activeRideProvider);
    final isMale = user?.gender.toLowerCase() == 'male';

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
                      color: mutedText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.name.split(' ').first ?? 'Guest',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      color: blackColor,
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
                    color: cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(color: isDark ? const Color(0x33000000) : const Color(0x0F121212), blurRadius: 12),
                    ],
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: blackColor,
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
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4444),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: backgroundColor, width: 1.5),
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
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE7E4DF),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: getAvatarImageProvider(user?.profileImage) != null
                ? Image(
                    image: getAvatarImageProvider(user!.profileImage)!,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(color: blackColor, fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SingleChildScrollView(
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
                      'Share rides. Save money. Travel together.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _animatedCard(
                  duration: 500,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [softShadow],
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        _searchField(
                          label: 'Boarding Location',
                          icon: Icons.trip_origin,
                          color: successColor,
                          value: searchState.boarding.isEmpty ? 'Where from?' : searchState.boarding,
                          onTap: () => _showInputDialog(context, ref, 'boarding', searchState.boarding),
                        ),
                        const SizedBox(height: 12),
                        _searchField(
                          label: 'Destination',
                          icon: Icons.location_on,
                          color: dangerColor,
                          value: searchState.destination.isEmpty ? 'Where to?' : searchState.destination,
                          onTap: () => _showInputDialog(context, ref, 'destination', searchState.destination),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _searchField(
                                label: 'Departure Date',
                                icon: Icons.calendar_today_rounded,
                                color: blackColor,
                                value: searchState.departureDate == null
                                    ? 'Date'
                                    : DateFormat('MMM d').format(searchState.departureDate!),
                                compact: true,
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
                              child: _searchField(
                                label: 'Passengers',
                                icon: Icons.group_outlined,
                                color: blackColor,
                                value: '${searchState.passengers} seat${searchState.passengers > 1 ? 's' : ''}',
                                compact: true,
                                onTap: () {
                                  int p = searchState.passengers % 4 + 1;
                                  ref.read(homeSearchProvider.notifier).updatePassengers(p);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (!isMale)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF28282A) : const Color(0xFFF6F5F3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.female_outlined, size: 18, color: blackColor),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Girls Only Ride',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: blackColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Switch.adaptive(
                                  value: searchState.girlsOnly,
                                  onChanged: (val) => ref.read(homeSearchProvider.notifier).toggleGirlsOnly(val),
                                  activeThumbColor: primaryColor,
                                  activeTrackColor: primaryColor.withAlpha(180),
                                ),
                              ],
                            ),
                          ),
                        if (!isMale) const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: FilledButton(
                                  onPressed: () {
                                    // Search logic
                                    context.push('/search-ride');
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: blackColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    'Find Ride',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: FilledButton(
                                  onPressed: () {
                                    // Create logic
                                    context.push('/create-ride');
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: blackColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    'Create Ride',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
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
                const SizedBox(height: 26),
                Text(
                  'Quick Actions',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    color: blackColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.32,
                  children: [
                    _ActionCard(
                      icon: Icons.add_road,
                      label: 'Create Ride',
                      onTap: () => context.push('/create-ride'),
                    ),
                    _ActionCard(
                      icon: Icons.search_rounded,
                      label: 'Find Ride',
                      onTap: () => context.push('/search-ride'),
                    ),
                    _ActionCard(
                      icon: Icons.directions_car_rounded,
                      label: 'My Rides',
                      onTap: () => context.push('/my-rides'),
                    ),
                    _ActionCard(
                      icon: Icons.people_alt_rounded,
                      label: 'Driver Directory',
                      onTap: () => context.push('/driver-directory'),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Text(
                  'Active Ride',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    color: blackColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                activeRideAsync.when(
                  data: (activeRideData) {
                    if (activeRideData == null) {
                      return _animatedCard(
                        duration: 550,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [softShadow],
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F3E7),
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                child: const Icon(
                                  Icons.directions_car_rounded,
                                  size: 44,
                                  color: Color(0xFF121212),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'No active rides',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  color: blackColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: 180,
                                height: 48,
                                child: FilledButton(
                                  onPressed: () => context.push('/create-ride'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: blackColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    'Create Ride',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [softShadow],
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.trip_origin, size: 14, color: successColor),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Boarding',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: mutedText,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        ride.boardingLocation,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          color: blackColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4F4F4),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 18,
                                    color: blackColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: dangerColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    ride.destination,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: blackColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                _rideMeta(
                                  icon: Icons.access_time_rounded,
                                  label: DateFormat('MMM d, h:mm a').format(ride.departureTime),
                                ),
                                const SizedBox(width: 16),
                                _rideMeta(
                                  icon: Icons.event_seat_rounded,
                                  label: '${ride.availableSeats} seats left',
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                if (ride.isGirlsOnly)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAF5ED),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.shield_rounded, size: 14, color: successColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Girls Only',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: successColor,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const Spacer(),
                                Consumer(
                                  builder: (ctx, ref, _) {
                                    final driverProfileAsync =
                                        ref.watch(userProfileProvider(ride.driverId));
                                    final avg = driverProfileAsync.value?.averageRating ?? 0.0;
                                    if (avg == 0.0) return const SizedBox.shrink();
                                    return Row(
                                      children: [
                                        const Icon(Icons.star_rounded,
                                            size: 16, color: Color(0xFFF6C000)),
                                        const SizedBox(width: 4),
                                        Text(
                                          avg.toStringAsFixed(1),
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: blackColor,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F8F8),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Estimated Fare',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: mutedText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '₹${ride.farePerSeat.toInt()}',
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      color: blackColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: FilledButton(
                                onPressed: () {
                                  context.push('/ride-details', extra: ride);
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: blackColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  'View Ride',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => context.push('/create-ride'),
        backgroundColor: primaryColor,
        foregroundColor: blackColor,
        elevation: 6,
        tooltip: 'Create Ride',
        child: const Icon(Icons.add_road, size: 30),
      ),
    );
  }

  void _showInputDialog(BuildContext context, WidgetRef ref, String field, String initialValue) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Enter ${field == 'boarding' ? 'Boarding Location' : 'Destination'}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g. Indiranagar'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (field == 'boarding') {
                ref.read(homeSearchProvider.notifier).updateBoarding(controller.text);
              } else {
                ref.read(homeSearchProvider.notifier).updateDestination(controller.text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
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

  Widget _searchField({
    required String label,
    required IconData icon,
    required Color color,
    required String value,
    bool compact = false,
    VoidCallback? onTap,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final fieldBg = isDark ? const Color(0xFF28282A) : const Color(0xFFF8F8F8);
        final fieldBorder = isDark ? const Color(0xFF38383A) : const Color(0xFFEDE8E2);
        final textColor = theme.colorScheme.onSurface;
        final labelColor = isDark ? Colors.white60 : const Color(0xFF6E6E73);

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: compact ? 62 : 68,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: fieldBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: fieldBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withAlpha((255 * 0.10).round()),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: labelColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _rideMeta({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6E6E73)),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF4C4C4F),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
    final cardBg = theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFEAE5DD);
    final iconBg = isDark ? const Color(0xFF332D19) : const Color(0xFFF8F3E7);
    final textColor = theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
          boxShadow: [BoxShadow(color: isDark ? const Color(0x33000000) : const Color(0x0F121212), blurRadius: 12)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: isDark ? const Color(0xFFF6C000) : const Color(0xFF121212), size: 22),
              ),
              const Spacer(),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
