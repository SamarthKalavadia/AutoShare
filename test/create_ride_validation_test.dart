import 'package:flutter_test/flutter_test.dart';
import 'package:autoshare/features/ride_details/providers/create_ride_provider.dart';

void main() {
  group('CreateRideState Validation Tests', () {
    test('Rejects fare <= 0', () {
      final now = DateTime.now();
      final validDeparture = now.add(const Duration(minutes: 60));

      final stateZeroFare = CreateRideState(
        boardingLocation: 'Point A',
        destination: 'Point B',
        departureDate: validDeparture,
        departureTime: validDeparture,
        availableSeats: 1,
        totalFare: 0.0,
      );
      expect(stateZeroFare.validationError, equals('Enter a fare greater than ₹0.'));

      final stateNegativeFare = CreateRideState(
        boardingLocation: 'Point A',
        destination: 'Point B',
        departureDate: validDeparture,
        departureTime: validDeparture,
        availableSeats: 1,
        totalFare: -50.0,
      );
      expect(stateNegativeFare.validationError, equals('Enter a fare greater than ₹0.'));
    });

    test('Rejects fare > 9999', () {
      final now = DateTime.now();
      final validDeparture = now.add(const Duration(minutes: 60));

      final stateOverflowFare = CreateRideState(
        boardingLocation: 'Point A',
        destination: 'Point B',
        departureDate: validDeparture,
        departureTime: validDeparture,
        availableSeats: 1,
        totalFare: 10000.0,
      );
      expect(stateOverflowFare.validationError, equals('Total fare cannot exceed ₹9,999'));
    });

    test('Rejects past departure time', () {
      final now = DateTime.now();
      final pastDeparture = now.subtract(const Duration(minutes: 10));

      final state = CreateRideState(
        boardingLocation: 'Point A',
        destination: 'Point B',
        departureDate: pastDeparture,
        departureTime: pastDeparture,
        availableSeats: 1,
        totalFare: 100.0,
      );
      expect(state.validationError, equals('Departure time cannot be in the past'));
    });

    test('Rejects departure time within 45 minutes of now', () {
      final now = DateTime.now();
      final soonDeparture = now.add(const Duration(minutes: 30));

      final state = CreateRideState(
        boardingLocation: 'Point A',
        destination: 'Point B',
        departureDate: soonDeparture,
        departureTime: soonDeparture,
        availableSeats: 1,
        totalFare: 100.0,
      );
      expect(state.validationError, equals('Rides must be created at least 45 minutes before departure.'));
    });

    test('Accepts valid departure time (>= 45 min in future) and valid fare (> 0)', () {
      final now = DateTime.now();
      final validDeparture = now.add(const Duration(minutes: 50));

      final state = CreateRideState(
        boardingLocation: 'Point A',
        destination: 'Point B',
        departureDate: validDeparture,
        departureTime: validDeparture,
        availableSeats: 1,
        totalFare: 150.0,
      );
      expect(state.validationError, isNull);
      expect(state.isValid, isTrue);
    });

    test('Fare per person calculation: totalFare split equally', () {
      final now = DateTime.now();
      final validDeparture = now.add(const Duration(minutes: 60));

      final state = CreateRideState(
        boardingLocation: 'Point A',
        destination: 'Point B',
        departureDate: validDeparture,
        departureTime: validDeparture,
        availableSeats: 2,
        totalFare: 180.0,
      );

      // No passengers accepted yet: fare per person = 180 / 1 = 180
      expect(state.totalFare, equals(180.0));
      expect(state.isValid, isTrue);
    });
  });
}
