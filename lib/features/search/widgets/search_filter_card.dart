import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/search_ride_provider.dart';
import '../../../shared/widgets/location_autocomplete_field.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

class SearchFilterCard extends ConsumerStatefulWidget {
  const SearchFilterCard({super.key});

  @override
  ConsumerState<SearchFilterCard> createState() => _SearchFilterCardState();
}

class _SearchFilterCardState extends ConsumerState<SearchFilterCard> {
  bool _isSearchingBoarding = false;
  bool _isSearchingDestination = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryGreen = isDark
        ? const Color(0xFF10B981)
        : const Color(0xFF084E31);
    final blackColor = theme.colorScheme.onSurface;
    final borderColor = isDark
        ? const Color(0xFF2D3F37)
        : const Color(0xFFE3EBE6);
    final mutedText = isDark ? const Color(0xFFA0B2AA) : const Color(0xFF6B7E75);

    final state = ref.watch(searchRideProvider);
    final notifier = ref.read(searchRideProvider.notifier);

    final authState = ref.watch(authControllerProvider);
    final isFemale = authState.value?.gender.toLowerCase() == 'female';
    final isSearching = _isSearchingBoarding || _isSearchingDestination;

    final cardColor = isDark ? const Color(0xFF18221D) : Colors.white;
    final secondaryBg = isDark
        ? const Color(0xFF1F2D26)
        : const Color(0xFFF0F7F4);
    final mintBorder = isDark
        ? const Color(0xFF2E4D3D)
        : const Color(0xFFC4E3D4);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Boarding Location & Destination with Swap Button
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
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
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned(
                  left: 25,
                  top: 40,
                  bottom: 40,
                  child: Container(
                    width: 1.5,
                    color: isDark
                        ? const Color(0xFF2D3F37)
                        : const Color(0xFFE3EBE6),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocationAutocompleteField(
                      fieldKey: 'search_boarding',
                      hint: 'Pickup location',
                      icon: Icons.adjust_rounded,
                      iconColor: const Color(0xFFE5A93C), // Gold Target
                      initialValue: state.boardingLocation,
                      showCurrentLocationButton: true,
                      transparentBackground: true,
                      onSuggestionsVisibilityChanged: (visible) {
                        if (_isSearchingBoarding != visible) {
                          setState(() => _isSearchingBoarding = visible);
                        }
                      },
                      onPlaceSelected: (prediction, details) async {
                        notifier.updateBoardingLocation(prediction.description);
                      },
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      indent: 52,
                      endIndent: 68,
                      color: borderColor,
                    ),
                    const SizedBox(height: 12),
                    LocationAutocompleteField(
                      fieldKey: 'search_destination',
                      hint: 'Dropoff location',
                      icon: Icons.location_on,
                      iconColor: const Color(0xFFE53935), // Red Pin
                      initialValue: state.destination,
                      showCurrentLocationButton: false,
                      transparentBackground: true,
                      onSuggestionsVisibilityChanged: (visible) {
                        if (_isSearchingDestination != visible) {
                          setState(() => _isSearchingDestination = visible);
                        }
                      },
                      onPlaceSelected: (prediction, details) async {
                        notifier.updateDestination(prediction.description);
                      },
                    ),
                  ],
                ),
                // Right-aligned Swap Button
                if (!isSearching)
                  Positioned(
                    right: 16,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => notifier.swapLocations(),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: secondaryBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: mintBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.swap_vert_rounded,
                            color: primaryGreen,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Date and Time
          Row(
            children: [
              Expanded(
                child: _DateTimeSelector(
                  icon: Icons.calendar_today_outlined,
                  text: state.departureDate != null
                      ? DateFormat('MMM dd').format(state.departureDate!)
                      : 'Date',
                  mintBg: secondaryBg,
                  mintBorder: mintBorder,
                  primaryColor: primaryGreen,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: state.departureDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) notifier.updateDepartureDate(date);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateTimeSelector(
                  icon: Icons.access_time_rounded,
                  text: state.departureTime != null
                      ? DateFormat('hh:mm a').format(state.departureTime!)
                      : 'Time',
                  mintBg: secondaryBg,
                  mintBorder: mintBorder,
                  primaryColor: primaryGreen,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: state.departureTime != null
                          ? TimeOfDay.fromDateTime(state.departureTime!)
                          : TimeOfDay.now(),
                    );
                    if (time != null) {
                      final now = DateTime.now();
                      notifier.updateDepartureTime(
                        DateTime(
                          now.year,
                          now.month,
                          now.day,
                          time.hour,
                          time.minute,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Required Seats and Max Fare
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Required Seats',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: mutedText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StepperButton(
                            icon: Icons.remove,
                            primaryColor: primaryGreen,
                            mintBg: secondaryBg,
                            onTap: state.requiredSeats > 1
                                ? () => notifier.updateRequiredSeats(
                                    state.requiredSeats - 1,
                                  )
                                : null,
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              '${state.requiredSeats}',
                              key: ValueKey(state.requiredSeats),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: blackColor,
                              ),
                            ),
                          ),
                          _StepperButton(
                            icon: Icons.add,
                            primaryColor: primaryGreen,
                            mintBg: secondaryBg,
                            onTap: state.requiredSeats < 4
                                ? () => notifier.updateRequiredSeats(
                                    state.requiredSeats + 1,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Max Fare (₹${state.maxFare.toInt()})',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: mutedText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: primaryGreen,
                          inactiveTrackColor: isDark
                              ? const Color(0xFF263730)
                              : const Color(0xFFE3EBE6),
                          thumbColor: primaryGreen,
                          overlayColor: primaryGreen.withValues(alpha: 0.2),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: state.maxFare,
                          min: 50,
                          max: 1000,
                          divisions: 19,
                          onChanged: (val) => notifier.updateMaxFare(val),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Girls Only Toggle
          if (isFemale) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: secondaryBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: mintBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.female_rounded,
                    size: 20,
                    color: primaryGreen,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Girls Only Rides',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: blackColor,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: state.isGirlsOnly,
                    onChanged: notifier.toggleGirlsOnly,
                    activeColor: primaryGreen,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Search Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: state.isValid && !state.isLoading
                  ? () => notifier.searchRides()
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: state.isValid ? 3 : 0,
              ),
              child: state.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Search Rides',
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
    );
  }
}

class _DateTimeSelector extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color mintBg;
  final Color mintBorder;
  final Color primaryColor;
  final VoidCallback onTap;

  const _DateTimeSelector({
    required this.icon,
    required this.text,
    required this.mintBg,
    required this.mintBorder,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: mintBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: mintBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: primaryColor,
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
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final Color primaryColor;
  final Color mintBg;
  final VoidCallback? onTap;

  const _StepperButton({
    required this.icon,
    required this.primaryColor,
    required this.mintBg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = mintBg;
    final activeIconColor = primaryColor;
    final disabledIconColor = isDark ? Colors.white24 : const Color(0xFFD0D0D0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onTap != null ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? activeIconColor : disabledIconColor,
        ),
      ),
    );
  }
}
