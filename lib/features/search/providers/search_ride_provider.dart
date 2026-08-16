import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/result.dart';
import '../../../data/models/ride_model.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../../shared/providers.dart';

class SearchRideFilterState {
  final String boardingLocation;
  final String destination;
  final DateTime? departureDate;
  final DateTime? departureTime;
  final int requiredSeats;
  final double maxFare;
  final bool isGirlsOnly;
  final bool isLoading;
  final bool hasSearched;
  final List<RideModel> searchResults;

  const SearchRideFilterState({
    this.boardingLocation = '',
    this.destination = '',
    this.departureDate,
    this.departureTime,
    this.requiredSeats = 1,
    this.maxFare = 500.0,
    this.isGirlsOnly = false,
    this.isLoading = false,
    this.hasSearched = false,
    this.searchResults = const [],
  });

  SearchRideFilterState copyWith({
    String? boardingLocation,
    String? destination,
    DateTime? departureDate,
    DateTime? departureTime,
    int? requiredSeats,
    double? maxFare,
    bool? isGirlsOnly,
    bool? isLoading,
    bool? hasSearched,
    List<RideModel>? searchResults,
  }) {
    return SearchRideFilterState(
      boardingLocation: boardingLocation ?? this.boardingLocation,
      destination: destination ?? this.destination,
      departureDate: departureDate ?? this.departureDate,
      departureTime: departureTime ?? this.departureTime,
      requiredSeats: requiredSeats ?? this.requiredSeats,
      maxFare: maxFare ?? this.maxFare,
      isGirlsOnly: isGirlsOnly ?? this.isGirlsOnly,
      isLoading: isLoading ?? this.isLoading,
      hasSearched: hasSearched ?? this.hasSearched,
      searchResults: searchResults ?? this.searchResults,
    );
  }

  bool get isValid {
    final hasLocations =
        boardingLocation.trim().isNotEmpty && destination.trim().isNotEmpty;
    final locationsDifferent =
        boardingLocation.trim().toLowerCase() !=
        destination.trim().toLowerCase();
    final validFare = maxFare > 0;
    final validSeats = requiredSeats >= 1 && requiredSeats <= 4;

    // Check if future time (only if user selected both)
    bool isFutureTime = true;
    if (departureDate != null && departureTime != null) {
      final combinedDateTime = DateTime(
        departureDate!.year,
        departureDate!.month,
        departureDate!.day,
        departureTime!.hour,
        departureTime!.minute,
      );
      isFutureTime = combinedDateTime.isAfter(DateTime.now());
    }

    return hasLocations &&
        locationsDifferent &&
        isFutureTime &&
        validFare &&
        validSeats;
  }
}

class SearchRideNotifier extends Notifier<SearchRideFilterState> {
  @override
  SearchRideFilterState build() {
    return const SearchRideFilterState();
  }

  void updateBoardingLocation(String value) {
    state = state.copyWith(boardingLocation: value);
  }

  void updateDestination(String value) {
    state = state.copyWith(destination: value);
  }

  void swapLocations() {
    state = state.copyWith(
      boardingLocation: state.destination,
      destination: state.boardingLocation,
    );
  }

  void updateDepartureDate(DateTime date) {
    state = state.copyWith(departureDate: date);
  }

  void updateDepartureTime(DateTime time) {
    state = state.copyWith(departureTime: time);
  }

  void updateRequiredSeats(int seats) {
    if (seats >= 1 && seats <= 4) {
      state = state.copyWith(requiredSeats: seats);
    }
  }

  void updateMaxFare(double fare) {
    state = state.copyWith(maxFare: fare);
  }

  void toggleGirlsOnly(bool value) {
    state = state.copyWith(isGirlsOnly: value);
  }

  Future<void> searchRides() async {
    if (!state.isValid) return;

    state = state.copyWith(
      isLoading: true,
      searchResults: [],
      hasSearched: true,
    );

    DateTime? departureTimeFilter;
    if (state.departureDate != null && state.departureTime != null) {
      departureTimeFilter = DateTime(
        state.departureDate!.year,
        state.departureDate!.month,
        state.departureDate!.day,
        state.departureTime!.hour,
        state.departureTime!.minute,
      );
    }

    final authState = ref.read(authControllerProvider);
    final isFemale = authState.value?.gender.toLowerCase() == 'female';

    // If the user checked "Girls Only" but isn't female, they shouldn't see them anyway.
    // However, the UI should prevent checking the box if not female.
    // We enforce it strictly here.
    final enforceGirlsOnly = isFemale && state.isGirlsOnly;

    final result = await ref
        .read(rideRepositoryProvider)
        .searchRides(
          boardingLocation: state.boardingLocation,
          destination: state.destination,
          seats: state.requiredSeats,
          maxFare: state.maxFare,
          isGirlsOnly: enforceGirlsOnly,
          departureTime: departureTimeFilter,
        );

    if (result is Success<List<RideModel>>) {
      var filteredRides = result.data;

      // Secondary strict filter: Non-females can NEVER see Girls Only rides
      if (!isFemale) {
        filteredRides = filteredRides.where((r) => !r.isGirlsOnly).toList();
      }

      state = state.copyWith(isLoading: false, searchResults: filteredRides);
    } else {
      // On error, just show empty
      state = state.copyWith(isLoading: false, searchResults: []);
    }
  }

  void sortRides(String criteria) {
    if (state.searchResults.isEmpty) return;

    final sortedList = List<RideModel>.from(state.searchResults);

    switch (criteria) {
      case 'Nearest':
        sortedList.sort((a, b) => a.distance.compareTo(b.distance));
        break;
      case 'Lowest Fare':
        sortedList.sort((a, b) => a.farePerSeat.compareTo(b.farePerSeat));
        break;
      case 'Earliest Departure':
        sortedList.sort((a, b) => a.departureTime.compareTo(b.departureTime));
        break;
      case 'Highest Rating':
        sortedList.sort((a, b) => b.driverRating.compareTo(a.driverRating));
        break;
      case 'Most Seats Available':
        sortedList.sort((a, b) => b.availableSeats.compareTo(a.availableSeats));
        break;
    }

    state = state.copyWith(searchResults: sortedList);
  }
}

final searchRideProvider =
    NotifierProvider<SearchRideNotifier, SearchRideFilterState>(
      SearchRideNotifier.new,
    );
