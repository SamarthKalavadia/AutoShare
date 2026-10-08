import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:autoshare/data/models/ride_model.dart';
import 'package:autoshare/shared/utils/avatar_utils.dart';

void main() {
  group('AvatarUtils Base64 and URL Decoding Tests', () {
    test('handles standard HTTP/HTTPS URLs', () {
      final provider = getAvatarImageProvider('https://example.com/avatar.png');
      expect(provider, isA<NetworkImage>());
      expect((provider as NetworkImage).url, 'https://example.com/avatar.png');
    });

    test('handles data:image Base64 URIs', () {
      final sampleBytes = utf8.encode('fake-image-bytes-data');
      final base64String = base64Encode(sampleBytes);
      final dataUri = 'data:image/jpeg;base64,$base64String';

      final provider = getAvatarImageProvider(dataUri);
      expect(provider, isA<MemoryImage>());
      expect((provider as MemoryImage).bytes, sampleBytes);
    });

    test('handles raw Base64 string (including /9j/ JPEG and newline characters)', () {
      final sampleBytes = List<int>.generate(80, (i) => i % 256);
      final rawBase64 = base64Encode(sampleBytes);
      // Inject some newlines / whitespace
      final rawWithWhitespace = '  \n$rawBase64\n  ';

      final provider = getAvatarImageProvider(rawWithWhitespace);
      expect(provider, isA<MemoryImage>());
      expect((provider as MemoryImage).bytes, sampleBytes);
    });

    test('returns null for null, empty, or invalid input', () {
      expect(getAvatarImageProvider(null), isNull);
      expect(getAvatarImageProvider(''), isNull);
      expect(getAvatarImageProvider('   '), isNull);
      expect(getAvatarImageProvider('invalid_short_str'), isNull);
    });
  });

  group('RideModel Fare per Seat dynamic calculation', () {
    test('calculates Fare / Seat dynamically based on accepted passengers', () {
      final ride = RideModel(
        id: 'ride-123',
        driverId: 'driver-1',
        boardingLocation: 'Point A',
        destination: 'Point B',
        departureTime: DateTime.now(),
        availableSeats: 2,
        totalSeats: 2,
        acceptedPassengerCount: 0,
        totalFare: 300.0,
        createdAt: DateTime.now(),
      );

      // Creator only (0 accepted passengers): totalPeople = 1, fare = 300 / 1 = 300
      expect(ride.calculateFarePerPerson(), 300.0);
      expect(ride.calculateFarePerPerson(acceptedPassengers: 0), 300.0);
      expect(ride.remainingSeats, 2);
      expect(ride.totalPeople, 1);
      expect(ride.isFull, isFalse);

      // 1 accepted passenger: totalPeople = 2, fare = 300 / 2 = 150
      final withOnePassenger = ride.copyWith(acceptedPassengerCount: 1);
      expect(withOnePassenger.calculateFarePerPerson(), 150.0);
      expect(withOnePassenger.calculateFarePerPerson(acceptedPassengers: 1), 150.0);
      expect(withOnePassenger.remainingSeats, 1);
      expect(withOnePassenger.totalPeople, 2);
      expect(withOnePassenger.isFull, isFalse);

      // 2 accepted passengers: totalPeople = 3, fare = 300 / 3 = 100 (Full ride)
      final fullRide = ride.copyWith(acceptedPassengerCount: 2);
      expect(fullRide.calculateFarePerPerson(), 100.0);
      expect(fullRide.calculateFarePerPerson(acceptedPassengers: 2), 100.0);
      expect(fullRide.remainingSeats, 0);
      expect(fullRide.totalPeople, 3);
      expect(fullRide.isFull, isTrue);
    });

    test('recalculates dynamically when passengers cancel', () {
      final ride = RideModel(
        id: 'ride-123',
        driverId: 'driver-1',
        boardingLocation: 'Point A',
        destination: 'Point B',
        departureTime: DateTime.now(),
        availableSeats: 0,
        totalSeats: 2,
        acceptedPassengerCount: 2,
        totalFare: 300.0,
        createdAt: DateTime.now(),
      );

      // Initially full (2 accepted passengers): 300 / (1 + 2) = 100
      expect(ride.calculateFarePerPerson(), 100.0);
      expect(ride.isFull, isTrue);

      // 1 passenger cancels: acceptedPassengerCount drops to 1 -> 300 / (1 + 1) = 150
      final afterFirstCancel = ride.copyWith(acceptedPassengerCount: 1);
      expect(afterFirstCancel.calculateFarePerPerson(), 150.0);
      expect(afterFirstCancel.remainingSeats, 1);
      expect(afterFirstCancel.isFull, isFalse);

      // Last passenger cancels: acceptedPassengerCount drops to 0 -> 300 / (1 + 0) = 300
      final afterSecondCancel = ride.copyWith(acceptedPassengerCount: 0);
      expect(afterSecondCancel.calculateFarePerPerson(), 300.0);
      expect(afterSecondCancel.remainingSeats, 2);
      expect(afterSecondCancel.isFull, isFalse);
    });
  });
}
