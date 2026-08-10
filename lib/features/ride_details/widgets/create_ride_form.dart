import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/location_autocomplete_field.dart';
import '../providers/create_ride_provider.dart';

class CreateRideForm extends ConsumerWidget {
  const CreateRideForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryColor = Color(0xFFF6C000);
    const blackColor = Color(0xFF121212);
    const mutedText = Color(0xFF6F6F72);
    const borderColor = Color(0xFFEAE5DD);
    const successColor = Color(0xFF2E7D32);
    const dangerColor = Color(0xFFD32F2F);

    final state = ref.watch(createRideProvider);
    final notifier = ref.read(createRideProvider.notifier);
    final isFemale = ref.watch(isUserFemaleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Boarding Location
        LocationAutocompleteField(
          fieldKey: 'create_ride_boarding',
          hint: 'Boarding location',
          icon: Icons.trip_origin,
          iconColor: successColor,
          onChanged: notifier.updateBoardingLocation,
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
        const SizedBox(height: 20),

        // Destination
        LocationAutocompleteField(
          fieldKey: 'create_ride_destination',
          hint: 'Destination',
          icon: Icons.location_on,
          iconColor: dangerColor,
          onChanged: notifier.updateDestinationLocation,
          onPlaceSelected: (prediction, details) async {
            notifier.updateDestinationLocation(prediction.description);
            notifier.updateDestinationDetails(
              placeId: details.placeId,
              address: details.address,
              lat: details.latitude,
              lng: details.longitude,
            );
          },
        ),
        const SizedBox(height: 20),

        // Date & Time
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Departure Date'),
                  const SizedBox(height: 8),
                  _DatePickerField(),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Departure Time'),
                  const SizedBox(height: 8),
                  _TimePickerField(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Seats & Fare
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Available Seats'),
                  const SizedBox(height: 8),
                  _SeatsStepper(),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Fare Per Seat'),
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
        const SizedBox(height: 20),

        // Girls Only Ride (Conditional)
        if (isFemale) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F5F3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: const Icon(Icons.female_outlined, color: blackColor, size: 20),
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
          const SizedBox(height: 20),
        ],

        // Vehicle & Driver Optional
        _SectionTitle(title: 'Vehicle Number (Optional)'),
        const SizedBox(height: 8),
        _RideTextField(
          hint: 'e.g. KA01AB1234',
          icon: Icons.directions_car_rounded,
          iconColor: blackColor,
          textCapitalization: TextCapitalization.characters,
          onChanged: notifier.updateVehicleNumber,
        ),
        const SizedBox(height: 20),

        _SectionTitle(title: 'Ride Description (Optional)'),
        const SizedBox(height: 8),
        _RideTextField(
          hint: 'e.g. No luggage, precise pickup point',
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF121212),
      ),
    );
  }
}

class _RideTextField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return TextFormField(
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF121212),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: const Color(0xFF9E9E9E),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 12),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEAE5DD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEAE5DD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF6C000), width: 2),
        ),
      ),
    );
  }
}

class _DatePickerField extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createRideProvider);
    final notifier = ref.read(createRideProvider.notifier);

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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAE5DD)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: Color(0xFF121212), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dateText,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: state.departureDate != null
                      ? const Color(0xFF121212)
                      : const Color(0xFF9E9E9E),
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
          final selectedDateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
          notifier.updateDepartureTime(selectedDateTime);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAE5DD)),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, color: Color(0xFF121212), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                timeText,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: state.departureTime != null
                      ? const Color(0xFF121212)
                      : const Color(0xFF9E9E9E),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE5DD)),
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
                color: const Color(0xFF121212),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onTap != null ? const Color(0xFFF6F5F3) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap != null ? const Color(0xFF121212) : const Color(0xFFD0D0D0),
        ),
      ),
    );
  }
}
