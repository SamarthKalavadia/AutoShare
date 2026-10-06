import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/firestore_service.dart';
import '../../core/utils/result.dart';
import '../models/user_model.dart';

/// Repository responsible for all User-related database operations.
class UserRepository {
  final FirestoreService _firestoreService;

  UserRepository({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

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

      if (!doc.exists) {
        try {
          final querySnap = await _firestoreService.usersCollection
              .where('uid', isEqualTo: uid)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 8));
          if (querySnap.docs.isNotEmpty) {
            return Success(UserModel.fromDocument(querySnap.docs.first));
          }
        } catch (_) {}
        return const Failure(
          'User not found.',
          FirestoreException('User document does not exist.'),
        );
      }
      return Success(UserModel.fromDocument(doc));
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
      await _firestoreService.usersCollection.doc(uid).update(updates);

      return const Success(null);
    } on FirebaseException catch (e) {
      // ignore: avoid_print
      print('UserRepository.updateProfile Error: \$e');
      return Failure(
        e.message ?? 'Failed to update profile.',
        FirestoreException(e.code),
      );
    } catch (e) {
      // ignore: avoid_print
      print('UserRepository.updateProfile Unknown Error: \$e');
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  /// Updates the profile image URL.
  Future<Result<void>> updateProfileImage(String uid, String imageUrl) async {
    try {
      await _firestoreService.usersCollection.doc(uid).update({
        'profileImage': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
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

  /// Checks if a user document exists.
  Future<Result<bool>> checkUserExists(String uid) async {
    try {
      final doc = await _firestoreService.usersCollection.doc(uid).get();
      return Success(doc.exists);
    } on FirebaseException catch (e) {
      // ignore: avoid_print
      print('UserRepository.checkUserExists Error: \$e');
      return Failure(
        e.message ?? 'Failed to check user existence.',
        FirestoreException(e.code),
      );
    } catch (e) {
      // ignore: avoid_print
      print('UserRepository.checkUserExists Unknown Error: \$e');
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }
}
