import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'notification_service.dart';
import '../utils/result.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

/// Centralized service handling all Firebase Authentication.
class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final UserRepository _userRepository;

  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    required UserRepository userRepository,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _googleSignIn =
           googleSignIn ??
           GoogleSignIn(
             scopes: const <String>['email', 'profile'],
           ),
       // ignore: prefer_initializing_formals
       _userRepository = userRepository;

  /// Stream of current user's authentication state.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Gets the currently authenticated Firebase user.
  User? get currentUser => _auth.currentUser;

  /// Signs up a new user using email and password.
  Future<Result<UserModel>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return const Failure(
          'Signup failed. User is null.',
          AuthException('User is null after signup'),
        );
      }

      await user.updateDisplayName(name);

      final userModel = UserModel(
        uid: user.uid,
        name: name,
        email: email,
        phone: '',
        profileImage: '',
        emailVerified: user.emailVerified,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastSeen: DateTime.now(),
        isOnline: true,
        gender: '',
      );

      // Save user to Firestore
      final createResult = await _userRepository.createUser(userModel);
      if (createResult is Failure) {
        // ignore: avoid_print
        print(
          'Warning: User created in Auth but failed in Firestore: ${createResult.message}',
        );
      }

      return Success(userModel);
    } on FirebaseAuthException catch (e) {
      // ignore: avoid_print
      print('AuthService.signUp Error: $e');
      return Failure(
        _mapAuthErrorCode(e.code, defaultMessage: e.message),
        AuthException(e.code),
      );
    } catch (e) {
      // ignore: avoid_print
      print('AuthService.signUp Unknown Error: $e');
      return Failure(_mapGenericErrorMessage(e), Exception(e.toString()));
    }
  }

  /// Logs in an existing user using email and password.
  Future<Result<UserModel>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return const Failure(
          'Login failed. User is null.',
          AuthException('User is null after login'),
        );
      }

      // Fetch user from Firestore
      final dbResult = await _userRepository.getUser(user.uid);
      if (dbResult is Success<UserModel>) {
        return dbResult;
      }

      // If missing in DB, create an empty shell (fallback)
      final fallbackUser = UserModel.empty().copyWith(
        uid: user.uid,
        email: email,
      );
      return Success(fallbackUser);
    } on FirebaseAuthException catch (e) {
      // ignore: avoid_print
      print('AuthService.login Error: $e');
      return Failure(
        _mapAuthErrorCode(e.code, defaultMessage: e.message),
        AuthException(e.code),
      );
    } catch (e) {
      // ignore: avoid_print
      print('AuthService.login Unknown Error: $e');
      return Failure(_mapGenericErrorMessage(e), Exception(e.toString()));
    }
  }

  /// Authenticates using Google Sign In across Web and Mobile/Desktop.
  Future<Result<UserModel>> signInWithGoogle() async {
    try {
      User? user;

      if (kIsWeb) {
        // On Flutter Web, use Firebase Auth's built-in Google Auth Provider popup
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        final UserCredential userCredential = await _auth.signInWithPopup(
          googleProvider,
        );
        user = userCredential.user;
      } else {
        // On Mobile/Desktop, clear any existing stale session first
        try {
          await _googleSignIn.signOut();
        } catch (_) {}

        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          return const Failure(
            'Google Sign In was cancelled.',
            AuthException('Aborted by user'),
          );
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        if (googleAuth.accessToken == null && googleAuth.idToken == null) {
          return const Failure(
            'Failed to obtain Google authentication tokens. Please check your Google Sign-In setup.',
            AuthException('Missing Google tokens'),
          );
        }

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );
        user = userCredential.user;
      }

      if (user == null) {
        return const Failure(
          'Google login failed. User credential is null.',
          AuthException('User is null'),
        );
      }

      // Fetch existing user or create a new user profile
      UserModel userModel;
      final existingResult = await _userRepository.getUser(user.uid);
      if (existingResult is Success<UserModel>) {
        userModel = existingResult.data.copyWith(
          name: existingResult.data.name.isNotEmpty
              ? existingResult.data.name
              : (user.displayName ?? 'User'),
          email: user.email ?? existingResult.data.email,
          profileImage: existingResult.data.profileImage.isNotEmpty
              ? existingResult.data.profileImage
              : (user.photoURL ?? ''),
          emailVerified: user.emailVerified ||
              (user.email != null && user.email!.isNotEmpty),
          lastSeen: DateTime.now(),
          isOnline: true,
        );
        await _userRepository.updateUser(userModel);
      } else {
        userModel = UserModel(
          uid: user.uid,
          name: user.displayName ??
              (user.email != null ? user.email!.split('@').first : 'User'),
          email: user.email ?? '',
          phone: user.phoneNumber ?? '',
          profileImage: user.photoURL ?? '',
          emailVerified: user.emailVerified ||
              (user.email != null && user.email!.isNotEmpty),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastSeen: DateTime.now(),
          isOnline: true,
          gender: '',
        );
        final createResult = await _userRepository.createUser(userModel);
        if (createResult is Failure) {
          debugPrint(
            'Warning: Google user created in Auth but failed in Firestore: ${createResult.message}',
          );
        }
      }

      // Sync FCM token and notifications
      NotificationService().syncFcmToken(user.uid);
      NotificationService().startListening(user.uid);

      return Success(userModel);
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'AuthService.googleLogin FirebaseAuthException: ${e.code} - ${e.message}',
      );
      return Failure(
        _mapAuthErrorCode(e.code, defaultMessage: e.message),
        AuthException(e.code),
      );
    } catch (e) {
      debugPrint('AuthService.googleLogin Unknown Error: $e');
      return Failure(_mapGenericErrorMessage(e), Exception(e.toString()));
    }
  }

  /// Logs out the current user.
  Future<Result<void>> logout() async {
    try {
      await Future.wait([
        _auth.signOut(),
        if (!kIsWeb) _googleSignIn.signOut(),
      ]);
      return const Success(null);
    } catch (e) {
      // ignore: avoid_print
      print('AuthService.logout Error: $e');
      return Failure('Failed to log out.', Exception(e.toString()));
    }
  }

  /// Sends a password reset email.
  Future<Result<void>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      // ignore: avoid_print
      print('AuthService.resetPassword Error: $e');
      return Failure(
        _mapAuthErrorCode(e.code, defaultMessage: e.message),
        AuthException(e.code),
      );
    } catch (e) {
      // ignore: avoid_print
      print('AuthService.resetPassword Unknown Error: $e');
      return Failure(_mapGenericErrorMessage(e), Exception(e.toString()));
    }
  }

  /// Sends an email verification link to the current user.
  Future<Result<void>> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user == null) {
        return const Failure(
          'No user logged in.',
          AuthException('User is null'),
        );
      }
      await user.sendEmailVerification();
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      // ignore: avoid_print
      print('AuthService.sendEmailVerification Error: $e');
      return Failure(
        _mapAuthErrorCode(e.code, defaultMessage: e.message),
        AuthException(e.code),
      );
    } catch (e) {
      // ignore: avoid_print
      print('AuthService.sendEmailVerification Unknown Error: $e');
      return Failure(_mapGenericErrorMessage(e), Exception(e.toString()));
    }
  }

  /// Deletes the currently authenticated user account and their database record.
  Future<Result<void>> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) {
        return const Failure(
          'No user logged in.',
          AuthException('User is null'),
        );
      }

      // Delete from Firestore first
      await _userRepository.deleteUser(user.uid);
      // Delete from Auth
      await user.delete();

      return const Success(null);
    } on FirebaseAuthException catch (e) {
      // ignore: avoid_print
      print('AuthService.deleteAccount Error: $e');
      if (e.code == 'requires-recent-login') {
        return Failure(
          'Please log in again to delete your account.',
          AuthException(e.code),
        );
      }
      return Failure(
        _mapAuthErrorCode(e.code, defaultMessage: e.message),
        AuthException(e.code),
      );
    } catch (e) {
      // ignore: avoid_print
      print('AuthService.deleteAccount Unknown Error: $e');
      return Failure(_mapGenericErrorMessage(e), Exception(e.toString()));
    }
  }

  /// Maps Firebase Error codes to human-readable messages.
  String _mapAuthErrorCode(String code, {String? defaultMessage}) {
    switch (code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The email address is already in use by another account.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid credentials provided for Google Sign-In.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email using a different sign-in method.';
      case 'operation-not-allowed':
        return 'Google Sign-In is not enabled in Firebase Console.';
      case 'popup-closed-by-user':
        return 'Google Sign-In popup was closed before completion.';
      case 'popup-blocked':
        return 'Google Sign-In popup was blocked by your browser.';
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet connection.';
      default:
        return defaultMessage != null && defaultMessage.isNotEmpty
            ? defaultMessage
            : 'Authentication failed ($code). Please try again.';
    }
  }

  /// Maps generic exception objects to user-friendly error messages.
  String _mapGenericErrorMessage(dynamic e) {
    final errString = e.toString().toLowerCase();
    if (errString.contains('sign_in_failed') ||
        errString.contains('api_exception: 10') ||
        errString.contains('apiexception: 10') ||
        errString.contains('code: 10') ||
        errString.contains('developer_error')) {
      return 'Google Sign-In failed (Developer Error 10). Please ensure your SHA-1 fingerprint is added in Firebase Console and Google Sign-In is enabled in Authentication.';
    } else if (errString.contains('12500')) {
      return 'Google Sign-In failed (Error 12500). Please check Google Play Services and ensure a project support email is set in Firebase Console Settings.';
    } else if (errString.contains('canceled') ||
        errString.contains('cancelled') ||
        errString.contains('aborted') ||
        errString.contains('sign_in_canceled')) {
      return 'Google Sign-In was cancelled.';
    } else if (errString.contains('network') ||
        errString.contains('socketexception')) {
      return 'Network error occurred during Google Sign-In. Please check your internet connection.';
    }
    return 'An error occurred during authentication: $e';
  }
}
