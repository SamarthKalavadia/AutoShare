import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/ride_model.dart';
import '../../firebase_options.dart';
import '../routes/app_router.dart';
import '../../features/chat/providers/chat_provider.dart';

const String kDefaultChannelId = 'autoshare_notifications';
const String kDefaultChannelName = 'AutoShare Notifications';
const String kChatChannelId = 'chat_messages';
const String kChatChannelName = 'Chat Messages';
const String kReminderChannelId = 'ride_reminders';
const String kReminderChannelName = 'Ride Reminders';

/// Top-level background message handler required by Firebase Cloud Messaging.
/// Runs in an isolated background Dart VM thread when the app is in the background or killed/closed.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  debugPrint('[FCM BACKGROUND] Push notification received: ${message.messageId}');

  final notification = message.notification;
  final data = message.data;
  final title = notification?.title ?? data['title'] ?? 'AutoShare';
  final body = notification?.body ?? data['body'] ?? '';
  final type = data['type'] as String? ?? 'general';
  final relatedId = data['relatedId'] as String? ?? data['rideId'] as String? ?? '';

  // If the remote message already included a notification payload, Android's
  // system notification manager displays it automatically.
  // We only display via local notifications if it is a data-only message.
  final isDataOnly = notification == null;
  if (isDataOnly && (body.isNotEmpty || title.isNotEmpty)) {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await plugin.initialize(settings: initializationSettings);

      final isChat = type == 'chat';
      final channelId = isChat ? kChatChannelId : kDefaultChannelId;
      final channelName = isChat ? kChatChannelName : kDefaultChannelName;

      final bigTextStyle = BigTextStyleInformation(
        body,
        htmlFormatBigText: false,
        contentTitle: title,
        htmlFormatContentTitle: false,
        summaryText: isChat ? 'New Chat Message' : 'AutoShare',
        htmlFormatSummaryText: false,
      );

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: isChat
            ? 'Real-time chat messages and conversations'
            : 'Real-time notifications for rides, bookings, and alerts',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFFFC400),
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
        styleInformation: bigTextStyle,
        category: isChat ? AndroidNotificationCategory.message : AndroidNotificationCategory.event,
        visibility: NotificationVisibility.public,
      );

      final details = NotificationDetails(android: androidDetails);
      final payloadJson = jsonEncode({
        'type': type,
        'relatedId': relatedId,
        'rideId': relatedId,
      });

      await plugin.show(
        id: message.messageId?.hashCode ??
            DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        notificationDetails: details,
        payload: payloadJson,
      );
    } catch (e) {
      debugPrint('[FCM BACKGROUND SHOW ERROR] $e');
    }
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String defaultChannelId = kDefaultChannelId;
  static const String defaultChannelName = kDefaultChannelName;
  static const String chatChannelId = kChatChannelId;
  static const String chatChannelName = kChatChannelName;

  StreamSubscription<QuerySnapshot>? _notifSubscription;
  final Set<String> _seenNotificationIds = {};
  bool _isInitialNotifSnapshot = true;

  Future<void> init() async {
    try {
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
          _handleNotificationTap(payload: response.payload);
        },
      );

      // 2. Create High Importance Android Notification Channels (Heads-up popups)
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            defaultChannelId,
            defaultChannelName,
            description:
                'Real-time notifications for rides, bookings, and alerts',
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
            kReminderChannelId,
            kReminderChannelName,
            description: 'Notifications before a ride starts',
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
            showBadge: true,
          ),
        );
      }

      // 3. Register Background Handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 4. Request Notification Permissions & FCM Listeners (asynchronous, non-blocking)
      unawaited(_initFcmAsync());
    } catch (e) {
      debugPrint('[NOTIFICATION INIT ERROR] $e');
    }
  }

  Future<void> _initFcmAsync() async {
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
      ).timeout(const Duration(seconds: 4), onTimeout: () {
        return const NotificationSettings(
          authorizationStatus: AuthorizationStatus.notDetermined,
          alert: AppleNotificationSetting.notSupported,
          announcement: AppleNotificationSetting.notSupported,
          badge: AppleNotificationSetting.notSupported,
          carPlay: AppleNotificationSetting.notSupported,
          criticalAlert: AppleNotificationSetting.notSupported,
          lockScreen: AppleNotificationSetting.notSupported,
          notificationCenter: AppleNotificationSetting.notSupported,
          showPreviews: AppleShowPreviewSetting.notSupported,
          timeSensitive: AppleNotificationSetting.notSupported,
          sound: AppleNotificationSetting.notSupported,
          providesAppNotificationSettings: AppleNotificationSetting.notSupported,
        );
      });
      debugPrint('[FCM PERMISSION] Status: ${settings.authorizationStatus}');

      try {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (_) {}

      // Handle Foreground Push Notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM FOREGROUND] Push message received: ${message.messageId}');
        final notification = message.notification;
        final data = message.data;
        final title = notification?.title ?? data['title'] ?? 'AutoShare';
        final body = notification?.body ?? data['body'] ?? '';
        final type = data['type'] as String? ?? 'general';
        final relatedId = data['relatedId'] as String? ?? data['rideId'] as String? ?? '';

        if (body.isNotEmpty || title.isNotEmpty) {
          final payloadJson = jsonEncode({
            'type': type,
            'relatedId': relatedId,
            'rideId': relatedId,
          });

          showNotification(
            title: title,
            body: body,
            payload: payloadJson,
            channelId: type == 'chat' ? chatChannelId : defaultChannelId,
            channelName: type == 'chat' ? chatChannelName : defaultChannelName,
          );
        }
      });

      // Handle App Opened from Notification in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM OPENED] App opened via notification: ${message.data}');
        _handleNotificationTap(data: message.data);
      });

      // Handle App Launched from terminated state via notification
      try {
        final initialMessage = await messaging.getInitialMessage().timeout(const Duration(seconds: 3));
        if (initialMessage != null) {
          debugPrint(
              '[FCM INITIAL] App launched from terminated state via notification: ${initialMessage.data}');
          Future.delayed(const Duration(milliseconds: 600), () {
            _handleNotificationTap(data: initialMessage.data);
          });
        }
      } catch (_) {}

      // Auto-sync FCM Token and start real-time listener if user is authenticated
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid != null && currentUid.isNotEmpty) {
        syncFcmToken(currentUid);
        startListening(currentUid);
      }
    } catch (e) {
      debugPrint('[FCM ASYNC INIT ERROR] $e');
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
                final payloadJson = jsonEncode({
                  'type': type,
                  'relatedId': relatedId,
                  'rideId': relatedId,
                });

                showNotification(
                  id: docId.hashCode,
                  title: title,
                  body: body,
                  payload: payloadJson,
                  channelId: type == 'chat' ? chatChannelId : defaultChannelId,
                  channelName:
                      type == 'chat' ? chatChannelName : defaultChannelName,
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
      final isChat = channelId == chatChannelId;
      final bigTextStyleInformation = BigTextStyleInformation(
        body,
        htmlFormatBigText: false,
        contentTitle: title,
        htmlFormatContentTitle: false,
        summaryText: isChat ? 'New Message' : 'AutoShare',
        htmlFormatSummaryText: false,
      );

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: isChat
            ? 'Real-time chat messages and conversations'
            : 'Real-time notifications for rides, chats, and requests',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFFFC400),
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
        styleInformation: bigTextStyleInformation,
        category: isChat
            ? AndroidNotificationCategory.message
            : AndroidNotificationCategory.event,
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
      final token = await FirebaseMessaging.instance.getToken().timeout(const Duration(seconds: 4));
      if (token != null && token.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fcmToken': token,
          'fcmTokens': FieldValue.arrayUnion([token]),
          'lastTokenUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 4));
        debugPrint('[FCM TOKEN] Successfully synced token for $uid');
      }

      try {
        await FirebaseMessaging.instance.subscribeToTopic('user_$uid').timeout(const Duration(seconds: 4));
      } catch (_) {}

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'fcmToken': newToken,
            'fcmTokens': FieldValue.arrayUnion([newToken]),
            'lastTokenUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)).timeout(const Duration(seconds: 4));
          debugPrint('[FCM TOKEN REFRESHED] Updated token for $uid');
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('[FCM TOKEN SYNC ERROR] $e');
    }
  }

  /// Sends a push notification payload to the recipient's FCM tokens.
  Future<void> sendPushNotification({
    required String recipientUid,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    if (recipientUid.isEmpty) return;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(recipientUid)
          .get()
          .timeout(const Duration(seconds: 4));

      if (!userDoc.exists) return;
      final userData = userDoc.data();
      final tokens = <String>{};

      final singleToken = userData?['fcmToken'] as String?;
      if (singleToken != null && singleToken.isNotEmpty) {
        tokens.add(singleToken);
      }

      final multiTokens = userData?['fcmTokens'];
      if (multiTokens is List) {
        for (final t in multiTokens) {
          if (t is String && t.isNotEmpty) {
            tokens.add(t);
          }
        }
      }

      debugPrint(
          '[FCM PUSH DISPATCH] Recipient: $recipientUid, Title: "$title", Tokens found: ${tokens.length}');

      // 1. Dispatch high-priority FCM v1 push to each registered device token
      // This wakes up terminated devices and displays system notifications directly
      for (final token in tokens) {
        unawaited(_dispatchFcmV1(
          token: token,
          title: title,
          body: body,
          type: type,
          relatedId: relatedId,
        ));
      }

      // 2. Save push delivery record in Firestore to ensure reliable delivery queue
      try {
        await FirebaseFirestore.instance.collection('push_notifications').add({
          'recipientUid': recipientUid,
          'tokens': tokens.toList(),
          'title': title,
          'body': body,
          'type': type,
          'relatedId': relatedId ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'queued',
        }).timeout(const Duration(seconds: 4));
      } catch (_) {}
    } catch (e) {
      debugPrint('[FCM PUSH DISPATCH ERROR] $e');
    }
  }

  static String? _cachedAccessToken;
  static DateTime? _tokenExpiry;

  /// Retrieves an OAuth2 Access Token for Google Cloud Messaging (HTTP v1)
  /// using the Firebase Service Account JSON credentials.
  Future<String?> _getFcmAccessToken() async {
    if (_cachedAccessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedAccessToken;
    }

    try {
      String? jsonStr;
      try {
        jsonStr =
            await rootBundle.loadString('assets/firebase/service-account.json');
      } catch (_) {}

      if (jsonStr == null || jsonStr.trim().isEmpty || jsonStr.trim() == '{}') {
        debugPrint(
            '[FCM v1] No service-account.json found in assets/firebase/. Please place your Firebase service-account.json in assets/firebase/service-account.json to enable notifications for closed apps.');
        return null;
      }

      final creds = ServiceAccountCredentials.fromJson(jsonStr);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(creds, scopes);
      _cachedAccessToken = client.credentials.accessToken.data;
      _tokenExpiry =
          client.credentials.accessToken.expiry.subtract(const Duration(minutes: 5));
      client.close();
      return _cachedAccessToken;
    } catch (e) {
      debugPrint('[FCM v1 AUTH ERROR] Could not get OAuth token: $e');
      return null;
    }
  }

  /// Sends a high-priority heads-up FCM v1 push notification to a device token.
  /// When received, Google Play Services automatically wakes up the device
  /// and shows the heads-up notification in the system notification bar,
  /// even if the app is completely closed / terminated.
  Future<void> _dispatchFcmV1({
    required String token,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    try {
      final accessToken = await _getFcmAccessToken();
      if (accessToken == null) return;

      final isChat = type == 'chat';
      final channelId = isChat ? kChatChannelId : kDefaultChannelId;
      final projectId = DefaultFirebaseOptions.currentPlatform.projectId;

      final url = Uri.parse(
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

      final payload = {
        'message': {
          'token': token,
          'notification': {
            'title': title,
            'body': body,
          },
          'android': {
            'priority': 'HIGH',
            'notification': {
              'channel_id': channelId,
              'sound': 'default',
              'default_sound': true,
              'default_vibrate_timings': true,
              'notification_priority': 'PRIORITY_MAX',
              'visibility': 'PUBLIC',
              'icon': '@mipmap/ic_launcher',
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
          'data': {
            'type': type,
            'relatedId': relatedId ?? '',
            'rideId': relatedId ?? '',
            'title': title,
            'body': body,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
        }
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );

      debugPrint(
          '[FCM v1 DISPATCH RESULT] Token: ${token.length > 12 ? token.substring(0, 12) : token}... Status: ${response.statusCode}');
    } catch (e) {
      debugPrint('[FCM v1 DISPATCH ERROR] $e');
    }
  }

  /// Automatically deep-links and routes the user when tapping on a notification.
  Future<void> _handleNotificationTap({
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    try {
      String? type = data?['type'];
      String? relatedId = data?['relatedId'] ?? data?['rideId'];

      if (payload != null && payload.isNotEmpty) {
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            type ??= decoded['type'];
            relatedId ??= decoded['relatedId'] ?? decoded['rideId'];
          }
        } catch (_) {
          relatedId ??= payload;
        }
      }

      debugPrint('[NOTIFICATION ROUTER] type: $type, relatedId: $relatedId');

      if (type == 'chat' && relatedId != null && relatedId.isNotEmpty) {
        // Fetch ride or pass rideId to open chat screen
        try {
          final rideDoc = await FirebaseFirestore.instance
              .collection('rides')
              .doc(relatedId)
              .get();

          if (rideDoc.exists && rideDoc.data() != null) {
            final ride = RideModel.fromMap(rideDoc.data()!, rideDoc.id);
            final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
            final otherUid = ride.driverId == currentUid ? '' : ride.driverId;
            final otherName = (ride.driverId != currentUid &&
                    ride.driverName.isNotEmpty &&
                    ride.driverName != 'Unknown Driver')
                ? ride.driverName
                : '';
            AppRouter.router.push(
              '/chat',
              extra: ChatPageArgs(
                ride: ride,
                otherParticipantUid: otherUid,
                otherParticipantName: otherName,
              ),
            );
            return;
          }
        } catch (_) {}

        AppRouter.router.push('/chat', extra: relatedId);
      } else if ((type == 'new_request' || type == 'request') &&
          relatedId != null &&
          relatedId.isNotEmpty) {
        AppRouter.router.push('/incoming-requests');
      } else if (type == 'accepted' ||
          type == 'rejected' ||
          type == 'cancelled') {
        AppRouter.router.push('/my-rides');
      } else if (type == 'ride' && relatedId != null && relatedId.isNotEmpty) {
        try {
          final rideDoc = await FirebaseFirestore.instance
              .collection('rides')
              .doc(relatedId)
              .get();

          if (rideDoc.exists && rideDoc.data() != null) {
            final ride = RideModel.fromMap(rideDoc.data()!, rideDoc.id);
            AppRouter.router.push('/ride-details', extra: ride);
            return;
          }
        } catch (_) {}
        AppRouter.router.push('/my-rides');
      } else {
        AppRouter.router.push('/notifications');
      }
    } catch (e) {
      debugPrint('[NOTIFICATION ROUTE ERROR] $e');
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
                  kReminderChannelId,
                  kReminderChannelName,
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
                  kReminderChannelId,
                  kReminderChannelName,
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

