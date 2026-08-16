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

    const primaryColor = Color(0xFFF6C000);
    final blackColor = theme.colorScheme.onSurface;
    final borderColor = isDark
        ? const Color(0xFF333333)
        : const Color(0xFFEAE5DD);
    final mutedText = isDark ? Colors.white60 : const Color(0xFF6F6F72);

    final state = ref.watch(searchRideProvider);
    final notifier = ref.read(searchRideProvider.notifier);

    final authState = ref.watch(authControllerProvider);
    final isFemale = authState.value?.gender.toLowerCase() == 'female';
    final isSearching = _isSearchingBoarding || _isSearchingDestination;

    final cardColor = isDark ? const Color(0xFF181818) : Colors.white;
    final secondaryBg = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF6F5F3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Boarding Location & Destination with Swap Button
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
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
                        ? const Color(0xFF333333)
                        : const Color(0xFFE0E0E0),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocationAutocompleteField(
                      fieldKey: 'search_boarding',
                      hint: 'Pickup location',
                      icon: Icons.radio_button_checked,
                      iconColor: primaryColor,
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
                    const SizedBox(height: 16),
                    Divider(
                      height: 1,
                      indent: 52,
                      endIndent: 68,
                      color: isDark
                          ? const Color(0xFF333333)
                          : const Color(0xFFE0E0E0),
                    ),
                    const SizedBox(height: 16),
                    LocationAutocompleteField(
                      fieldKey: 'search_destination',
                      hint: 'Dropoff location',
                      icon: Icons.location_on,
                      iconColor: isDark ? Colors.white : Colors.black87,
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
                            border: Border.all(color: borderColor),
                          ),
                          child: Icon(
                            Icons.swap_vert_rounded,
                            color: blackColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Date and Time
          Row(
            children: [
              Expanded(
                child: _DateTimeSelector(
                  icon: Icons.calendar_month_rounded,
                  text: state.departureDate != null
                      ? DateFormat('MMM dd').format(state.departureDate!)
                      : 'Date',
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
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: mutedText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withAlpha(5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StepperButton(
                            icon: Icons.remove,
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
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: blackColor,
                              ),
                            ),
                          ),
                          _StepperButton(
                            icon: Icons.add,
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
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: mutedText,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withAlpha(5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: primaryColor,
                          inactiveTrackColor: isDark
                              ? const Color(0xFF38383A)
                              : const Color(0xFFEAE5DD),
                          thumbColor: primaryColor,
                          overlayColor: primaryColor.withValues(alpha: 0.2),
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
          if (isFemale)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.female_rounded,
                      size: 18,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Girls Only Rides',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: blackColor,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: state.isGirlsOnly,
                    onChanged: notifier.toggleGirlsOnly,
                    activeTrackColor: primaryColor,
                  ),
                ],
              ),
            ),
          if (isFemale) const SizedBox(height: 24),

          // Search Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: state.isValid && !state.isLoading
                  ? () => notifier.searchRides()
                  : null,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: state.isValid ? 4 : 0,
              ),
              child: state.isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      'Search Rides',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
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
  final VoidCallback onTap;

  const _DateTimeSelector({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF181818) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFEAE5DD);
    final textColor = theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Text(
              text,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? const Color(0xFF38383A) : Colors.white;
    final activeIconColor = isDark ? Colors.white : const Color(0xFF121212);
    final disabledIconColor = isDark ? Colors.white30 : const Color(0xFFD0D0D0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: onTap != null ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: isDark
                        ? const Color(0x33000000)
                        : const Color(0x0F000000),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
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
