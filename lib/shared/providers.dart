import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/auth_service.dart';
import '../core/services/firestore_service.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/ride_request_repository.dart';
import '../data/repositories/ride_repository.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/notification_repository.dart';
// ─── Infrastructure ───────────────────────────────────────────────────────────

/// Provides the singleton [FirestoreService] used for all collection references.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// ─── Repositories ─────────────────────────────────────────────────────────────

/// Provides the [UserRepository] with its Firestore dependency injected.
/// Uses ref.watch so the repository is recreated if its dependency changes.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(firestoreService: ref.watch(firestoreServiceProvider));
});

/// Provides the [ProfileRepository] with its dependencies injected.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    userRepository: ref.watch(userRepositoryProvider),
  );
});

/// Provides the [RideRequestRepository] with its Firestore dependency injected.
final rideRequestRepositoryProvider = Provider<RideRequestRepository>((ref) {
  return RideRequestRepository(
    firestoreService: ref.watch(firestoreServiceProvider),
  );
});

final rideRepositoryProvider = Provider<RideRepository>((ref) {
  return RideRepository(
    firestoreService: ref.watch(firestoreServiceProvider),
  );
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    firestoreService: ref.watch(firestoreServiceProvider),
  );
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

// ─── Services ─────────────────────────────────────────────────────────────────

/// Provides the [AuthService] with its dependencies explicitly injected.
/// No internal fallback construction — fully managed by Riverpod.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(userRepository: ref.watch(userRepositoryProvider));
});

// ─── Auth State ───────────────────────────────────────────────────────────────

/// Streams the Firebase authentication state.
/// Yields [User?] — null when signed out, populated when signed in.
/// This stream always emits immediately with the current Firebase cached user,
/// so authStateProvider will not stay in loading state for long.
final authStateProvider = StreamProvider((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
