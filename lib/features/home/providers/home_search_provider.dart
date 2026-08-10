import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeSearchState {
  final String boarding;
  final String destination;
  final DateTime? departureDate;
  final String? departureTime; // e.g. "08:30 AM"
  final int passengers;
  final bool girlsOnly;

  const HomeSearchState({
    this.boarding = '',
    this.destination = '',
    this.departureDate,
    this.departureTime,
    this.passengers = 1,
    this.girlsOnly = false,
  });

  HomeSearchState copyWith({
    String? boarding,
    String? destination,
    DateTime? departureDate,
    String? departureTime,
    int? passengers,
    bool? girlsOnly,
  }) {
    return HomeSearchState(
      boarding: boarding ?? this.boarding,
      destination: destination ?? this.destination,
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

  void updateBoarding(String value) => state = state.copyWith(boarding: value);
  void updateDestination(String value) => state = state.copyWith(destination: value);
  void updateDate(DateTime value) => state = state.copyWith(departureDate: value);
  void updateTime(String value) => state = state.copyWith(departureTime: value);
  void updatePassengers(int value) => state = state.copyWith(passengers: value);
  void toggleGirlsOnly(bool value) => state = state.copyWith(girlsOnly: value);
  
  void clear() => state = const HomeSearchState();
}

/// A global provider to persist search card data across the dashboard
final homeSearchProvider = NotifierProvider<HomeSearchNotifier, HomeSearchState>(
  HomeSearchNotifier.new,
);
