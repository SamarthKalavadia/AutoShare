import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../shared/providers.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

// ─── Enum for grouping ────────────────────────────────────────────────────────

enum NotificationGroup { today, yesterday, older }

class GroupedNotifications {
  final List<NotificationModel> today;
  final List<NotificationModel> yesterday;
  final List<NotificationModel> older;

  const GroupedNotifications({
    required this.today,
    required this.yesterday,
    required this.older,
  });

  bool get isEmpty => today.isEmpty && yesterday.isEmpty && older.isEmpty;
  int get total => today.length + yesterday.length + older.length;
}

// ─── Stream Provider ──────────────────────────────────────────────────────────

final rawNotificationsStreamProvider =
    StreamProvider.autoDispose<List<NotificationModel>>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return const Stream.empty();
  return ref
      .watch(notificationRepositoryProvider)
      .streamNotifications(user.uid);
});

// ─── Unread Count ─────────────────────────────────────────────────────────────

final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final notifs = ref.watch(rawNotificationsStreamProvider).value ?? [];
  return notifs.where((n) => !n.isRead).length;
});

// ─── Grouped Notifications ────────────────────────────────────────────────────

final groupedNotificationsProvider =
    Provider.autoDispose<AsyncValue<GroupedNotifications>>((ref) {
  return ref.watch(rawNotificationsStreamProvider).whenData((notifs) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    final today = <NotificationModel>[];
    final yesterday = <NotificationModel>[];
    final older = <NotificationModel>[];

    for (final n in notifs) {
      final d = n.createdAt;
      if (!d.isBefore(todayStart)) {
        today.add(n);
      } else if (!d.isBefore(yesterdayStart)) {
        yesterday.add(n);
      } else {
        older.add(n);
      }
    }

    return GroupedNotifications(today: today, yesterday: yesterday, older: older);
  });
});

// ─── Notification Actions Notifier ───────────────────────────────────────────

class NotificationActionsNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  NotificationRepository get _repo => ref.read(notificationRepositoryProvider);

  String get _userId => ref.read(authControllerProvider).value?.uid ?? '';

  Future<void> markAsRead(String notificationId) async {
    await _repo.markAsRead(_userId, notificationId);
  }

  Future<void> markAllAsRead() async {
    state = true;
    await _repo.markAllAsRead(_userId);
    state = false;
  }

  Future<void> delete(String notificationId) async {
    await _repo.deleteNotification(_userId, notificationId);
  }
}

final notificationActionsProvider =
    NotifierProvider<NotificationActionsNotifier, bool>(
  NotificationActionsNotifier.new,
);

// ─── Helper: Notification Factory ────────────────────────────────────────────

/// Creates a [NotificationModel] ready to be stored in Firestore.
NotificationModel buildNotification({
  required String userId,
  required String title,
  required String body,
  required String type,
  String? relatedId,
}) {
  return NotificationModel(
    id: '',
    userId: userId,
    title: title,
    body: body,
    type: type,
    isRead: false,
    createdAt: DateTime.now(),
    relatedId: relatedId,
  );
}
