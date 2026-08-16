import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeSearchState {
  final String boarding;
  final String? boardingPlaceId;
  final String? boardingAddress;
  final double? boardingLat;
  final double? boardingLng;
  final String destination;
  final String? destinationPlaceId;
  final String? destinationAddress;
  final double? destinationLat;
  final double? destinationLng;
  final DateTime? departureDate;
  final String? departureTime; // e.g. "08:30 AM"
  final int passengers;
  final bool girlsOnly;

  const HomeSearchState({
    this.boarding = '',
    this.boardingPlaceId,
    this.boardingAddress,
    this.boardingLat,
    this.boardingLng,
    this.destination = '',
    this.destinationPlaceId,
    this.destinationAddress,
    this.destinationLat,
    this.destinationLng,
    this.departureDate,
    this.departureTime,
    this.passengers = 1,
    this.girlsOnly = false,
  });

  HomeSearchState copyWith({
    String? boarding,
    String? boardingPlaceId,
    String? boardingAddress,
    double? boardingLat,
    double? boardingLng,
    String? destination,
    String? destinationPlaceId,
    String? destinationAddress,
    double? destinationLat,
    double? destinationLng,
    DateTime? departureDate,
    String? departureTime,
    int? passengers,
    bool? girlsOnly,
  }) {
    return HomeSearchState(
      boarding: boarding ?? this.boarding,
      boardingPlaceId: boardingPlaceId ?? this.boardingPlaceId,
      boardingAddress: boardingAddress ?? this.boardingAddress,
      boardingLat: boardingLat ?? this.boardingLat,
      boardingLng: boardingLng ?? this.boardingLng,
      destination: destination ?? this.destination,
      destinationPlaceId: destinationPlaceId ?? this.destinationPlaceId,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      departureDate: departureDate ?? this.departureDate,
      departureTime: departureTime ?? this.departureTime,
      passengers: passengers ?? this.passengers,
      girlsOnly: girlsOnly ?? this.girlsOnly,
    );
  }
}

class HomeSearchNotifier extends Notifier<HomeSearchState> {
  @override
  HomeSearchState build() {
    return const HomeSearchState();
  }

  void updateBoarding(
    String value, {
    String? placeId,
    String? address,
    double? lat,
    double? lng,
  }) => state = state.copyWith(
    boarding: value,
    boardingPlaceId: placeId,
    boardingAddress: address,
    boardingLat: lat,
    boardingLng: lng,
  );
  void updateDestination(
    String value, {
    String? placeId,
    String? address,
    double? lat,
    double? lng,
  }) => state = state.copyWith(
    destination: value,
    destinationPlaceId: placeId,
    destinationAddress: address,
    destinationLat: lat,
    destinationLng: lng,
  );
  void updateDate(DateTime value) =>
      state = state.copyWith(departureDate: value);
  void updateTime(String value) => state = state.copyWith(departureTime: value);
  void updatePassengers(int value) => state = state.copyWith(passengers: value);
  void toggleGirlsOnly(bool value) => state = state.copyWith(girlsOnly: value);

  void clear() => state = const HomeSearchState();
}

/// A global provider to persist search card data across the dashboard
final homeSearchProvider =
    NotifierProvider<HomeSearchNotifier, HomeSearchState>(
      HomeSearchNotifier.new,
    );
