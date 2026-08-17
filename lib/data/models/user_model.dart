import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a User entity in the application.
class UserModel extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String profileImage;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastSeen;
  final bool isOnline;
  final String gender;
  final double averageRating;
  final int totalReviews;
  final List<String> blockedUsers;
  final String city;
  final String emergencyContact;
  final String bio;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImage,
    required this.emailVerified,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSeen,
    required this.isOnline,
    required this.gender,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.blockedUsers = const [],
    this.city = '',
    this.emergencyContact = '',
    this.bio = '',
  });

  /// Creates an empty UserModel with default/null values.
  factory UserModel.empty() {
    return UserModel(
      uid: '',
      name: '',
      email: '',
      phone: '',
      profileImage: '',
      emailVerified: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastSeen: DateTime.now(),
      isOnline: false,
      gender: '',
      averageRating: 0.0,
      totalReviews: 0,
      blockedUsers: const [],
      city: '',
      emergencyContact: '',
      bio: '',
    );
  }

  @override
  List<Object?> get props => [
    uid,
    name,
    email,
    phone,
    profileImage,
    emailVerified,
    createdAt,
    updatedAt,
    lastSeen,
    isOnline,
    gender,
    averageRating,
    totalReviews,
    blockedUsers,
    city,
    emergencyContact,
    bio,
  ];

  /// Creates a copy of the current model with updated values.
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSeen,
    bool? isOnline,
    String? gender,
    double? averageRating,
    int? totalReviews,
    List<String>? blockedUsers,
    String? city,
    String? emergencyContact,
    String? bio,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      gender: gender ?? this.gender,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      city: city ?? this.city,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      bio: bio ?? this.bio,
    );
  }

  /// Converts the model to a JSON map.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'emailVerified': emailVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastSeen': Timestamp.fromDate(lastSeen),
      'isOnline': isOnline,
      'gender': gender,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'blockedUsers': blockedUsers,
      'city': city,
      'emergencyContact': emergencyContact,
      'bio': bio,
    };
  }

  /// Alias for toMap for standard JSON serialization.
  Map<String, dynamic> toJson() => toMap();

  /// Creates a model from a JSON map.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    final photo = (map['profileImage'] as String?)?.trim() ??
        (map['photoURL'] as String?)?.trim() ??
        (map['photoUrl'] as String?)?.trim() ??
        (map['avatar'] as String?)?.trim() ??
        (map['profile_image'] as String?)?.trim() ??
        (map['profilePic'] as String?)?.trim() ??
        (map['image'] as String?)?.trim() ??
        '';

    final userName = (map['name'] as String?)?.trim() ??
        (map['displayName'] as String?)?.trim() ??
        (map['fullName'] as String?)?.trim() ??
        '';

    return UserModel(
      uid: map['uid'] as String? ?? '',
      name: userName,
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      profileImage: photo,
      emailVerified: map['emailVerified'] as bool? ?? false,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      lastSeen: _parseTimestamp(map['lastSeen']),
      isOnline: map['isOnline'] as bool? ?? false,
      gender: map['gender'] as String? ?? '',
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: map['totalReviews'] as int? ?? 0,
      blockedUsers:
          (map['blockedUsers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      city: map['city'] as String? ?? '',
      emergencyContact: map['emergencyContact'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
    );
  }

  /// Alias for fromMap for standard JSON serialization.
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel.fromMap(json);

  /// Creates a model from a Firestore DocumentSnapshot.
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    if (doc.data() == null) {
      return UserModel.empty().copyWith(uid: doc.id);
    }
    final data = doc.data() as Map<String, dynamic>;
    data['uid'] = doc.id; // Ensure UID is always present
    return UserModel.fromMap(data);
  }

  /// Helper to safely parse Timestamps.
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
