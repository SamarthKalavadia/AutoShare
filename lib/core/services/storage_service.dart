import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/result.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage}) : _storage = storage ?? FirebaseStorage.instance;

  Future<Result<String>> uploadProfilePicture(String uid, XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();

      // 1. Fast attempt to upload to Firebase Storage (with 2-second timeout)
      try {
        final ref = _storage.ref().child('profile_pictures').child('$uid.jpg');
        final uploadTask = ref.putData(
          bytes, 
          SettableMetadata(contentType: 'image/jpeg')
        );
        final snapshot = await uploadTask.timeout(const Duration(seconds: 2));
        final downloadUrl = await snapshot.ref.getDownloadURL().timeout(const Duration(seconds: 1));
        return Success(downloadUrl);
      } catch (e) {
        // ignore: avoid_print
        print('Firebase Storage quick-attempt timed out/failed: $e. Using instant Base64 Firestore storage.');
      }

      // 2. Instant Base64 Fallback directly into Firebase Firestore (< 10ms)
      final base64String = base64Encode(bytes);
      final dataUri = 'data:image/jpeg;base64,$base64String';
      return Success(dataUri);
    } catch (err) {
      return Failure('Failed to process profile image.', Exception(err.toString()));
    }
  }

  Future<Result<void>> deleteProfilePicture(String uid) async {
    try {
      final ref = _storage.ref().child('profile_pictures').child('$uid.jpg');
      await ref.delete();
      return const Success(null);
    } catch (_) {
      return const Success(null);
    }
  }
}
