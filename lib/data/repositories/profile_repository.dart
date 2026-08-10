import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/services/storage_service.dart';
import '../../core/utils/result.dart';
import '../models/user_model.dart';
import 'user_repository.dart';

/// Repository for handling Profile related operations including Image Uploads via Firebase.
class ProfileRepository {
  final UserRepository _userRepository;
  final StorageService _storageService;

  ProfileRepository({
    UserRepository? userRepository,
    StorageService? storageService,
  })  : _userRepository = userRepository ?? UserRepository(),
        _storageService = storageService ?? StorageService();

  /// Fetches a user's profile from Firestore.
  Future<Result<UserModel>> getProfile(String uid) {
    return _userRepository.getUser(uid);
  }

  /// Streams real-time profile updates.
  Stream<Result<UserModel>> streamProfile(String uid) {
    return _userRepository.streamUser(uid);
  }

  /// Updates general profile information like name and phone.
  Future<Result<void>> updateProfile({
    required String uid,
    String? name,
    String? phone,
  }) async {
    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;

    final result = await _userRepository.updateProfile(
      uid: uid,
      updates: updates,
    );
    return result;
  }

  /// Uploads a new profile image using Firebase (Storage / Firestore) and updates Firestore database.
  /// Returns the updated [UserModel].
  Future<Result<UserModel>> uploadProfileImage({
    required String uid,
    required XFile imageFile,
  }) async {
    try {
      // 1. Upload via Firebase StorageService (Firebase Storage + Firebase Firestore Base64 fallback)
      final fbResult = await _storageService.uploadProfilePicture(uid, imageFile);
      if (fbResult is Failure<String>) {
        return Failure(fbResult.message, fbResult.exception);
      }

      final imageUrl = (fbResult as Success<String>).data;

      // 2. Update Firebase Firestore document with the new profileImage (URL or Base64 Data URI)
      final updateResult = await _userRepository.updateProfileImage(uid, imageUrl);
      
      if (updateResult is Failure<void>) {
        return Failure(updateResult.message, updateResult.exception);
      }

      // 3. Sync photoURL with FirebaseAuth
      try {
        if (imageUrl.startsWith('http')) {
          await FirebaseAuth.instance.currentUser?.updatePhotoURL(imageUrl);
        }
      } catch (_) {}

      // 4. Return the updated user model from Firebase
      return await _userRepository.getUser(uid);
    } catch (e) {
      // ignore: avoid_print
      print('ProfileRepository.uploadProfileImage Unknown Error: $e');
      return Failure('An unexpected error occurred during image upload.', Exception(e.toString()));
    }
  }

  /// Removes the user's profile image from Firebase Firestore & Storage.
  Future<Result<UserModel>> removeProfileImage(String uid) async {
    try {
      // 1. Clear profile image in Firebase Firestore
      final updateResult = await _userRepository.updateProfileImage(uid, '');
      
      if (updateResult is Failure<void>) {
        return Failure(updateResult.message, updateResult.exception);
      }

      // 2. Clear Firebase Storage picture & FirebaseAuth photoURL
      try {
        await _storageService.deleteProfilePicture(uid);
        await FirebaseAuth.instance.currentUser?.updatePhotoURL(null);
      } catch (_) {}

      // 3. Return the updated user model
      return await _userRepository.getUser(uid);
    } catch (e) {
      // ignore: avoid_print
      print('ProfileRepository.removeProfileImage Unknown Error: $e');
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }
}
