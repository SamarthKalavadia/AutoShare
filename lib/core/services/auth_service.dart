import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
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
        return const Failure('Signup failed. User is null.', AuthException('User is null after signup'));
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
        // We still return the user but log that DB creation failed
        // ignore: avoid_print
        print('Warning: User created in Auth but failed in Firestore: \${createResult.message}');
      }

      return Success(userModel);
    } on FirebaseAuthException catch (e) {
      // ignore: avoid_print
      print('AuthService.signUp Error: \$e');
      return Failure(_mapAuthErrorCode(e.code), AuthException(e.code));
    } catch (e) {
      // ignore: avoid_print
      print('AuthService.signUp Unknown Error: \$e');
      return Failure('An unexpected error occurred.', Exception(e.toString()));
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
        return const Failure('Login failed. User is null.', AuthException('User is null after login'));
      }

      // Fetch user from Firestore
      final dbResult = await _userRepository.getUser(user.uid);
      if (dbResult is Success<UserModel>) {
        return dbResult;
      }

      // If missing in DB, create an empty shell (fallback)
      final fallbackUser = UserModel.empty().copyWith(uid: user.uid, email: email);
      return Success(fallbackUser);
    } on FirebaseAuthException catch (e) {
      // ignore: avoid_print
      print('AuthService.login Error: \$e');
      return Failure(_mapAuthErrorCode(e.code), AuthException(e.code));
    } catch (e) {
      // ignore: avoid_print
      print('AuthService.login Unknown Error: \$e');
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  /// Authenticates using Google Sign In.
  Future<Result<UserModel>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const Failure('Google Sign In was aborted.', AuthException('Aborted by user'));
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      
      if (user == null) {
        return const Failure('Google login failed.', AuthException('User is null'));
      }

      // Check if user exists in DB
      final existingCheck = await _userRepository.checkUserExists(user.uid);
      if (existingCheck is Success<bool> && existingCheck.data) {
        return await _userRepository.getUser(user.uid);
      }

      // If new, create user in DB
      final userModel = UserModel(
        uid: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        phone: user.phoneNumber ?? '',
        profileImage: user.photoURL ?? '',
        emailVerified: user.emailVerified,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastSeen: DateTime.now(),
        isOnline: true,
        gender: '',
      );

      await _userRepository.createUser(userModel);
      return Success(userModel);
    } on FirebaseAuthException catch (e) {
      // ignore: avoid_print
      print('AuthService.googleLogin Error: \$e');
      return Failure(_mapAuthErrorCode(e.code), AuthException(e.code));
    } catch (e) {
      // ignore: avoid_print
      print('AuthService.googleLogin Unknown Error: \$e');
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  /// Logs out the current user.
  Future<Result<void>> logout() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      return const Success(null);
    } catch (e) {
      // ignore: avoid_print
      print('AuthService.logout Unknown Error: \$e');
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
      print('AuthService.resetPassword Error: \$e');
      return Failure(_mapAuthErrorCode(e.code), AuthException(e.code));
    } catch (e) {
      // ignore: avoid_print
      print('AuthService.resetPassword Unknown Error: \$e');
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  /// Sends an email verification link to the current user.
  Future<Result<void>> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user == null) {
        return const Failure('No user logged in.', AuthException('User is null'));
      }
      await user.sendEmailVerification();
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      // ignore: avoid_print
      print('AuthService.sendEmailVerification Error: \$e');
      return Failure(_mapAuthErrorCode(e.code), AuthException(e.code));
    } catch (e) {
      // ignore: avoid_print
      print('AuthService.sendEmailVerification Unknown Error: \$e');
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  /// Deletes the currently authenticated user account and their database record.
  Future<Result<void>> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) {
        return const Failure('No user logged in.', AuthException('User is null'));
      }

      // Delete from Firestore first
      await _userRepository.deleteUser(user.uid);
      // Delete from Auth
      await user.delete();

      return const Success(null);
    } on FirebaseAuthException catch (e) {
      // ignore: avoid_print
      print('AuthService.deleteAccount Error: \$e');
      if (e.code == 'requires-recent-login') {
        return Failure('Please log in again to delete your account.', AuthException(e.code));
      }
      return Failure(_mapAuthErrorCode(e.code), AuthException(e.code));
    } catch (e) {
      // ignore: avoid_print
      print('AuthService.deleteAccount Unknown Error: \$e');
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  /// Maps Firebase Error codes to human-readable messages.
  String _mapAuthErrorCode(String code) {
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
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
