import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/location_autocomplete_field.dart';
import '../providers/create_ride_provider.dart';

class CreateRideForm extends ConsumerStatefulWidget {
  const CreateRideForm({super.key});

  @override
  ConsumerState<CreateRideForm> createState() => _CreateRideFormState();
}

class _CreateRideFormState extends ConsumerState<CreateRideForm> {
  bool _isSearchingBoarding = false;
  bool _isSearchingDestination = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = isDark
        ? const Color(0xFFFFC400)
        : theme.colorScheme.primary;
    final blackColor = isDark
        ? const Color(0xFFFFFFFF)
        : theme.colorScheme.onSurface;
    final cardColor = isDark ? const Color(0xFF181818) : Colors.white;
    final mutedText = isDark
        ? const Color(0xFFA1A1A1)
        : const Color(0xFF6F6F72);
    final borderColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFEAE5DD);
    final secondaryBg = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF6F5F3);

    final state = ref.watch(createRideProvider);
    final notifier = ref.read(createRideProvider.notifier);
    final isFemale = ref.watch(isUserFemaleProvider);
    final isSearching = _isSearchingBoarding || _isSearchingDestination;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MainSectionTitle(title: 'ROUTE'),
        // Boarding Location & Destination with Centered Swap Button
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
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
                    fieldKey: 'create_ride_boarding',
                    hint: 'Pickup location',
                    icon: Icons.radio_button_checked,
                    iconColor: primaryColor,
                    initialValue: state.boardingLocation,
                    showCurrentLocationButton: true,
                    transparentBackground: true,
                    onChanged: notifier.updateBoardingLocation,
                    onSuggestionsVisibilityChanged: (visible) {
                      if (_isSearchingBoarding != visible) {
                        setState(() => _isSearchingBoarding = visible);
                      }
                    },
                    onPlaceSelected: (prediction, details) async {
                      notifier.updateBoardingLocation(prediction.description);
                      notifier.updateBoardingDetails(
                        placeId: details.placeId,
                        address: details.address,
                        lat: details.latitude,
                        lng: details.longitude,
                      );
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
                    fieldKey: 'create_ride_destination',
                    hint: 'Dropoff location',
                    icon: Icons.location_on,
                    iconColor: isDark ? Colors.white : Colors.black87,
                    initialValue: state.destination,
                    showCurrentLocationButton: false,
                    transparentBackground: true,
                    onChanged: notifier.updateDestinationLocation,
                    onSuggestionsVisibilityChanged: (visible) {
                      if (_isSearchingDestination != visible) {
                        setState(() => _isSearchingDestination = visible);
                      }
                    },
                    onPlaceSelected: (prediction, details) async {
                      notifier.updateDestinationLocation(
                        prediction.description,
                      );
                      notifier.updateDestinationDetails(
                        placeId: details.placeId,
                        address: details.address,
                        lat: details.latitude,
                        lng: details.longitude,
                      );
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
        const SizedBox(height: 28),

        _MainSectionTitle(title: 'TRIP DETAILS'),
        // Date & Time
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(title: 'Departure Date'),
                  const SizedBox(height: 8),
                  _DatePickerField(),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(title: 'Departure Time'),
                  const SizedBox(height: 8),
                  _TimePickerField(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Seats & Fare
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(title: 'Available Seats'),
                  const SizedBox(height: 8),
                  _SeatsStepper(),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(title: 'Fare Per Seat'),
                  const SizedBox(height: 8),
                  _RideTextField(
                    hint: '0',
                    icon: Icons.currency_rupee_rounded,
                    iconColor: blackColor,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (val) {
                      notifier.updateFarePerSeat(double.tryParse(val) ?? 0.0);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Girls Only Ride (Conditional)
        if (isFemale) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: secondaryBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.female_outlined,
                    color: blackColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Girls Only Ride',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: blackColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Only verified female passengers can discover and request this ride.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: mutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch.adaptive(
                  value: state.isGirlsOnly,
                  onChanged: notifier.toggleGirlsOnly,
                  activeThumbColor: primaryColor,
                  activeTrackColor: primaryColor.withAlpha(180),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],

        _MainSectionTitle(title: 'ADDITIONAL DETAILS'),
        const _SectionTitle(title: 'Vehicle Number'),
        const SizedBox(height: 8),
        _RideTextField(
          hint: 'Enter vehicle number',
          icon: Icons.directions_car_outlined,
          iconColor: blackColor,
          textCapitalization: TextCapitalization.characters,
          onChanged: notifier.updateVehicleNumber,
        ),
        const SizedBox(height: 16),

        const _SectionTitle(title: 'Ride Description'),
        const SizedBox(height: 8),
        _RideTextField(
          hint: 'Add notes for passengers (optional)',
          icon: Icons.description_outlined,
          iconColor: blackColor,
          maxLines: 3,
          maxLength: 150,
          onChanged: notifier.updateRideDescription,
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

class _MainSectionTitle extends StatelessWidget {
  final String title;

  const _MainSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFA1A1A1)
              : const Color(0xFF6F6F72),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF121212),
        ),
      ),
    );
  }
}

class _RideTextField extends StatefulWidget {
  final String hint;
  final IconData icon;
  final Color iconColor;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;
  final TextCapitalization textCapitalization;

  const _RideTextField({
    required this.hint,
    required this.icon,
    required this.iconColor,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<_RideTextField> createState() => _RideTextFieldState();
}

class _RideTextFieldState extends State<_RideTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF181818) : Colors.white;
    final textColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF121212);
    final hintColor = isDark
        ? const Color(0xFF6F6F72)
        : const Color(0xFF9E9E9E);
    final borderColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFEAE5DD);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isFocused ? const Color(0xFFF6C000) : borderColor,
          width: _isFocused ? 2 : 1,
        ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 12, top: 16),
            child: Icon(widget.icon, color: widget.iconColor, size: 20),
          ),
          Expanded(
            child: TextFormField(
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              textCapitalization: widget.textCapitalization,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: GoogleFonts.inter(fontSize: 15, color: hintColor),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.only(
                  right: 16,
                  top: 16,
                  bottom: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerField extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createRideProvider);
    final notifier = ref.read(createRideProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF181818) : Colors.white;
    final textColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF121212);
    final hintColor = isDark
        ? const Color(0xFF6F6F72)
        : const Color(0xFF9E9E9E);
    final borderColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFEAE5DD);

    final dateText = state.departureDate != null
        ? DateFormat('MMM dd, yyyy').format(state.departureDate!)
        : 'Select Date';

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: state.departureDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );
        if (date != null) {
          notifier.updateDepartureDate(date);
        }
      },
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
          children: [
            Icon(Icons.calendar_month_rounded, color: textColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dateText,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: state.departureDate != null ? textColor : hintColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerField extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createRideProvider);
    final notifier = ref.read(createRideProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF181818) : Colors.white;
    final textColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF121212);
    final hintColor = isDark
        ? const Color(0xFF6F6F72)
        : const Color(0xFF9E9E9E);
    final borderColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFEAE5DD);

    final timeText = state.departureTime != null
        ? DateFormat('hh:mm a').format(state.departureTime!)
        : 'Select Time';

    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: state.departureTime != null
              ? TimeOfDay.fromDateTime(state.departureTime!)
              : TimeOfDay.now(),
        );
        if (time != null) {
          final now = DateTime.now();
          final selectedDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            time.hour,
            time.minute,
          );
          notifier.updateDepartureTime(selectedDateTime);
        }
      },
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
          children: [
            Icon(Icons.access_time_rounded, color: textColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                timeText,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: state.departureTime != null ? textColor : hintColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeatsStepper extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createRideProvider);
    final notifier = ref.read(createRideProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF181818) : Colors.white;
    final textColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF121212);
    final borderColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFEAE5DD);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            onTap: state.availableSeats > 1
                ? () => notifier.updateAvailableSeats(state.availableSeats - 1)
                : null,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              '${state.availableSeats}',
              key: ValueKey<int>(state.availableSeats),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            onTap: state.availableSeats < 4
                ? () => notifier.updateAvailableSeats(state.availableSeats + 1)
                : null,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnBg = isDark ? const Color(0xFF333333) : const Color(0xFFE8E8E8);
    final iconColorActive = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF121212);
    final iconColorInactive = isDark
        ? const Color(0xFF444444)
        : const Color(0xFFD0D0D0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onTap != null ? btnBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap != null ? iconColorActive : iconColorInactive,
        ),
      ),
    );
  }
}
