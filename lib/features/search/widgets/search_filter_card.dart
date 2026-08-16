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
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFEAE5DD);
    const successColor = Color(0xFF2E7D32);
    const dangerColor = Color(0xFFD32F2F);
    final mutedText = isDark ? Colors.white60 : const Color(0xFF6F6F72);
    final cardBg = theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    final state = ref.watch(searchRideProvider);
    final notifier = ref.read(searchRideProvider.notifier);
    
    final authState = ref.watch(authControllerProvider);
    final isFemale = authState.value?.gender.toLowerCase() == 'female';
    final isSearching = _isSearchingBoarding || _isSearchingDestination;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: borderColor, width: 1.1) : null,
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Boarding Location & Destination with Swap Button
          Stack(
            alignment: Alignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocationAutocompleteField(
                    fieldKey: 'search_boarding',
                    hint: 'Pickup location',
                    icon: Icons.circle_outlined,
                    iconColor: blackColor,
                    initialValue: state.boardingLocation,
                    showCurrentLocationButton: true,
                    onSuggestionsVisibilityChanged: (visible) {
                      if (_isSearchingBoarding != visible) {
                        setState(() => _isSearchingBoarding = visible);
                      }
                    },
                    onPlaceSelected: (prediction, details) async {
                      notifier.updateBoardingLocation(prediction.description);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: Container(
                      height: 12,
                      width: 2,
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                  ),
                  LocationAutocompleteField(
                    fieldKey: 'search_destination',
                    hint: 'Dropoff location',
                    icon: Icons.location_on,
                    iconColor: primaryColor,
                    initialValue: state.destination,
                    showCurrentLocationButton: false,
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
              // Center-aligned Swap Button - Automatically hidden when searching suggestions to prevent overlap
              if (!isSearching)
                Align(
                  alignment: Alignment.center,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => notifier.swapLocations(),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(35),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.swap_vert_rounded,
                          color: Color(0xFF121212),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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
                      notifier.updateDepartureTime(DateTime(now.year, now.month, now.day, time.hour, time.minute));
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
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: mutedText),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF28282A) : const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StepperButton(
                            icon: Icons.remove,
                            onTap: state.requiredSeats > 1
                                ? () => notifier.updateRequiredSeats(state.requiredSeats - 1)
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
                                ? () => notifier.updateRequiredSeats(state.requiredSeats + 1)
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
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: mutedText),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: primaryColor,
                        inactiveTrackColor: isDark ? const Color(0xFF38383A) : const Color(0xFFEAE5DD),
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
                color: isDark ? const Color(0xFF28282A) : const Color(0xFFF3F3F3),
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
                      'Girls Only Rides',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: blackColor,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: state.isGirlsOnly,
                    onChanged: notifier.toggleGirlsOnly,
                    activeColor: primaryColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Search Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: state.isValid && !state.isLoading ? () => notifier.searchRides() : null,
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: const Color(0xFF121212),
                disabledBackgroundColor: isDark ? const Color(0xFF38383A) : primaryColor.withValues(alpha: 0.4),
                disabledForegroundColor: isDark ? Colors.white38 : blackColor.withValues(alpha: 0.5),
              ),
              child: state.isLoading 
                  ? const SizedBox(
                      width: 24, 
                      height: 24, 
                      child: CircularProgressIndicator(color: Color(0xFF121212), strokeWidth: 2.5),
                    )
                  : const Text('Search Rides'),
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
    final selectorBg = isDark ? const Color(0xFF28282A) : const Color(0xFFF3F3F3);
    final textColor = theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selectorBg,
          borderRadius: BorderRadius.circular(16),
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
              ? [BoxShadow(color: isDark ? const Color(0x33000000) : const Color(0x0F000000), blurRadius: 4, offset: const Offset(0, 2))]
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
