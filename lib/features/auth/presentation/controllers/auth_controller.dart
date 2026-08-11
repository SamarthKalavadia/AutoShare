import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/result.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../shared/providers.dart';

/// Riverpod Notifier handling Authentication UI state transitions and operations.
class AuthController extends Notifier<AsyncValue<UserModel?>> {
  late final AuthService _authService;
  late final ProfileRepository _profileRepository;
  late final UserRepository _userRepository;

  @override
  AsyncValue<UserModel?> build() {
    _authService = ref.watch(authServiceProvider);
    _profileRepository = ref.watch(profileRepositoryProvider);
    _userRepository = ref.watch(userRepositoryProvider);

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      _fetchUserModel(firebaseUser.uid);
      return const AsyncValue.loading();
    }
    return const AsyncValue.data(null);
  }

  Future<void> _fetchUserModel(String uid) async {
    final result = await _userRepository.getUser(uid);
    if (result is Success<UserModel>) {
      UserModel user = result.data;
      if (user.profileImage.isEmpty) {
        final fbPhoto = FirebaseAuth.instance.currentUser?.photoURL;
        if (fbPhoto != null && fbPhoto.isNotEmpty) {
          user = user.copyWith(profileImage: fbPhoto);
          await _userRepository.updateProfileImage(uid, fbPhoto);
        }
      }
      state = AsyncValue.data(user);
    } else {
      state = const AsyncValue.data(null);
    }
  }

  /// Log in with Email and Password
  Future<Result<UserModel>> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final result = await _authService.loginWithEmail(
      email: email,
      password: password,
    );

    if (result is Success<UserModel>) {
      UserModel userModel = result.data;
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        userModel = userModel.copyWith(
          emailVerified: firebaseUser.emailVerified,
          lastSeen: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _userRepository.updateUser(userModel);
      }
      state = AsyncValue.data(userModel);
      return Success(userModel);
    } else {
      state = const AsyncValue.data(null);
      return result;
    }
  }

  /// Sign up with Email, Password, Name, Phone, Gender, and optional Profile Image
  Future<Result<UserModel>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String gender,
    XFile? profileImageFile,
  }) async {
    state = const AsyncValue.loading();

    final signupResult = await _authService.signUpWithEmail(
      name: name,
      email: email,
      password: password,
    );

    if (signupResult is Failure<UserModel>) {
      state = const AsyncValue.data(null);
      return signupResult;
    }

    UserModel user = (signupResult as Success<UserModel>).data;

    // Upload image if provided
    String imageUrl = '';
    if (profileImageFile != null) {
      final uploadResult = await _profileRepository.uploadProfileImage(
        uid: user.uid,
        imageFile: profileImageFile,
      );
      if (uploadResult is Success<UserModel>) {
        user = uploadResult.data;
        imageUrl = user.profileImage;
      }
    }

    // Update phone, gender & profile picture in Firestore if specified
    final updatedModel = user.copyWith(
      phone: phone,
      gender: gender,
      profileImage: imageUrl.isNotEmpty ? imageUrl : user.profileImage,
    );

    await _userRepository.updateUser(updatedModel);

    // Send email verification
    await _authService.sendEmailVerification();

    state = AsyncValue.data(updatedModel);
    return Success(updatedModel);
  }

  /// Sign in with Google
  Future<Result<UserModel>> signInWithGoogle() async {
    state = const AsyncValue.loading();
    final result = await _authService.signInWithGoogle();

    if (result is Success<UserModel>) {
      UserModel userModel = result.data;
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        userModel = userModel.copyWith(
          emailVerified: firebaseUser.emailVerified,
          lastSeen: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _userRepository.updateUser(userModel);
      }
      state = AsyncValue.data(userModel);
      return Success(userModel);
    } else {
      state = const AsyncValue.data(null);
      return result;
    }
  }

  /// Send password reset email
  Future<Result<void>> sendPasswordReset(String email) async {
    return await _authService.resetPassword(email);
  }

  /// Send email verification
  Future<Result<void>> sendEmailVerification() async {
    return await _authService.sendEmailVerification();
  }

  Future<Result<void>> deleteAccount() async {
    state = const AsyncValue.loading();
    final result = await _authService.deleteAccount();
    if (result is Success) {
      state = const AsyncValue.data(null);
    } else {
      // Revert state if deletion fails, though ideally we'd re-fetch.
      // But keeping it as is or reloading user is safer. Let's just reload.
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        _fetchUserModel(firebaseUser.uid);
      } else {
        state = const AsyncValue.data(null);
      }
    }
    return result;
  }

  /// Manually syncs local state after an external repository update (e.g. Edit Profile)
  void updateUser(UserModel updatedUser) {
    state = AsyncValue.data(updatedUser);
  }

  Future<Result<void>> resetPassword(String email) async {
    return await _authService.resetPassword(email);
  }

  /// Reload current user status
  Future<User?> reloadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;
      
      if (updatedUser != null && updatedUser.emailVerified) {
        final fetchUserResult = await _userRepository.getUser(updatedUser.uid);
        if (fetchUserResult is Success<UserModel>) {
          UserModel currentUserModel = fetchUserResult.data;
          if (!currentUserModel.emailVerified) {
            final syncedModel = currentUserModel.copyWith(
              emailVerified: true,
              updatedAt: DateTime.now(),
              lastSeen: DateTime.now(),
            );
            await _userRepository.updateUser(syncedModel);
            if (state.value?.uid == updatedUser.uid) {
              state = AsyncValue.data(syncedModel);
            }
          }
        }
      }
      
      return updatedUser;
    }
    return null;
  }

  /// Complete missing profile fields (Phone, Gender, DOB, City, Emergency Contact, Image)
  Future<Result<void>> completeProfile({
    required String uid,
    required String phone,
    required String gender,
    required String dob,
    required String city,
    required String emergencyContact,
    XFile? profileImageFile,
  }) async {
    state = const AsyncValue.loading();
    try {
      String imageUrl = '';
      if (profileImageFile != null) {
        final uploadResult = await _profileRepository.uploadProfileImage(
          uid: uid,
          imageFile: profileImageFile,
        );
        if (uploadResult is Success<UserModel>) {
          imageUrl = uploadResult.data.profileImage;
        }
      }

      final fetchUserResult = await _userRepository.getUser(uid);
      UserModel current = fetchUserResult is Success<UserModel>
          ? fetchUserResult.data
          : UserModel.empty().copyWith(uid: uid);

      final updatedUser = current.copyWith(
        phone: phone,
        gender: gender,
        city: city,
        emergencyContact: emergencyContact,
        profileImage: imageUrl.isNotEmpty ? imageUrl : current.profileImage,
        updatedAt: DateTime.now(),
      );

      final updateDbResult = await _userRepository.updateUser(updatedUser);
      if (updateDbResult is Failure) {
        state = AsyncValue.data(current);
        return updateDbResult;
      }

      state = AsyncValue.data(updatedUser);
      return const Success(null);
    } catch (e) {
      state = const AsyncValue.data(null);
      return Failure('Failed to update profile details.', Exception(e.toString()));
    }
  }

  /// Logout
  Future<Result<void>> logout() async {
    state = const AsyncValue.loading();
    final result = await _authService.logout();
    state = const AsyncValue.data(null);
    return result;
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<UserModel?>>(AuthController.new);
