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

  /// Returns true when all compulsory profile fields are filled.
  bool get isProfileComplete =>
      name.trim().isNotEmpty &&
      phone.trim().isNotEmpty &&
      gender.trim().isNotEmpty &&
      city.trim().isNotEmpty;

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
    String photo = '';
    final photoKeys = [
      'profileImage',
      'photoURL',
      'photoUrl',
      'avatar',
      'avatarUrl',
      'profile_image',
      'profile_picture',
      'picture',
      'profilePic',
      'photo',
      'image',
    ];
    for (final k in photoKeys) {
      final v = map[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        photo = v.toString().trim();
        break;
      }
    }

    var userName = (map['name']?.toString() ??
        map['displayName']?.toString() ??
        map['fullName']?.toString() ??
        map['userName']?.toString() ??
        map['user_name']?.toString() ??
        map['username']?.toString() ??
        '').trim();

    final uid = (map['uid']?.toString() ?? map['id']?.toString() ?? '').trim();
    final email = (map['email']?.toString() ??
        map['userEmail']?.toString() ??
        map['mail']?.toString() ??
        '').trim();

    if (userName.isEmpty && email.isNotEmpty && email.contains('@')) {
      userName = email.split('@').first;
    }
    final phone = (map['phone']?.toString() ?? map['phoneNumber']?.toString() ?? '').trim();
    final gender = (map['gender']?.toString() ?? '').trim();
    final city = (map['city']?.toString() ?? '').trim();
    final emergencyContact = (map['emergencyContact']?.toString() ?? '').trim();
    final bio = (map['bio']?.toString() ?? '').trim();

    final emailVerified = map['emailVerified'] == true ||
        map['emailVerified']?.toString().toLowerCase() == 'true' ||
        map['emailVerified'] == 1;

    final isOnline = map['isOnline'] == true ||
        map['isOnline']?.toString().toLowerCase() == 'true' ||
        map['isOnline'] == 1;

    double averageRating = 0.0;
    if (map['averageRating'] is num) {
      averageRating = (map['averageRating'] as num).toDouble();
    } else if (map['averageRating'] != null) {
      averageRating = double.tryParse(map['averageRating'].toString()) ?? 0.0;
    }

    int totalReviews = 0;
    if (map['totalReviews'] is num) {
      totalReviews = (map['totalReviews'] as num).toInt();
    } else if (map['totalReviews'] != null) {
      totalReviews = int.tryParse(map['totalReviews'].toString()) ?? 0;
    }

    List<String> blockedUsers = [];
    if (map['blockedUsers'] is List) {
      blockedUsers = (map['blockedUsers'] as List)
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return UserModel(
      uid: uid,
      name: userName,
      email: email,
      phone: phone,
      profileImage: photo,
      emailVerified: emailVerified,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      lastSeen: _parseTimestamp(map['lastSeen']),
      isOnline: isOnline,
      gender: gender,
      averageRating: averageRating,
      totalReviews: totalReviews,
      blockedUsers: blockedUsers,
      city: city,
      emergencyContact: emergencyContact,
      bio: bio,
    );
  }

  /// Alias for fromMap for standard JSON serialization.
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel.fromMap(json);

  /// Creates a model from a Firestore DocumentSnapshot.
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    try {
      final rawData = doc.data();
      if (rawData == null) {
        return UserModel.empty().copyWith(uid: doc.id);
      }
      final Map<String, dynamic> data = {};
      if (rawData is Map) {
        rawData.forEach((key, value) {
          data[key.toString()] = value;
        });
      }
      if (!data.containsKey('uid') || data['uid'] == null || data['uid'].toString().isEmpty) {
        data['uid'] = doc.id;
      }
      return UserModel.fromMap(data);
    } catch (_) {
      return UserModel.empty().copyWith(uid: doc.id);
    }
  }

  /// Helper to safely parse Timestamps.
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return DateTime.now();
  }
}
