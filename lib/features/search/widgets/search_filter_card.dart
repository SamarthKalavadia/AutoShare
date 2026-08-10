import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/search_ride_provider.dart';
import '../../../shared/widgets/location_autocomplete_field.dart';

class SearchFilterCard extends ConsumerWidget {
  const SearchFilterCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x33000000) : const Color(0x0F121212),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Boarding Location
          LocationAutocompleteField(
            fieldKey: 'search_boarding',
            hint: 'Where from?',
            icon: Icons.trip_origin,
            iconColor: successColor,
            onPlaceSelected: (prediction, details) async {
              notifier.updateBoardingLocation(prediction.description);
            },
          ),
          const SizedBox(height: 16),
          
          // Destination
          LocationAutocompleteField(
            fieldKey: 'search_destination',
            hint: 'Where to?',
            icon: Icons.location_on,
            iconColor: dangerColor,
            onPlaceSelected: (prediction, details) async {
              notifier.updateDestination(prediction.description);
            },
          ),
          const SizedBox(height: 20),

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
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: mutedText),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF28282A) : const Color(0xFFF6F5F3),
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
                              style: GoogleFonts.inter(
                                fontSize: 16,
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
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: mutedText),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: primaryColor,
                        inactiveTrackColor: isDark ? const Color(0xFF38383A) : const Color(0xFFEAE5DD),
                        thumbColor: primaryColor,
                        overlayColor: primaryColor.withAlpha(50),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF28282A) : const Color(0xFFF6F5F3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.female_outlined, color: Color(0xFFD81B60), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Girls Only Rides',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: blackColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: state.isGirlsOnly,
                  onChanged: notifier.toggleGirlsOnly,
                  activeThumbColor: const Color(0xFFD81B60),
                  activeTrackColor: const Color(0xFFD81B60).withAlpha(100),
                  inactiveTrackColor: borderColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Search Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: state.isValid && !state.isLoading ? () => notifier.searchRides() : null,
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: const Color(0xFF121212),
                disabledBackgroundColor: isDark ? const Color(0xFF38383A) : primaryColor.withAlpha(100),
                disabledForegroundColor: isDark ? Colors.white38 : blackColor.withAlpha(120),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: state.isValid ? 4 : 0,
              ),
              child: state.isLoading 
                  ? const SizedBox(
                      width: 24, 
                      height: 24, 
                      child: CircularProgressIndicator(color: Color(0xFF121212), strokeWidth: 2.5),
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
    final selectorBg = isDark ? const Color(0xFF28282A) : const Color(0xFFF6F5F3);
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
              style: GoogleFonts.inter(
                fontSize: 14,
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
