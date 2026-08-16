import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/result.dart';
import '../../../data/models/ride_model.dart';
import '../../../shared/providers.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../../core/services/notification_service.dart';

class CreateRideState {
  final String boardingLocation;
  final String destination;
  final String boardingPlaceId;
  final double? boardingLat;
  final double? boardingLng;
  final String boardingAddress;
  final String destinationPlaceId;
  final double? destinationLat;
  final double? destinationLng;
  final String destinationAddress;
  final DateTime? departureDate;
  final DateTime? departureTime;
  final int availableSeats;
  final double farePerSeat;
  final String vehicleNumber;
  final String driverName;
  final String rideDescription;
  final bool isGirlsOnly;
  final bool isLoading;

  const CreateRideState({
    this.boardingLocation = '',
    this.destination = '',
    this.boardingPlaceId = '',
    this.boardingLat,
    this.boardingLng,
    this.boardingAddress = '',
    this.destinationPlaceId = '',
    this.destinationLat,
    this.destinationLng,
    this.destinationAddress = '',
    this.departureDate,
    this.departureTime,
    this.availableSeats = 1,
    this.farePerSeat = 0.0,
    this.vehicleNumber = '',
    this.driverName = '',
    this.rideDescription = '',
    this.isGirlsOnly = false,
    this.isLoading = false,
  });

  CreateRideState copyWith({
    String? boardingLocation,
    String? destination,
    String? boardingPlaceId,
    double? boardingLat,
    double? boardingLng,
    String? boardingAddress,
    String? destinationPlaceId,
    double? destinationLat,
    double? destinationLng,
    String? destinationAddress,
    DateTime? departureDate,
    DateTime? departureTime,
    int? availableSeats,
    double? farePerSeat,
    String? vehicleNumber,
    String? driverName,
    String? rideDescription,
    bool? isGirlsOnly,
    bool? isLoading,
  }) {
    return CreateRideState(
      boardingLocation: boardingLocation ?? this.boardingLocation,
      destination: destination ?? this.destination,
      boardingPlaceId: boardingPlaceId ?? this.boardingPlaceId,
      boardingLat: boardingLat ?? this.boardingLat,
      boardingLng: boardingLng ?? this.boardingLng,
      boardingAddress: boardingAddress ?? this.boardingAddress,
      destinationPlaceId: destinationPlaceId ?? this.destinationPlaceId,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      departureDate: departureDate ?? this.departureDate,
      departureTime: departureTime ?? this.departureTime,
      availableSeats: availableSeats ?? this.availableSeats,
      farePerSeat: farePerSeat ?? this.farePerSeat,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      driverName: driverName ?? this.driverName,
      rideDescription: rideDescription ?? this.rideDescription,
      isGirlsOnly: isGirlsOnly ?? this.isGirlsOnly,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  String? get validationError {
    if (boardingLocation.trim().isEmpty) {
      return 'Please enter a boarding location';
    }
    if (destination.trim().isEmpty) {
      return 'Please enter a destination';
    }
    if (boardingLocation.trim().toLowerCase() == destination.trim().toLowerCase()) {
      return 'Boarding location and destination cannot be the same';
    }
    if (departureDate == null) {
      return 'Please select a departure date';
    }
    if (departureTime == null) {
      return 'Please select a departure time';
    }
    final combinedDateTime = DateTime(
      departureDate!.year,
      departureDate!.month,
      departureDate!.day,
      departureTime!.hour,
      departureTime!.minute,
    );
    if (combinedDateTime.isBefore(DateTime.now().subtract(const Duration(minutes: 5)))) {
      return 'Departure time must be in the future';
    }
    if (availableSeats < 1 || availableSeats > 4) {
      return 'Available seats must be between 1 and 4';
    }
    if (farePerSeat < 0) {
      return 'Fare per seat cannot be negative';
    }
    return null;
  }

  bool get isValid => validationError == null;
}

class CreateRideNotifier extends Notifier<CreateRideState> {
  @override
  CreateRideState build() {
    return const CreateRideState();
  }

  void reset() {
    state = const CreateRideState();
  }

  void updateBoardingLocation(String value) {
    state = state.copyWith(boardingLocation: value);
  }

  void updateBoardingDetails({required String placeId, required String address, double? lat, double? lng}) {
    state = state.copyWith(
      boardingPlaceId: placeId,
      boardingAddress: address,
      boardingLat: lat,
      boardingLng: lng,
    );
  }

  void updateDestinationLocation(String value) {
    state = state.copyWith(destination: value);
  }

  void updateDestinationDetails({required String placeId, required String address, double? lat, double? lng}) {
    state = state.copyWith(
      destinationPlaceId: placeId,
      destinationAddress: address,
      destinationLat: lat,
      destinationLng: lng,
    );
  }

  void updateDestination(String value) {
    state = state.copyWith(destination: value);
  }

  void swapLocations() {
    final oldBoardingLoc = state.boardingLocation;
    final oldBoardingPlaceId = state.boardingPlaceId;
    final oldBoardingLat = state.boardingLat;
    final oldBoardingLng = state.boardingLng;
    final oldBoardingAddress = state.boardingAddress;

    state = state.copyWith(
      boardingLocation: state.destination,
      boardingPlaceId: state.destinationPlaceId,
      boardingLat: state.destinationLat,
      boardingLng: state.destinationLng,
      boardingAddress: state.destinationAddress,
      destination: oldBoardingLoc,
      destinationPlaceId: oldBoardingPlaceId,
      destinationLat: oldBoardingLat,
      destinationLng: oldBoardingLng,
      destinationAddress: oldBoardingAddress,
    );
  }

  void updateDepartureDate(DateTime date) {
    state = state.copyWith(departureDate: date);
  }

  void updateDepartureTime(DateTime time) {
    state = state.copyWith(departureTime: time);
  }

  void updateAvailableSeats(int seats) {
    if (seats >= 1 && seats <= 4) {
      state = state.copyWith(availableSeats: seats);
    }
  }

  void updateFarePerSeat(double fare) {
    state = state.copyWith(farePerSeat: fare);
  }

  void updateVehicleNumber(String vehicleNumber) {
    state = state.copyWith(vehicleNumber: vehicleNumber.toUpperCase());
  }

  void updateDriverName(String driverName) {
    state = state.copyWith(driverName: driverName);
  }

  void updateRideDescription(String description) {
    if (description.length <= 150) {
      state = state.copyWith(rideDescription: description);
    }
  }

  void toggleGirlsOnly(bool value) {
    state = state.copyWith(isGirlsOnly: value);
  }

  Future<Result<String>> publishRide() async {
    final validationErr = state.validationError;
    if (validationErr != null) {
      return Failure(validationErr, Exception(validationErr));
    }

    state = state.copyWith(isLoading: true);

    final user = ref.read(authControllerProvider).value;
    if (user == null) {
      state = state.copyWith(isLoading: false);
      return Failure('User not logged in. Please sign in to create a ride.', Exception('Unauthenticated'));
    }

    final ride = RideModel(
      id: '',
      driverId: user.uid,
      driverName: user.name.isNotEmpty ? user.name : 'Driver',
      driverRating: user.averageRating,
      boardingLocation: state.boardingLocation,
      destination: state.destination,
      departureTime: DateTime(
        state.departureDate!.year,
        state.departureDate!.month,
        state.departureDate!.day,
        state.departureTime!.hour,
        state.departureTime!.minute,
      ),
      availableSeats: state.availableSeats,
      farePerSeat: state.farePerSeat,
      vehicleNumber: state.vehicleNumber,
      description: state.rideDescription,
      isGirlsOnly: state.isGirlsOnly,
      createdAt: DateTime.now(),
    );

    final result = await ref.read(rideRepositoryProvider).createRide(ride);

    state = state.copyWith(isLoading: false);

    if (result is Success<String>) {
      // Schedule background reminders safely
      try {
        await NotificationService().scheduleRideReminder(result.data, ride.departureTime);
      } catch (e) {
        // Notification error should never prevent successful ride creation
      }
    }

    return result;
  }
}

final createRideProvider = NotifierProvider<CreateRideNotifier, CreateRideState>(
  CreateRideNotifier.new,
);

final isUserFemaleProvider = Provider.autoDispose<bool>((ref) {
  final userAsync = ref.watch(authControllerProvider);
  final user = userAsync.value;
  return user?.gender.toLowerCase() == 'female';
});
