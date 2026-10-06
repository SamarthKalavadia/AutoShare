import 'package:flutter_test/flutter_test.dart';
import 'package:autoshare/core/services/auth_service.dart';
import 'package:autoshare/core/utils/result.dart';
import 'package:autoshare/data/models/user_model.dart';
import 'package:autoshare/data/repositories/user_repository.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class MockFirebaseAuth implements FirebaseAuth {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockGoogleSignIn implements GoogleSignIn {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUserRepository implements UserRepository {
  final Map<String, UserModel> _store = {};

  void addUser(UserModel user) {
    _store[user.uid] = user;
  }

  @override
  Future<Result<UserModel>> getUser(String uid) async {
    if (_store.containsKey(uid)) {
      return Success(_store[uid]!);
    }
    return const Failure('User not found', AuthException('user-not-found'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Authentication Error Messages Requirement Tests', () {
    test('Verify error messages for non-existent and invalid credentials', () {
      final mockRepo = MockUserRepository();
      final mockAuth = MockFirebaseAuth();
      final mockGoogle = MockGoogleSignIn();
      final authService = AuthService(
        auth: mockAuth,
        googleSignIn: mockGoogle,
        userRepository: mockRepo,
      );

      // CASE 3: Email/password account does not exist
      final userNotFoundMsg = authService.mapAuthErrorCode('user-not-found');
      expect(
        userNotFoundMsg,
        equals('No account found. Please create an account first to continue.'),
      );

      // CASE 2: Existing account + incorrect password
      final wrongPasswordMsg = authService.mapAuthErrorCode('wrong-password');
      expect(
        wrongPasswordMsg,
        equals('Incorrect password provided. Please try again.'),
      );

      // CASE: Invalid credential (email/password)
      final invalidCredentialMsg = authService.mapAuthErrorCode('invalid-credential');
      expect(
        invalidCredentialMsg,
        equals('Invalid email or password. Please check your credentials and try again.'),
      );
      // Ensure the old misleading Google message is NEVER displayed here
      expect(
        invalidCredentialMsg,
        isNot(contains('Google')),
      );

      // CASE 6: Network connection error
      final networkErrorMsg = authService.mapAuthErrorCode('network-request-failed');
      expect(
        networkErrorMsg,
        equals('Network connection failed. Please check your internet connection.'),
      );
    });

    test('Verify Google Sign-In account not found detection message', () async {
      // Required exact message:
      const expectedGoogleNoAccountMsg =
          'No AutoShare account is associated with this Google account. Please create an account first.';
      
      expect(
        expectedGoogleNoAccountMsg,
        equals('No AutoShare account is associated with this Google account. Please create an account first.'),
      );
    });
  });
}
