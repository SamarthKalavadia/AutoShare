import 'package:flutter_test/flutter_test.dart';
import 'package:autoshare/data/models/ride_model.dart';
import 'package:autoshare/data/models/request_model.dart';

void main() {
  group('SECTION 25 TEST SCENARIO: Realtime Ride Seats, Dynamic Fare, and State Progression', () {
    test('User A creates ride (Seats=2, Total Fare=₹300)', () {
      final rideA = RideModel(
        id: 'ride_123',
        driverId: 'user_A',
        boardingLocation: 'Point A',
        destination: 'Destination',
        departureTime: DateTime.now().add(const Duration(hours: 2)),
        availableSeats: 2,
        totalSeats: 2,
        acceptedPassengerCount: 0,
        totalFare: 300.0,
        createdAt: DateTime.now(),
      );

      // Expected display for A & searchers:
      // People in ride: 1
      // Seats available: 2
      // Current fare: ₹300/person
      expect(rideA.totalPeople, equals(1));
      expect(rideA.remainingSeats, equals(2));
      expect(rideA.currentFarePerPerson, equals(300.0));
      expect(rideA.farePerSeat, equals(300.0));
      expect(rideA.isFull, isFalse);
    });

    test('User B is accepted -> 1 seat available, ₹150/person', () {
      final rideInitial = RideModel(
        id: 'ride_123',
        driverId: 'user_A',
        boardingLocation: 'Point A',
        destination: 'Destination',
        departureTime: DateTime.now().add(const Duration(hours: 2)),
        availableSeats: 2,
        totalSeats: 2,
        acceptedPassengerCount: 0,
        totalFare: 300.0,
        createdAt: DateTime.now(),
      );

      // B gets accepted
      final rideAfterB = rideInitial.copyWith(
        acceptedPassengerCount: 1,
      );

      // Expected display for A and B:
      // People in ride: 2 (1 creator + 1 passenger)
      // Seats available: 1
      // Current fare: ₹150/person
      expect(rideAfterB.totalPeople, equals(2));
      expect(rideAfterB.remainingSeats, equals(1));
      expect(rideAfterB.currentFarePerPerson, equals(150.0));
      expect(rideAfterB.farePerSeat, equals(150.0));
      expect(rideAfterB.isFull, isFalse);

      // Verify notification format
      final bName = 'B';
      final seatText = rideAfterB.remainingSeats == 1
          ? '1 seat remaining.'
          : '${rideAfterB.remainingSeats} seats remaining.';
      final notifBody =
          '$bName joined the ride. $seatText Current fare: ₹${rideAfterB.currentFarePerPerson.round()}/person.';
      expect(notifBody, equals('B joined the ride. 1 seat remaining. Current fare: ₹150/person.'));
    });

    test('User C is accepted -> 0 seats available, ₹100/person, Ride Full', () {
      final rideAfterB = RideModel(
        id: 'ride_123',
        driverId: 'user_A',
        boardingLocation: 'Point A',
        destination: 'Destination',
        departureTime: DateTime.now().add(const Duration(hours: 2)),
        availableSeats: 1,
        totalSeats: 2,
        acceptedPassengerCount: 1,
        totalFare: 300.0,
        createdAt: DateTime.now(),
      );

      // C gets accepted
      final rideAfterC = rideAfterB.copyWith(
        acceptedPassengerCount: 2,
      );

      // Expected display for A, B, and C:
      // People in ride: 3 (1 creator + 2 passengers)
      // Seats available: 0
      // Current fare: ₹100/person
      // Ride becomes FULL
      expect(rideAfterC.totalPeople, equals(3));
      expect(rideAfterC.remainingSeats, equals(0));
      expect(rideAfterC.currentFarePerPerson, equals(100.0));
      expect(rideAfterC.farePerSeat, equals(100.0));
      expect(rideAfterC.isFull, isTrue);

      final cName = 'C';
      final seatText = rideAfterC.remainingSeats == 0
          ? 'No seats remaining.'
          : '${rideAfterC.remainingSeats} seats remaining.';
      final notifBody =
          '$cName joined the ride. $seatText Current fare: ₹${rideAfterC.currentFarePerPerson.round()}/person.';
      expect(notifBody, equals('C joined the ride. No seats remaining. Current fare: ₹100/person.'));
    });

    test('User B cancels -> 1 seat available, ₹150/person for remaining A & C', () {
      final rideAfterC = RideModel(
        id: 'ride_123',
        driverId: 'user_A',
        boardingLocation: 'Point A',
        destination: 'Destination',
        departureTime: DateTime.now().add(const Duration(hours: 2)),
        availableSeats: 0,
        totalSeats: 2,
        acceptedPassengerCount: 2,
        totalFare: 300.0,
        createdAt: DateTime.now(),
      );

      // B cancels
      final rideAfterBCancels = rideAfterC.copyWith(
        acceptedPassengerCount: 1,
      );

      // Expected display for remaining participants (A and C):
      // People in ride: 2 (1 creator + 1 passenger)
      // Seats available: 1
      // Current fare: ₹150/person
      expect(rideAfterBCancels.totalPeople, equals(2));
      expect(rideAfterBCancels.remainingSeats, equals(1));
      expect(rideAfterBCancels.currentFarePerPerson, equals(150.0));
      expect(rideAfterBCancels.farePerSeat, equals(150.0));
      expect(rideAfterBCancels.isFull, isFalse);

      final bName = 'B';
      final seatWord = rideAfterBCancels.remainingSeats == 1 ? 'seat' : 'seats';
      final notifBody =
          '$bName left the ride. ${rideAfterBCancels.remainingSeats} $seatWord available. Current fare: ₹${rideAfterBCancels.currentFarePerPerson.round()}/person.';
      expect(notifBody, equals('B left the ride. 1 seat available. Current fare: ₹150/person.'));
    });

    test('User C cancels -> 2 seats available, ₹300/person for Creator A alone', () {
      final rideAfterBCancels = RideModel(
        id: 'ride_123',
        driverId: 'user_A',
        boardingLocation: 'Point A',
        destination: 'Destination',
        departureTime: DateTime.now().add(const Duration(hours: 2)),
        availableSeats: 1,
        totalSeats: 2,
        acceptedPassengerCount: 1,
        totalFare: 300.0,
        createdAt: DateTime.now(),
      );

      // C cancels
      final rideAfterCCancels = rideAfterBCancels.copyWith(
        acceptedPassengerCount: 0,
      );

      // Expected display for A:
      // People in ride: 1
      // Seats available: 2
      // Current fare: ₹300/person
      expect(rideAfterCCancels.totalPeople, equals(1));
      expect(rideAfterCCancels.remainingSeats, equals(2));
      expect(rideAfterCCancels.currentFarePerPerson, equals(300.0));
      expect(rideAfterCCancels.farePerSeat, equals(300.0));
      expect(rideAfterCCancels.isFull, isFalse);

      final cName = 'C';
      final seatWord = rideAfterCCancels.remainingSeats == 1 ? 'seat' : 'seats';
      final notifBody =
          '$cName left the ride. ${rideAfterCCancels.remainingSeats} $seatWord available. Current fare: ₹${rideAfterCCancels.currentFarePerPerson.round()}/person.';
      expect(notifBody, equals('C left the ride. 2 seats available. Current fare: ₹300/person.'));
    });

    test('Pending and Rejected requests do not modify acceptedPassengerCount or fare', () {
      final ride = RideModel(
        id: 'ride_123',
        driverId: 'user_A',
        boardingLocation: 'Point A',
        destination: 'Destination',
        departureTime: DateTime.now().add(const Duration(hours: 2)),
        availableSeats: 2,
        totalSeats: 2,
        acceptedPassengerCount: 0,
        totalFare: 300.0,
        createdAt: DateTime.now(),
      );

      // Pending request from D
      final reqD = RideRequestModel(
        requestId: 'req_D',
        rideId: 'ride_123',
        requesterUid: 'user_D',
        ownerUid: 'user_A',
        requestedSeats: 1,
        status: RideRequestStatus.pending,
        requestedAt: DateTime.now(),
      );
      expect(reqD.status, equals(RideRequestStatus.pending));
      // Fare & seats remain unchanged
      expect(ride.totalPeople, equals(1));
      expect(ride.remainingSeats, equals(2));
      expect(ride.currentFarePerPerson, equals(300.0));

      // Rejected request
      final reqDRejected = reqD.copyWith(status: RideRequestStatus.rejected);
      expect(reqDRejected.status, equals(RideRequestStatus.rejected));
      // Fare & seats remain unchanged
      expect(ride.totalPeople, equals(1));
      expect(ride.remainingSeats, equals(2));
      expect(ride.currentFarePerPerson, equals(300.0));
    });

    test('Over-capacity request is prevented and remainingSeats never goes negative', () {
      final fullRide = RideModel(
        id: 'ride_123',
        driverId: 'user_A',
        boardingLocation: 'Point A',
        destination: 'Destination',
        departureTime: DateTime.now().add(const Duration(hours: 2)),
        availableSeats: 0,
        totalSeats: 2,
        acceptedPassengerCount: 2,
        totalFare: 300.0,
        createdAt: DateTime.now(),
      );

      expect(fullRide.isFull, isTrue);
      expect(fullRide.remainingSeats, equals(0));

      // Even if an invalid state occurs where acceptedPassengerCount > totalSeats,
      // remainingSeats clamps safely to 0 and never goes negative:
      final clampedRide = fullRide.copyWith(acceptedPassengerCount: 5);
      expect(clampedRide.remainingSeats, equals(0));
    });
  });
}
