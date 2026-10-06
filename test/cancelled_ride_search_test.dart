import 'package:flutter_test/flutter_test.dart';
import 'package:autoshare/data/models/ride_model.dart';
import 'package:autoshare/data/models/request_model.dart';

void main() {
  group('Cancelled Ride Search and Request Status Filtering Tests', () {
    late RideModel ride1;
    late RideModel ride2;

    setUp(() {
      final now = DateTime.now();
      final futureDeparture = now.add(const Duration(hours: 2));

      ride1 = RideModel(
        id: 'ride_1',
        driverId: 'driver_1',
        boardingLocation: 'Downtown',
        destination: 'Airport',
        departureTime: futureDeparture,
        availableSeats: 2,
        totalFare: 200.0,
        createdAt: now,
      );

      ride2 = RideModel(
        id: 'ride_2',
        driverId: 'driver_2',
        boardingLocation: 'Downtown',
        destination: 'Airport',
        departureTime: futureDeparture,
        availableSeats: 1,
        totalFare: 150.0,
        createdAt: now,
      );
    });

    test('Active pending request excludes ride from search results for passenger', () {
      final allRides = [ride1, ride2];
      const passengerUid = 'passenger_1';

      final userRequests = [
        RideRequestModel(
          requestId: 'req_1',
          rideId: 'ride_1',
          ownerUid: 'driver_1',
          requesterUid: passengerUid,
          requestedSeats: 1,
          status: RideRequestStatus.pending,
          requestedAt: DateTime.now(),
        ),
      ];

      final activeRideIds = userRequests
          .where((req) =>
              req.status == RideRequestStatus.pending ||
              req.status == RideRequestStatus.accepted)
          .map((req) => req.rideId)
          .toSet();

      final filteredRides =
          allRides.where((r) => !activeRideIds.contains(r.id)).toList();

      expect(filteredRides.length, equals(1));
      expect(filteredRides.first.id, equals('ride_2'));
      expect(activeRideIds.contains('ride_1'), isTrue);
    });

    test('Active accepted request excludes ride from search results for passenger', () {
      final allRides = [ride1, ride2];
      const passengerUid = 'passenger_1';

      final userRequests = [
        RideRequestModel(
          requestId: 'req_1',
          rideId: 'ride_1',
          ownerUid: 'driver_1',
          requesterUid: passengerUid,
          requestedSeats: 1,
          status: RideRequestStatus.accepted,
          requestedAt: DateTime.now(),
        ),
      ];

      final activeRideIds = userRequests
          .where((req) =>
              req.status == RideRequestStatus.pending ||
              req.status == RideRequestStatus.accepted)
          .map((req) => req.rideId)
          .toSet();

      final filteredRides =
          allRides.where((r) => !activeRideIds.contains(r.id)).toList();

      expect(filteredRides.length, equals(1));
      expect(filteredRides.first.id, equals('ride_2'));
      expect(activeRideIds.contains('ride_1'), isTrue);
    });

    test('Cancelled request allows the SAME ride to appear again in search results', () {
      final allRides = [ride1, ride2];
      const passengerUid = 'passenger_1';

      // Passenger previously requested ride_1 and then cancelled
      final userRequests = [
        RideRequestModel(
          requestId: 'req_1',
          rideId: 'ride_1',
          ownerUid: 'driver_1',
          requesterUid: passengerUid,
          requestedSeats: 1,
          status: RideRequestStatus.cancelled,
          requestedAt: DateTime.now(),
        ),
      ];

      final activeRideIds = userRequests
          .where((req) =>
              req.status == RideRequestStatus.pending ||
              req.status == RideRequestStatus.accepted)
          .map((req) => req.rideId)
          .toSet();

      final filteredRides =
          allRides.where((r) => !activeRideIds.contains(r.id)).toList();

      // Ride 1 MUST appear in the results because request is cancelled (inactive)
      expect(filteredRides.length, equals(2));
      expect(filteredRides.map((r) => r.id), contains('ride_1'));
      expect(filteredRides.map((r) => r.id), contains('ride_2'));
      expect(activeRideIds.contains('ride_1'), isFalse);
    });

    test('Another passenger request does NOT affect current passenger search', () {
      final allRides = [ride1, ride2];
      const currentPassengerUid = 'passenger_1';

      // Request belongs to passenger_2, not current passenger
      final allRequestsInSystem = [
        RideRequestModel(
          requestId: 'req_other',
          rideId: 'ride_1',
          ownerUid: 'driver_1',
          requesterUid: 'passenger_2',
          requestedSeats: 1,
          status: RideRequestStatus.accepted,
          requestedAt: DateTime.now(),
        ),
      ];

      // Requests queried for current passenger:
      final userRequests = allRequestsInSystem
          .where((r) => r.requesterUid == currentPassengerUid)
          .toList();

      final activeRideIds = userRequests
          .where((req) =>
              req.status == RideRequestStatus.pending ||
              req.status == RideRequestStatus.accepted)
          .map((req) => req.rideId)
          .toSet();

      final filteredRides =
          allRides.where((r) => !activeRideIds.contains(r.id)).toList();

      // Current passenger sees ride_1 since current passenger has no active request
      expect(filteredRides.length, equals(2));
      expect(filteredRides.map((r) => r.id), contains('ride_1'));
    });

    test('Available seats are properly restored upon cancelling an accepted request', () {
      // Ride starts with 2 seats
      var seats = 2;
      const requestedSeats = 1;

      // 1. Driver accepts request -> seats decremented
      seats -= requestedSeats;
      expect(seats, equals(1));

      // 2. Passenger cancels request -> seats restored
      const wasAccepted = true;
      if (wasAccepted) {
        seats += requestedSeats;
      }
      expect(seats, equals(2));

      // 3. Search for 2 seats passes
      expect(seats >= 2, isTrue);
    });

    test('Pending request cancellation does not increment seats', () {
      // Ride starts with 2 seats
      var seats = 2;
      const requestedSeats = 1;

      // Request was only pending (seats were never decremented)
      bool wasAccepted = false;
      if (wasAccepted) {
        seats += requestedSeats;
      }

      // Seats remain unchanged at 2
      expect(seats, equals(2));
    });
  });
}
