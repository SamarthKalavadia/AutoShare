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
    test('calculates Fare / Seat dynamically based on availableSeats', () {
      final ride = RideModel(
        id: 'ride-123',
        driverId: 'driver-1',
        boardingLocation: 'Point A',
        destination: 'Point B',
        departureTime: DateTime.now(),
        availableSeats: 2,
        totalFare: 300.0,
        createdAt: DateTime.now(),
      );

      // With 2 available seats, fare per seat is 300 / 2 = 150
      expect(ride.calculateFarePerPerson(), 150.0);

      // When edited to 1 available seat, fare per seat is 300 / 1 = 300
      final updatedRide = ride.copyWith(availableSeats: 1);
      expect(updatedRide.calculateFarePerPerson(), 300.0);

      // When customSeats parameter is supplied
      expect(ride.calculateFarePerPerson(customSeats: 1), 300.0);
      expect(ride.calculateFarePerPerson(customSeats: 2), 150.0);
    });

    test('calculates Fare / Person when availableSeats is 0', () {
      final ride = RideModel(
        id: 'ride-123',
        driverId: 'driver-1',
        boardingLocation: 'Point A',
        destination: 'Point B',
        departureTime: DateTime.now(),
        availableSeats: 0,
        totalFare: 300.0,
        createdAt: DateTime.now(),
      );

      // 0 available seats, 0 accepted passengers -> 300 / (1 + 0) = 300
      expect(ride.calculateFarePerPerson(acceptedPassengers: 0), 300.0);

      // 0 available seats, 1 accepted passenger -> 300 / (1 + 1) = 150
      expect(ride.calculateFarePerPerson(acceptedPassengers: 1), 150.0);
    });
  });
}
