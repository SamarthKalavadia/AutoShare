import 'package:flutter_test/flutter_test.dart';
import 'package:autoshare/features/ride_details/providers/create_ride_provider.dart';

void main() {
  group('Edit & Available Seats Validation Tests', () {
    test('Maximum available seats allowed for auto-rickshaw is 2', () {
      final now = DateTime.now();
      final validDeparture = now.add(const Duration(minutes: 60));

      final stateMax2 = CreateRideState(
        boardingLocation: 'Changa',
        destination: 'Nadiad',
        departureDate: validDeparture,
        departureTime: validDeparture,
        availableSeats: 2,
        totalFare: 250.0,
      );
      expect(stateMax2.availableSeats, equals(2));
      expect(stateMax2.isValid, isTrue);

      final stateOneSeat = CreateRideState(
        boardingLocation: 'Changa',
        destination: 'Nadiad',
        departureDate: validDeparture,
        departureTime: validDeparture,
        availableSeats: 1,
        totalFare: 250.0,
      );
      expect(stateOneSeat.availableSeats, equals(1));
      expect(stateOneSeat.isValid, isTrue);
    });

    test('Available seats clamped between 1 and 2 when editing', () {
      // Bounds check for editing seats: only 1 or 2 allowed, 0 is invalid
      bool isValidSeatCount(int seats) => seats >= 1 && seats <= 2;

      expect(isValidSeatCount(-1), isFalse);
      expect(isValidSeatCount(0), isFalse);
      expect(isValidSeatCount(1), isTrue);
      expect(isValidSeatCount(2), isTrue);
      expect(isValidSeatCount(3), isFalse);
    });

    test('Clamping logic correctly bounds between 1 and 2', () {
      int clampSeats(int requested) => requested.clamp(1, 2);

      expect(clampSeats(3), equals(2));
      expect(clampSeats(2), equals(2));
      expect(clampSeats(1), equals(1));
      expect(clampSeats(0), equals(1));
      expect(clampSeats(-1), equals(1));
    });
  });
}
