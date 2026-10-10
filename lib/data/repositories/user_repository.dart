import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/firestore_service.dart';
import '../../core/utils/result.dart';
import '../models/user_model.dart';

/// Repository responsible for all User-related database operations.
class UserRepository {
  final FirestoreService _firestoreService;

  UserRepository({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  UserModel _healUserIfNeeded(UserModel user, String uid, User? fbUser) {
    if (fbUser == null || fbUser.uid != uid) {
      if (user.name.trim().isEmpty) {
        final fallback = user.email.isNotEmpty && user.email.contains('@')
            ? user.email.split('@').first
            : 'AutoShare User';
        return user.copyWith(name: fallback);
      }
      return user;
    }

    // Do NOT write phantom updates to Firestore if the user document is empty/unregistered
    if (user.phone.trim().isEmpty) {
      return user;
    }

    bool needsUpdate = false;
    final Map<String, dynamic> updates = {};
    var healed = user;

    if (healed.name.trim().isEmpty) {
      final resolvedName = (fbUser.displayName != null && fbUser.displayName!.trim().isNotEmpty)
          ? fbUser.displayName!.trim()
          : (healed.email.isNotEmpty && healed.email.contains('@')
              ? healed.email.split('@').first
              : (fbUser.email != null && fbUser.email!.contains('@')
                  ? fbUser.email!.split('@').first
                  : 'AutoShare User'));
      healed = healed.copyWith(name: resolvedName);
      updates['name'] = resolvedName;
      needsUpdate = true;
    }

    if (healed.email.trim().isEmpty && fbUser.email != null && fbUser.email!.isNotEmpty) {
      healed = healed.copyWith(email: fbUser.email);
      updates['email'] = fbUser.email;
      needsUpdate = true;
    }

    if (healed.profileImage.trim().isEmpty && fbUser.photoURL != null && fbUser.photoURL!.isNotEmpty) {
      healed = healed.copyWith(profileImage: fbUser.photoURL);
      updates['profileImage'] = fbUser.photoURL;
      needsUpdate = true;
    }

    if (fbUser.emailVerified && !healed.emailVerified) {
      healed = healed.copyWith(emailVerified: true);
      updates['emailVerified'] = true;
      needsUpdate = true;
    }

    if (needsUpdate) {
      unawaited(
        _firestoreService.usersCollection
            .doc(uid)
            .set(updates, SetOptions(merge: true))
            .catchError((_) {}),
      );
    }

    return healed;
  }

  /// Retrieves a user by their [uid].
  Future<Result<UserModel>> getUser(String uid) async {
    if (uid.isEmpty) {
      return const Failure(
        'Empty UID.',
        FirestoreException('UID is empty.'),
      );
    }
    try {
      DocumentSnapshot doc;
      try {
        doc = await _firestoreService.usersCollection
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 8));
      } catch (e) {
        // Fallback to cache if network timeout or offline
        try {
          doc = await _firestoreService.usersCollection
              .doc(uid)
              .get(const GetOptions(source: Source.cache));
        } catch (_) {
          rethrow;
        }
      }

      User? fbUser;
      try {
        fbUser = FirebaseAuth.instance.currentUser;
      } catch (_) {}

      if (!doc.exists) {
        try {
          final querySnap = await _firestoreService.usersCollection
              .where('uid', isEqualTo: uid)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 8));
          if (querySnap.docs.isNotEmpty) {
            final user = UserModel.fromDocument(querySnap.docs.first);
            if (user.phone.trim().isNotEmpty) {
              return Success(_healUserIfNeeded(user, uid, fbUser));
            }
          }
        } catch (_) {}

        return const Failure(
          'User not found.',
          FirestoreException('User document does not exist.'),
        );
      }

      final rawUser = UserModel.fromDocument(doc);
      if (rawUser.phone.trim().isEmpty) {
        return const Failure(
          'User not registered.',
          FirestoreException('User document does not contain completed registration data.'),
        );
      }
      return Success(_healUserIfNeeded(rawUser, uid, fbUser));
    } on FirebaseException catch (e) {
      debugPrint('UserRepository.getUser FirebaseException: $e');
      return Failure(
        e.message ?? 'Failed to fetch user.',
        FirestoreException(e.code),
      );
    } catch (e, stack) {
      debugPrint('UserRepository.getUser Unknown Error: $e\n$stack');
      return Failure('An unexpected error occurred: $e', Exception(e.toString()));
    }
  }

  /// Creates a new user in the database.
  Future<Result<void>> createUser(UserModel user) async {
    try {
      await _firestoreService.usersCollection.doc(user.uid).set(user.toMap());
      return const Success(null);
    } on FirebaseException catch (e) {
      // ignore: avoid_print
      print('UserRepository.createUser Error: \$e');
      return Failure(
        e.message ?? 'Failed to create user.',
        FirestoreException(e.code),
      );
    } catch (e) {
      // ignore: avoid_print
      print('UserRepository.createUser Unknown Error: \$e');
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  /// Updates an entire user document.
  Future<Result<void>> updateUser(UserModel user) async {
    try {
      final data = user.copyWith(updatedAt: DateTime.now()).toMap();
      await _firestoreService.usersCollection.doc(user.uid).update(data);
      return const Success(null);
    } on FirebaseException catch (e) {
      // ignore: avoid_print
      print('UserRepository.updateUser Error: \$e');
      return Failure(
        e.message ?? 'Failed to update user.',
        FirestoreException(e.code),
      );
    } catch (e) {
      // ignore: avoid_print
      print('UserRepository.updateUser Unknown Error: \$e');
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  /// Updates a user's profile with arbitrary fields.
  Future<Result<void>> updateProfile({
    required String uid,
    required Map<String, dynamic> updates,
  }) async {
    try {
      if (updates.isEmpty) return const Success(null);

      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestoreService.usersCollection
          .doc(uid)
          .set(updates, SetOptions(merge: true));

      return const Success(null);
    } on FirebaseException catch (e) {
      // ignore: avoid_print
      print('UserRepository.updateProfile Error: $e');
      return Failure(
        e.message ?? 'Failed to update profile.',
        FirestoreException(e.code),
      );
    } catch (e) {
      // ignore: avoid_print
      print('UserRepository.updateProfile Unknown Error: $e');
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  /// Updates the profile image URL.
  Future<Result<void>> updateProfileImage(String uid, String imageUrl) async {
    try {
      await _firestoreService.usersCollection.doc(uid).set({
        'profileImage': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return const Success(null);
    } on FirebaseException catch (e) {
      // ignore: avoid_print
      print('UserRepository.updateProfileImage Error: \$e');
      return Failure(
        e.message ?? 'Failed to update profile image.',
        FirestoreException(e.code),
      );
    } catch (e) {
      // ignore: avoid_print
      print('UserRepository.updateProfileImage Unknown Error: $e');
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  /// Streams real-time updates for a user.
  Stream<Result<UserModel>> streamUser(String uid) async* {
    if (uid.isEmpty) {
      yield const Failure('Empty UID', FirestoreException('UID is empty.'));
      return;
    }
    try {
      await for (final doc
          in _firestoreService.usersCollection.doc(uid).snapshots()) {
        if (doc.exists) {
          yield Success(UserModel.fromDocument(doc));
        } else {
          try {
            final query = await _firestoreService.usersCollection
                .where('uid', isEqualTo: uid)
                .limit(1)
                .get();
            if (query.docs.isNotEmpty) {
              yield Success(UserModel.fromDocument(query.docs.first));
              continue;
            }
          } catch (_) {}
          yield const Failure(
            'User not found.',
            FirestoreException('User document does not exist.'),
          );
        }
      }
    } catch (e) {
      debugPrint('UserRepository.streamUser Error: $e');
      yield Failure('Failed to stream user data.', Exception(e.toString()));
    }
  }

  /// Deletes a user document.
  Future<Result<void>> deleteUser(String uid) async {
    try {
      await _firestoreService.usersCollection.doc(uid).delete();
      try {
        final chatsSnap = await _firestoreService.chatsCollection
            .where('participants', arrayContains: uid)
            .get();
        for (final doc in chatsSnap.docs) {
          await doc.reference.delete();
        }
      } catch (_) {}
      return const Success(null);
    } on FirebaseException catch (e) {
      // ignore: avoid_print
      print('UserRepository.deleteUser Error: \$e');
      return Failure(
        e.message ?? 'Failed to delete user.',
        FirestoreException(e.code),
      );
    } catch (e) {
      // ignore: avoid_print
      print('UserRepository.deleteUser Unknown Error: \$e');
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  /// Searches users by name (Basic prefix search).
  Future<Result<List<UserModel>>> searchUser(String query) async {
    try {
      if (query.isEmpty) return const Success([]);

      // Basic prefix search — Firestore range query ending with Unicode high surrogate.
      final snapshot = await _firestoreService.usersCollection
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      final users = snapshot.docs
          .map((doc) => UserModel.fromDocument(doc))
          .toList();
      return Success(users);
    } on FirebaseException catch (e) {
      // ignore: avoid_print
      print('UserRepository.searchUser Error: \$e');
      return Failure(
        e.message ?? 'Failed to search users.',
        FirestoreException(e.code),
      );
    } catch (e) {
      // ignore: avoid_print
      print('UserRepository.searchUser Unknown Error: \$e');
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  /// Checks if a phone number is already in use by another user.
  /// Returns Success(true) if unique, Success(false) if already taken.
  Future<Result<bool>> isPhoneNumberUnique({
    required String phone,
    required String currentUid,
  }) async {
    if (phone.trim().isEmpty) {
      return const Success(true); // Empty phone is trivially "unique"
    }
    // Firestore rules require authentication to query the users collection
    if (FirebaseAuth.instance.currentUser == null) {
      return const Success(true);
    }
    try {
      final snapshot = await _firestoreService.usersCollection
          .where('phone', isEqualTo: phone.trim())
          .limit(5)
          .get()
          .timeout(const Duration(seconds: 8));

      // Filter out the current user's own document
      final otherUsers = snapshot.docs
          .where((doc) => doc.id != currentUid)
          .toList();

      return Success(otherUsers.isEmpty);
    } on FirebaseException catch (e) {
      debugPrint('UserRepository.isPhoneNumberUnique FirebaseException: $e');
      if (e.code == 'permission-denied') {
        // If security rules disallow querying other user documents, treat as unique
        // rather than failing and blocking the entire auth/profile flow.
        return const Success(true);
      }
      return Failure(
        e.message ?? 'Failed to check phone uniqueness.',
        FirestoreException(e.code),
      );
    } catch (e) {
      debugPrint('UserRepository.isPhoneNumberUnique Unknown Error: $e');
      return Failure(
        'An unexpected error occurred.',
        Exception(e.toString()),
      );
    }
  }

  /// Checks if a user document exists.
  Future<Result<bool>> checkUserExists(String uid) async {
    try {
      final doc = await _firestoreService.usersCollection.doc(uid).get();
      return Success(doc.exists);
    } on FirebaseException catch (e) {
      // ignore: avoid_print
      print('UserRepository.checkUserExists Error: $e');
      return Failure(
        e.message ?? 'Failed to check user existence.',
        FirestoreException(e.code),
      );
    } catch (e) {
      // ignore: avoid_print
      print('UserRepository.checkUserExists Unknown Error: $e');
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  /// Retrieves a user by their email address.
  Future<Result<UserModel>> getUserByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      return const Failure('Empty email.', FirestoreException('Email is empty.'));
    }
    try {
      final snapshot = await _firestoreService.usersCollection
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 8));
      if (snapshot.docs.isNotEmpty) {
        final user = UserModel.fromDocument(snapshot.docs.first);
        if (user.phone.trim().isNotEmpty) {
          return Success(user);
        }
      }

      // Check original case as fallback
      if (email.trim() != cleanEmail) {
        final snapOriginal = await _firestoreService.usersCollection
            .where('email', isEqualTo: email.trim())
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 8));
        if (snapOriginal.docs.isNotEmpty) {
          final user = UserModel.fromDocument(snapOriginal.docs.first);
          if (user.phone.trim().isNotEmpty) {
            return Success(user);
          }
        }
      }

      return const Failure('User not found.', FirestoreException('user-not-found'));
    } catch (e) {
      return Failure('Error finding user by email: $e', Exception(e.toString()));
    }
  }
}
