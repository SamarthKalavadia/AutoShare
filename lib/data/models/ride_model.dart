import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class RideModel extends Equatable {
  final String id;
  final String driverId;
  final String boardingLocation;
  final String destination;
  final DateTime departureTime;
  final int availableSeats;
  final int totalSeats;
  final int acceptedPassengerCount;
  final double totalFare;

  /// Remaining passenger seats: availablePassengerSeats - acceptedPassengerCount.
  int get remainingSeats =>
      (totalSeats - acceptedPassengerCount).clamp(0, totalSeats);

  /// Total people currently in the ride: 1 creator + acceptedPassengerCount.
  int get totalPeople =>
      1 + (acceptedPassengerCount < 0 ? 0 : acceptedPassengerCount);

  /// Whether the ride is full (no remaining passenger seats).
  bool get isFull => remainingSeats <= 0;

  /// Calculates fare per person based on CURRENT accepted passenger count:
  /// totalPeople = 1 + acceptedPassengerCount
  /// currentFarePerPerson = totalFare / totalPeople
  double calculateFarePerPerson({int? acceptedPassengers, int? customSeats}) {
    final count = acceptedPassengers ?? acceptedPassengerCount;
    final people = 1 + (count < 0 ? 0 : count);
    if (people <= 0) return totalFare;
    return totalFare / people;
  }

  /// Current calculated fare per person.
  double get currentFarePerPerson => calculateFarePerPerson();

  /// Backward-compatible alias for existing callers.
  double get farePerSeat => currentFarePerPerson;

  final String vehicleNumber;
  final String description;
  final bool isGirlsOnly;
  final String status; // e.g., 'active', 'completed', 'cancelled'
  final DateTime createdAt;
  final String driverName; // For UI display
  final double driverRating; // For UI display
  final String estimatedDuration; // For UI display
  final String distance; // For UI display

  const RideModel({
    required this.id,
    required this.driverId,
    required this.boardingLocation,
    required this.destination,
    required this.departureTime,
    required this.availableSeats,
    int? totalSeats,
    int? acceptedPassengerCount,
    double? totalFare,
    double? farePerSeat,
    this.vehicleNumber = '',
    this.description = '',
    this.isGirlsOnly = false,
    this.status = 'active',
    required this.createdAt,
    this.driverName = 'Unknown Driver',
    this.driverRating = 0.0,
    this.estimatedDuration = '',
    this.distance = '',
  })  : totalSeats = totalSeats ?? (availableSeats > 0 ? availableSeats : 1),
        acceptedPassengerCount = acceptedPassengerCount ?? 0,
        totalFare = totalFare ?? farePerSeat ?? 0.0;

  factory RideModel.empty() {
    return RideModel(
      id: '',
      driverId: '',
      boardingLocation: '',
      destination: '',
      departureTime: DateTime.now(),
      availableSeats: 1,
      totalSeats: 1,
      acceptedPassengerCount: 0,
      totalFare: 0.0,
      createdAt: DateTime.now(),
    );
  }

  RideModel copyWith({
    String? id,
    String? driverId,
    String? boardingLocation,
    String? destination,
    DateTime? departureTime,
    int? availableSeats,
    int? totalSeats,
    int? acceptedPassengerCount,
    double? totalFare,
    double? farePerSeat,
    String? vehicleNumber,
    String? description,
    bool? isGirlsOnly,
    String? status,
    DateTime? createdAt,
    String? driverName,
    double? driverRating,
    String? estimatedDuration,
    String? distance,
  }) {
    final resolvedTotalSeats = totalSeats ?? this.totalSeats;
    final resolvedAccepted =
        acceptedPassengerCount ?? this.acceptedPassengerCount;
    final resolvedRemaining = availableSeats ??
        (resolvedTotalSeats - resolvedAccepted).clamp(0, resolvedTotalSeats);

    return RideModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      boardingLocation: boardingLocation ?? this.boardingLocation,
      destination: destination ?? this.destination,
      departureTime: departureTime ?? this.departureTime,
      availableSeats: resolvedRemaining,
      totalSeats: resolvedTotalSeats,
      acceptedPassengerCount: resolvedAccepted,
      totalFare: totalFare ?? farePerSeat ?? this.totalFare,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      description: description ?? this.description,
      isGirlsOnly: isGirlsOnly ?? this.isGirlsOnly,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      driverName: driverName ?? this.driverName,
      driverRating: driverRating ?? this.driverRating,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      distance: distance ?? this.distance,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'boardingLocation': boardingLocation,
      'destination': destination,
      'departureTime': Timestamp.fromDate(departureTime),
      'availableSeats': remainingSeats,
      'totalSeats': totalSeats,
      'acceptedPassengerCount': acceptedPassengerCount,
      'totalFare': totalFare,
      'currentFarePerPerson': currentFarePerPerson,
      'farePerSeat': currentFarePerPerson,
      'vehicleNumber': vehicleNumber,
      'description': description,
      'isGirlsOnly': isGirlsOnly,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'driverName': driverName,
      'driverRating': driverRating,
      'estimatedDuration': estimatedDuration,
      'distance': distance,
    };
  }

  factory RideModel.fromMap(Map<String, dynamic> map, String docId) {
    final rawTotalSeats =
        (map['totalSeats'] ?? map['availableSeats'])?.toInt() ?? 1;
    final rawAvailableSeats =
        map['availableSeats']?.toInt() ?? rawTotalSeats;
    final rawAccepted = map['acceptedPassengerCount']?.toInt() ??
        (rawTotalSeats - rawAvailableSeats).clamp(0, rawTotalSeats);

    return RideModel(
      id: docId,
      driverId: map['driverId'] ?? '',
      boardingLocation: map['boardingLocation'] ?? '',
      destination: map['destination'] ?? '',
      departureTime: (map['departureTime'] as Timestamp).toDate(),
      availableSeats: rawAvailableSeats,
      totalSeats: rawTotalSeats,
      acceptedPassengerCount: rawAccepted,
      totalFare: (map['totalFare'] ?? map['farePerSeat'])?.toDouble() ?? 0.0,
      vehicleNumber: map['vehicleNumber'] ?? '',
      description: map['description'] ?? '',
      isGirlsOnly: map['isGirlsOnly'] ?? false,
      status: map['status'] ?? 'active',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      driverName: map['driverName'] ?? 'Unknown Driver',
      driverRating: map['driverRating']?.toDouble() ?? 0.0,
      estimatedDuration: map['estimatedDuration'] ?? '',
      distance: map['distance'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
    id,
    driverId,
    boardingLocation,
    destination,
    departureTime,
    availableSeats,
    totalSeats,
    acceptedPassengerCount,
    totalFare,
    vehicleNumber,
    description,
    isGirlsOnly,
    status,
    createdAt,
    driverName,
    driverRating,
    estimatedDuration,
    distance,
  ];
}
