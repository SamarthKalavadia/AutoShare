import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class RideModel extends Equatable {
  final String id;
  final String driverId;
  final String boardingLocation;
  final String destination;
  final DateTime departureTime;
  final int availableSeats;
  final double farePerSeat;
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
    required this.farePerSeat,
    this.vehicleNumber = '',
    this.description = '',
    this.isGirlsOnly = false,
    this.status = 'active',
    required this.createdAt,
    this.driverName = 'Unknown Driver',
    this.driverRating = 0.0,
    this.estimatedDuration = '',
    this.distance = '',
  });

  factory RideModel.empty() {
    return RideModel(
      id: '',
      driverId: '',
      boardingLocation: '',
      destination: '',
      departureTime: DateTime.now(),
      availableSeats: 1,
      farePerSeat: 0.0,
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
    return RideModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      boardingLocation: boardingLocation ?? this.boardingLocation,
      destination: destination ?? this.destination,
      departureTime: departureTime ?? this.departureTime,
      availableSeats: availableSeats ?? this.availableSeats,
      farePerSeat: farePerSeat ?? this.farePerSeat,
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
      'availableSeats': availableSeats,
      'farePerSeat': farePerSeat,
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
    return RideModel(
      id: docId,
      driverId: map['driverId'] ?? '',
      boardingLocation: map['boardingLocation'] ?? '',
      destination: map['destination'] ?? '',
      departureTime: (map['departureTime'] as Timestamp).toDate(),
      availableSeats: map['availableSeats']?.toInt() ?? 1,
      farePerSeat: map['farePerSeat']?.toDouble() ?? 0.0,
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
        farePerSeat,
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
