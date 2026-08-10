import 'package:equatable/equatable.dart';

/// Represents a single driver in the Driver Directory.
class DriverModel extends Equatable {
  final String driverId;
  final String name;
  final String phoneNumber;
  final String area;
  final String city;
  final bool available;
  final bool verified;
  final double rating;
  final String? profileImage; // Optional URL or asset path

  const DriverModel({
    required this.driverId,
    required this.name,
    required this.phoneNumber,
    required this.area,
    required this.city,
    required this.available,
    required this.verified,
    required this.rating,
    this.profileImage,
  });

  @override
  List<Object?> get props => [
        driverId,
        name,
        phoneNumber,
        area,
        city,
        available,
        verified,
        rating,
        profileImage,
      ];

  DriverModel copyWith({
    String? driverId,
    String? name,
    String? phoneNumber,
    String? area,
    String? city,
    bool? available,
    bool? verified,
    double? rating,
    String? profileImage,
  }) {
    return DriverModel(
      driverId: driverId ?? this.driverId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      area: area ?? this.area,
      city: city ?? this.city,
      available: available ?? this.available,
      verified: verified ?? this.verified,
      rating: rating ?? this.rating,
      profileImage: profileImage ?? this.profileImage,
    );
  }

  // ── Future Firebase integration ──────────────────────────────────────────────
  // When you add Firebase, uncomment and use these:

  // Map<String, dynamic> toMap() {
  //   return {
  //     'driverId': driverId,
  //     'name': name,
  //     'phoneNumber': phoneNumber,
  //     'area': area,
  //     'city': city,
  //     'available': available,
  //     'verified': verified,
  //     'rating': rating,
  //     'profileImage': profileImage,
  //   };
  // }

  // factory DriverModel.fromMap(Map<String, dynamic> map, String id) {
  //   return DriverModel(
  //     driverId: id,
  //     name: map['name'] as String? ?? '',
  //     phoneNumber: map['phoneNumber'] as String? ?? '',
  //     area: map['area'] as String? ?? '',
  //     city: map['city'] as String? ?? '',
  //     available: map['available'] as bool? ?? false,
  //     verified: map['verified'] as bool? ?? false,
  //     rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
  //     profileImage: map['profileImage'] as String?,
  //   );
  // }
}
