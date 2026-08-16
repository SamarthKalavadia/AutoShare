import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Status values for a ride request lifecycle.
enum RideRequestStatus {
  pending,
  accepted,
  rejected,
  cancelled;

  static RideRequestStatus fromString(String value) {
    return RideRequestStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RideRequestStatus.pending,
    );
  }
}

/// Represents a ride request document in Firestore `ride_requests` collection.
class RideRequestModel extends Equatable {
  final String requestId;
  final String rideId;
  final String ownerUid;
  final String requesterUid;
  final int requestedSeats;
  final RideRequestStatus status;
  final DateTime requestedAt;

  const RideRequestModel({
    required this.requestId,
    required this.rideId,
    required this.ownerUid,
    required this.requesterUid,
    required this.requestedSeats,
    required this.status,
    required this.requestedAt,
  });

  factory RideRequestModel.create({
    required String requestId,
    required String rideId,
    required String ownerUid,
    required String requesterUid,
    required int requestedSeats,
  }) {
    return RideRequestModel(
      requestId: requestId,
      rideId: rideId,
      ownerUid: ownerUid,
      requesterUid: requesterUid,
      requestedSeats: requestedSeats,
      status: RideRequestStatus.pending,
      requestedAt: DateTime.now(),
    );
  }

  RideRequestModel copyWith({
    String? requestId,
    String? rideId,
    String? ownerUid,
    String? requesterUid,
    int? requestedSeats,
    RideRequestStatus? status,
    DateTime? requestedAt,
  }) {
    return RideRequestModel(
      requestId: requestId ?? this.requestId,
      rideId: rideId ?? this.rideId,
      ownerUid: ownerUid ?? this.ownerUid,
      requesterUid: requesterUid ?? this.requesterUid,
      requestedSeats: requestedSeats ?? this.requestedSeats,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'rideId': rideId,
      'ownerUid': ownerUid,
      'requesterUid': requesterUid,
      'requestedSeats': requestedSeats,
      'status': status.name,
      'requestedAt': Timestamp.fromDate(requestedAt),
    };
  }

  factory RideRequestModel.fromMap(Map<String, dynamic> map, String docId) {
    return RideRequestModel(
      requestId: docId,
      rideId: map['rideId'] as String? ?? '',
      ownerUid: map['ownerUid'] as String? ?? '',
      requesterUid: map['requesterUid'] as String? ?? '',
      requestedSeats: (map['requestedSeats'] as num?)?.toInt() ?? 1,
      status: RideRequestStatus.fromString(
        map['status'] as String? ?? 'pending',
      ),
      requestedAt: map['requestedAt'] is Timestamp
          ? (map['requestedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory RideRequestModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RideRequestModel.fromMap(data, doc.id);
  }

  @override
  List<Object?> get props => [
    requestId,
    rideId,
    ownerUid,
    requesterUid,
    requestedSeats,
    status,
    requestedAt,
  ];
}
