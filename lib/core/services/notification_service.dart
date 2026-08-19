import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Top-level background message handler required by Firebase Cloud Messaging.
/// Runs in an isolated background thread when the app is in the background or killed/closed.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('[FCM BACKGROUND] Push notification received: ${message.messageId}');

  final notification = message.notification;
  final data = message.data;
  final title = notification?.title ?? data['title'] ?? 'AutoShare';
  final body = notification?.body ?? data['body'] ?? '';

  if (body.isNotEmpty || title.isNotEmpty) {
    const androidDetails = AndroidNotificationDetails(
      'autoshare_notifications',
      'AutoShare Notifications',
      channelDescription: 'Real-time notifications for rides, chats, and requests',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );
    const details = NotificationDetails(android: androidDetails);
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: details,
      payload: data['relatedId'] ?? data['rideId'],
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String defaultChannelId = 'autoshare_notifications';
  static const String defaultChannelName = 'AutoShare Notifications';
  static const String chatChannelId = 'chat_messages';
  static const String chatChannelName = 'Chat Messages';

  StreamSubscription<QuerySnapshot>? _notifSubscription;
  final Set<String> _seenNotificationIds = {};
  bool _isInitialNotifSnapshot = true;

  Future<void> init() async {
    tz.initializeTimeZones();

    // 1. Local Notifications initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('[NOTIFICATION TAP] payload: ${response.payload}');
      },
    );

    // 2. Create High Importance Android Notification Channels (Heads-up popups)
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          defaultChannelId,
          defaultChannelName,
          description: 'Real-time notifications for rides, bookings, and alerts',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          chatChannelId,
          chatChannelName,
          description: 'Real-time chat messages and conversations',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'ride_reminders',
          'Ride Reminders',
          description: 'Notifications before a ride starts',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        ),
      );
    }

    // 3. Request Notification Permissions (Android 13+ & iOS)
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );
      debugPrint('[FCM PERMISSION] Status: ${settings.authorizationStatus}');

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Register Background Handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 5. Handle Foreground Push Notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM FOREGROUND] Push message received: ${message.messageId}');
        final notification = message.notification;
        final data = message.data;
        final title = notification?.title ?? data['title'] ?? 'AutoShare';
        final body = notification?.body ?? data['body'] ?? '';

        if (body.isNotEmpty || title.isNotEmpty) {
          showNotification(
            title: title,
            body: body,
            payload: data['relatedId'] ?? data['rideId'],
            channelId: data['type'] == 'chat' ? chatChannelId : defaultChannelId,
            channelName: data['type'] == 'chat' ? chatChannelName : defaultChannelName,
          );
        }
      });

      // 6. Handle App Opened from Notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM OPENED] App opened via notification: ${message.data}');
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM INITIAL] App launched from terminated state via notification: ${initialMessage.data}');
      }

      // 7. Auto-sync FCM Token and start real-time listener if user is authenticated
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid != null && currentUid.isNotEmpty) {
        await syncFcmToken(currentUid);
        startListening(currentUid);
      }
    } catch (e) {
      debugPrint('[FCM INIT ERROR] $e');
    }
  }

  /// Persistent real-time listener for incoming user notifications from Firestore.
  /// Shows instant system heads-up notifications (like WhatsApp) whenever a new notification is generated.
  void startListening(String uid) {
    if (uid.isEmpty) return;
    _notifSubscription?.cancel();
    _isInitialNotifSnapshot = true;

    _notifSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      if (_isInitialNotifSnapshot) {
        for (final doc in snapshot.docs) {
          _seenNotificationIds.add(doc.id);
        }
        _isInitialNotifSnapshot = false;
        return;
      }

      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final docId = change.doc.id;
          if (!_seenNotificationIds.contains(docId)) {
            _seenNotificationIds.add(docId);
            final data = change.doc.data();
            if (data != null) {
              final title = (data['title'] as String?) ?? 'AutoShare';
              final body = (data['body'] as String?) ?? '';
              final type = (data['type'] as String?) ?? '';
              final relatedId = (data['relatedId'] as String?) ?? '';

              if (body.isNotEmpty || title.isNotEmpty) {
                showNotification(
                  id: docId.hashCode,
                  title: title,
                  body: body,
                  payload: relatedId,
                  channelId: type == 'chat' ? chatChannelId : defaultChannelId,
                  channelName: type == 'chat' ? chatChannelName : defaultChannelName,
                );
              }
            }
          }
        }
      }
    }, onError: (error) {
      debugPrint('[REALTIME NOTIF ERROR] $error');
    });
  }

  /// Displays a heads-up system tray notification (like WhatsApp) with sound and vibration.
  Future<void> showNotification({
    int? id,
    required String title,
    required String body,
    String? payload,
    String channelId = defaultChannelId,
    String channelName = defaultChannelName,
  }) async {
    try {
      final bigTextStyleInformation = BigTextStyleInformation(
        body,
        htmlFormatBigText: false,
        contentTitle: title,
        htmlFormatContentTitle: false,
        summaryText: 'AutoShare',
        htmlFormatSummaryText: false,
      );

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Real-time notifications for rides, chats, and requests',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFFFC400),
        playSound: true,
        enableVibration: true,
        styleInformation: bigTextStyleInformation,
        visibility: NotificationVisibility.public,
      );
      final details = NotificationDetails(android: androidDetails);
      await _flutterLocalNotificationsPlugin.show(
        id: id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NOTIFICATION SHOW ERROR] $e');
    }
  }

  /// Saves and continuously keeps the device's FCM Token synced in Firestore for the given [uid].
  Future<void> syncFcmToken(String uid) async {
    if (uid.isEmpty) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fcmToken': token,
          'fcmTokens': FieldValue.arrayUnion([token]),
          'lastTokenUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('[FCM TOKEN] Successfully synced token for $uid');
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fcmToken': newToken,
          'fcmTokens': FieldValue.arrayUnion([newToken]),
          'lastTokenUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('[FCM TOKEN REFRESHED] Updated token for $uid');
      });
    } catch (e) {
      debugPrint('[FCM TOKEN SYNC ERROR] $e');
    }
  }

  Future<void> scheduleRideReminder(
    String rideId,
    DateTime departureTime,
  ) async {
    try {
      final reminders = {
        '30 min': departureTime.subtract(const Duration(minutes: 30)),
        '15 min': departureTime.subtract(const Duration(minutes: 15)),
        '5 min': departureTime.subtract(const Duration(minutes: 5)),
      };

      int i = 0;
      for (final entry in reminders.entries) {
        if (entry.value.isAfter(DateTime.now())) {
          try {
            await _flutterLocalNotificationsPlugin.zonedSchedule(
              id: rideId.hashCode + i,
              title: 'Ride Starting Soon',
              body: 'Your ride starts in ${entry.key}. Please get ready!',
              scheduledDate: tz.TZDateTime.from(entry.value, tz.local),
              notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                  'ride_reminders',
                  'Ride Reminders',
                  channelDescription: 'Notifications before a ride starts',
                  importance: Importance.high,
                  priority: Priority.high,
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            );
          } catch (_) {
            // Fallback to inexact scheduling if exact alarms are not allowed
            await _flutterLocalNotificationsPlugin.zonedSchedule(
              id: rideId.hashCode + i,
              title: 'Ride Starting Soon',
              body: 'Your ride starts in ${entry.key}. Please get ready!',
              scheduledDate: tz.TZDateTime.from(entry.value, tz.local),
              notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                  'ride_reminders',
                  'Ride Reminders',
                  channelDescription: 'Notifications before a ride starts',
                  importance: Importance.high,
                  priority: Priority.high,
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
          }
        }
        i++;
      }
    } catch (_) {
      // Ignore notification failures gracefully to never crash ride operations
    }
  }
}
