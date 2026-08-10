import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/ride_model.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

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
    final hasLocations = boardingLocation.trim().isNotEmpty && destination.trim().isNotEmpty;
    final locationsDifferent = boardingLocation.trim().toLowerCase() != destination.trim().toLowerCase();
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

    return hasLocations && locationsDifferent && isFutureTime && validFare && validSeats;
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

    state = state.copyWith(isLoading: true, searchResults: [], hasSearched: true);

    // Mock network delay
    await Future.delayed(const Duration(seconds: 2));

    // Generate 8 realistic dummy rides
    final dummyRides = _generateDummyRides();

    // Filter by Girls Only if toggle is ON
    var filteredRides = dummyRides;
    if (state.isGirlsOnly) {
      filteredRides = filteredRides.where((r) => r.isGirlsOnly).toList();
    }
    
    // Basic filter simulation: if the user searched for something, we just return the dummy rides 
    // in a real app, we would query Firestore with parameters

    state = state.copyWith(
      isLoading: false,
      searchResults: filteredRides,
    );
  }

  List<RideModel> _generateDummyRides() {
    final now = DateTime.now();
    final currentUserId = ref.read(authControllerProvider).value?.uid ?? '';

    return [
      RideModel(
        id: 'ride_1',
        driverId: 'driver_a',
        driverName: 'Rahul Sharma',
        driverRating: 4.8,
        boardingLocation: state.boardingLocation.isEmpty ? 'Koramangala' : state.boardingLocation,
        destination: state.destination.isEmpty ? 'HSR Layout' : state.destination,
        departureTime: now.add(const Duration(minutes: 15)),
        availableSeats: 2,
        farePerSeat: 45.0,
        estimatedDuration: '25 mins',
        distance: '6 km',
        isGirlsOnly: false,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      RideModel(
        id: 'ride_2',
        driverId: 'driver_b',
        driverName: 'Priya Patel',
        driverRating: 4.9,
        boardingLocation: state.boardingLocation.isEmpty ? 'Indiranagar' : state.boardingLocation,
        destination: state.destination.isEmpty ? 'Whitefield' : state.destination,
        departureTime: now.add(const Duration(minutes: 45)),
        availableSeats: 1,
        farePerSeat: 120.0,
        estimatedDuration: '45 mins',
        distance: '14 km',
        isGirlsOnly: true,
        createdAt: now.subtract(const Duration(minutes: 30)),
      ),
      RideModel(
        id: 'ride_3',
        driverId: currentUserId, // Current user's own ride (Owner logic test)
        driverName: 'You',
        driverRating: 5.0,
        boardingLocation: state.boardingLocation.isEmpty ? 'BTM Layout' : state.boardingLocation,
        destination: state.destination.isEmpty ? 'Electronic City' : state.destination,
        departureTime: now.add(const Duration(hours: 1)),
        availableSeats: 3,
        farePerSeat: 80.0,
        estimatedDuration: '35 mins',
        distance: '10 km',
        isGirlsOnly: false,
        createdAt: now.subtract(const Duration(minutes: 10)),
      ),
      RideModel(
        id: 'ride_4',
        driverId: 'driver_c',
        driverName: 'Amit Kumar',
        driverRating: 4.6,
        boardingLocation: state.boardingLocation.isEmpty ? 'Jayanagar' : state.boardingLocation,
        destination: state.destination.isEmpty ? 'MG Road' : state.destination,
        departureTime: now.add(const Duration(minutes: 20)),
        availableSeats: 2,
        farePerSeat: 60.0,
        estimatedDuration: '30 mins',
        distance: '8 km',
        isGirlsOnly: false,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      RideModel(
        id: 'ride_5',
        driverId: 'driver_d',
        driverName: 'Neha Gupta',
        driverRating: 4.7,
        boardingLocation: state.boardingLocation.isEmpty ? 'Marathahalli' : state.boardingLocation,
        destination: state.destination.isEmpty ? 'Bellandur' : state.destination,
        departureTime: now.add(const Duration(minutes: 5)),
        availableSeats: 1,
        farePerSeat: 30.0,
        estimatedDuration: '15 mins',
        distance: '4 km',
        isGirlsOnly: true,
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
      RideModel(
        id: 'ride_6',
        driverId: 'driver_e',
        driverName: 'Vikram Singh',
        driverRating: 4.5,
        boardingLocation: state.boardingLocation.isEmpty ? 'Hebbal' : state.boardingLocation,
        destination: state.destination.isEmpty ? 'Manyata Tech Park' : state.destination,
        departureTime: now.add(const Duration(hours: 2)),
        availableSeats: 3,
        farePerSeat: 50.0,
        estimatedDuration: '20 mins',
        distance: '5 km',
        isGirlsOnly: false,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      RideModel(
        id: 'ride_7',
        driverId: 'driver_f',
        driverName: 'Anjali Desai',
        driverRating: 4.9,
        boardingLocation: state.boardingLocation.isEmpty ? 'Malleswaram' : state.boardingLocation,
        destination: state.destination.isEmpty ? 'Rajajinagar' : state.destination,
        departureTime: now.add(const Duration(minutes: 10)),
        availableSeats: 2,
        farePerSeat: 40.0,
        estimatedDuration: '15 mins',
        distance: '3 km',
        isGirlsOnly: true,
        createdAt: now.subtract(const Duration(minutes: 40)),
      ),
      RideModel(
        id: 'ride_8',
        driverId: 'driver_g',
        driverName: 'Suresh Menon',
        driverRating: 4.8,
        boardingLocation: state.boardingLocation.isEmpty ? 'Banashankari' : state.boardingLocation,
        destination: state.destination.isEmpty ? 'JP Nagar' : state.destination,
        departureTime: now.add(const Duration(minutes: 50)),
        availableSeats: 4,
        farePerSeat: 35.0,
        estimatedDuration: '20 mins',
        distance: '5 km',
        isGirlsOnly: false,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 20)),
      ),
    ];
  }

  void sortRides(String criteria) {
    if (state.searchResults.isEmpty) return;

    final sortedList = List<RideModel>.from(state.searchResults);
    
    switch (criteria) {
      case 'Nearest':
        // Mock nearest by distance string length or just leave as is since it's dummy data
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

final searchRideProvider = NotifierProvider<SearchRideNotifier, SearchRideFilterState>(
  SearchRideNotifier.new,
);
