import 'package:flutter_test/flutter_test.dart';
import 'package:autoshare/core/utils/result.dart';
import 'package:autoshare/data/models/user_model.dart';
import 'package:autoshare/data/repositories/user_repository.dart';

class FakeUserRepository implements UserRepository {
  final Map<String, UserModel> users = {};
  bool shouldFailCreation = false;

  @override
  Future<Result<void>> createUser(UserModel user) async {
    if (shouldFailCreation) {
      return const Failure(
        'Firestore creation failed',
        AuthException('DB error'),
      );
    }
    users[user.uid] = user;
    return const Success(null);
  }

  @override
  Future<Result<UserModel>> getUser(String uid) async {
    if (users.containsKey(uid)) {
      return Success(users[uid]!);
    }
    return const Failure('User not found', AuthException('Not found'));
  }

  @override
  Future<Result<bool>> checkUserExists(String uid) async {
    return Success(users.containsKey(uid));
  }

  @override
  Future<Result<void>> updateUser(UserModel user) async {
    users[user.uid] = user;
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteUser(String uid) async {
    users.remove(uid);
    return const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AuthService Google Sign-In Unit Tests', () {
    late FakeUserRepository fakeUserRepository;

    setUp(() {
      fakeUserRepository = FakeUserRepository();
    });

    test(
      'FakeUserRepository checkUserExists returns correct boolean',
      () async {
        const uid = 'google_user_123';
        final initialCheck = await fakeUserRepository.checkUserExists(uid);
        expect(initialCheck, isA<Success<bool>>());
        expect((initialCheck as Success<bool>).data, isFalse);

        final user = UserModel(
          uid: uid,
          name: 'Test Google User',
          email: 'google@example.com',
          phone: '',
          profileImage: 'https://example.com/photo.jpg',
          emailVerified: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastSeen: DateTime.now(),
          isOnline: true,
          gender: '',
        );

        await fakeUserRepository.createUser(user);
        final postCheck = await fakeUserRepository.checkUserExists(uid);
        expect((postCheck as Success<bool>).data, isTrue);

        final fetchedUser = await fakeUserRepository.getUser(uid);
        expect(fetchedUser, isA<Success<UserModel>>());
        expect(
          (fetchedUser as Success<UserModel>).data.email,
          equals('google@example.com'),
        );
      },
    );

    test(
      'FakeUserRepository functions as expected for Google Sign-In persistence',
      () async {
        final repo = fakeUserRepository;
        const uid = 'google_user_999';
        final model = UserModel(
          uid: uid,
          name: 'Google User',
          email: 'googleuser@test.com',
          phone: '',
          profileImage: '',
          emailVerified: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastSeen: DateTime.now(),
          isOnline: true,
          gender: '',
        );

        final saveResult = await repo.createUser(model);
        expect(saveResult, isA<Success<void>>());

        final checkResult = await repo.checkUserExists(uid);
        expect((checkResult as Success<bool>).data, isTrue);
      },
    );
  });
}
