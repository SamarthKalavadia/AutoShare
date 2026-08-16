import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class RatingModel extends Equatable {
  final String ratingId;
  final String rideId;
  final String fromUserId;
  final String toUserId;
  final int rating;
  final String review;
  final DateTime createdAt;

  const RatingModel({
    required this.ratingId,
    required this.rideId,
    required this.fromUserId,
    required this.toUserId,
    required this.rating,
    required this.review,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    ratingId,
    rideId,
    fromUserId,
    toUserId,
    rating,
    review,
    createdAt,
  ];

  RatingModel copyWith({
    String? ratingId,
    String? rideId,
    String? fromUserId,
    String? toUserId,
    int? rating,
    String? review,
    DateTime? createdAt,
  }) {
    return RatingModel(
      ratingId: ratingId ?? this.ratingId,
      rideId: rideId ?? this.rideId,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ratingId': ratingId,
      'rideId': rideId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'rating': rating,
      'review': review,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory RatingModel.fromMap(Map<String, dynamic> map, String id) {
    return RatingModel(
      ratingId: id,
      rideId: map['rideId'] as String? ?? '',
      fromUserId: map['fromUserId'] as String? ?? '',
      toUserId: map['toUserId'] as String? ?? '',
      rating: map['rating'] as int? ?? 0,
      review: map['review'] as String? ?? '',
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
