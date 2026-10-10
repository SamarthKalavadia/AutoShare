import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

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

      final androidPlugin = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          AndroidNotificationChannel(
            channelId,
            channelName,
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
            showBadge: true,
          ),
        );
      }

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
  StreamSubscription<String>? _tokenRefreshSubscription;
  final Set<String> _seenNotificationIds = {};
  final Set<String> _seenNotificationKeys = {};
  final Map<String, int> _recentNotificationTimestamps = {};
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

      // Check if app was launched by tapping a local notification from terminated state
      try {
        final launchDetails = await _flutterLocalNotificationsPlugin
            .getNotificationAppLaunchDetails();
        if (launchDetails?.didNotificationLaunchApp ?? false) {
          final payload =
              launchDetails?.notificationResponse?.payload;
          if (payload != null && payload.isNotEmpty) {
            debugPrint(
                '[NOTIFICATION LAUNCH TERMINATED] App opened via local notification: $payload');
            Future.delayed(const Duration(milliseconds: 600), () {
              _handleNotificationTap(payload: payload);
            });
          }
        }
      } catch (e) {
        debugPrint('[NOTIFICATION LAUNCH CHECK ERROR] $e');
      }

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

        // Request Android 13+ POST_NOTIFICATIONS permission
        try {
          await Permission.notification.request();
          await androidPlugin.requestNotificationsPermission();
        } catch (_) {}
      }

      // 3. Request Notification Permissions & FCM Listeners (asynchronous, non-blocking)
      unawaited(_initFcmAsync());
    } catch (e) {
      debugPrint('[NOTIFICATION INIT ERROR] $e');
    }
  }

  Future<void> _initFcmAsync() async {
    try {
      final messaging = FirebaseMessaging.instance;
      try {
        await Permission.notification.request();
      } catch (_) {}
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

        final dedupKey = '$title::$body';
        if (_seenNotificationKeys.contains(dedupKey)) {
          debugPrint('[NOTIFICATION DEDUP] Skipping duplicate notification on foreground: $dedupKey');
          return;
        }
        _seenNotificationKeys.add(dedupKey);

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
        final initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) {
          debugPrint(
              '[FCM INITIAL] App launched from terminated state via notification: ${initialMessage.data}');
          Future.delayed(const Duration(milliseconds: 600), () {
            _handleNotificationTap(data: initialMessage.data);
          });
        }
      } catch (_) {}

      // Auto-sync FCM Token and start real-time listener if user is authenticated
      for (int i = 0; i < 5; i++) {
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        if (currentUid != null && currentUid.isNotEmpty) {
          syncFcmToken(currentUid);
          startListening(currentUid);
          break;
        }
        await Future.delayed(const Duration(milliseconds: 400));
      }

      // Also listen to auth state changes so session restoration or login auto-syncs FCM
      FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user != null && user.uid.isNotEmpty) {
          try {
            final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
            if (doc.exists) {
              final data = doc.data();
              final phone = (data?['phone']?.toString() ?? '').trim();
              if (phone.isNotEmpty) {
                syncFcmToken(user.uid);
                startListening(user.uid);
              }
            }
          } catch (_) {}
        }
      });
    } catch (e) {
      debugPrint('[FCM ASYNC INIT ERROR] $e');
    }
  }

  final DateTime _appSessionStartTime = DateTime.now();

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
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            final title = (data['title'] as String?) ?? '';
            final body = (data['body'] as String?) ?? '';
            if (title.isNotEmpty || body.isNotEmpty) {
              _seenNotificationKeys.add('$title::$body');
            }
          }
        }
        _isInitialNotifSnapshot = false;
        return;
      }

      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final docId = change.doc.id;
          if (_seenNotificationIds.contains(docId)) continue;
          _seenNotificationIds.add(docId);

          final data = change.doc.data();
          if (data == null) continue;

          final title = (data['title'] as String?) ?? 'AutoShare';
          final body = (data['body'] as String?) ?? '';
          final type = (data['type'] as String?) ?? '';
          final relatedId = (data['relatedId'] as String?) ?? '';

          DateTime createdAt = DateTime.now();
          final rawCreated = data['createdAt'];
          if (rawCreated is Timestamp) {
            createdAt = rawCreated.toDate();
          } else if (rawCreated is String) {
            createdAt = DateTime.tryParse(rawCreated) ?? DateTime.now();
          }

          final dedupKey = '$title::$body';
          // If the notification was created before this app session started,
          // or older than 8 seconds ago, it was delivered while the app was closed.
          // NEVER show a popup notification on app open for past notifications!
          if (createdAt.isBefore(_appSessionStartTime) ||
              createdAt.isBefore(DateTime.now().subtract(const Duration(seconds: 8)))) {
            _seenNotificationKeys.add(dedupKey);
            continue;
          }

          if (_seenNotificationKeys.contains(dedupKey)) {
            debugPrint('[NOTIFICATION DEDUP] Skipping duplicate notification: $dedupKey');
            continue;
          }
          _seenNotificationKeys.add(dedupKey);

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
      // Deduplicate notifications with identical title & body within 4 seconds
      final dedupKey = '$title::$body';
      final now = DateTime.now().millisecondsSinceEpoch;
      if (_recentNotificationTimestamps.containsKey(dedupKey) &&
          now - _recentNotificationTimestamps[dedupKey]! < 4000) {
        debugPrint('[NOTIFICATION DEDUP] Skipping duplicate notification: $dedupKey');
        return;
      }
      _recentNotificationTimestamps[dedupKey] = now;
      // Prune entries older than 30s
      _recentNotificationTimestamps.removeWhere((k, v) => now - v > 30000);

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
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        final updateData = {
          'fcmToken': token,
          'fcmTokens': [token],
          'lastTokenUpdated': FieldValue.serverTimestamp(),
        };
        final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
        final doc = await docRef.get();
        if (!doc.exists) {
          // Do NOT create phantom documents for users who haven't completed registration
          return;
        }
        final data = doc.data();
        final phone = (data?['phone']?.toString() ?? '').trim();
        if (phone.isEmpty) {
          // Do NOT update stub documents
          return;
        }

        await docRef.set(
          updateData,
          SetOptions(merge: true),
        );

        // Also update any document matching uid field
        try {
          final querySnap = await FirebaseFirestore.instance
              .collection('users')
              .where('uid', isEqualTo: uid)
              .get()
              .timeout(const Duration(seconds: 2));
          for (final doc in querySnap.docs) {
            if (doc.id != uid) {
              await doc.reference.set(updateData, SetOptions(merge: true));
            }
          }
        } catch (_) {}

        debugPrint('[FCM TOKEN] Successfully synced token for $uid');
      }

      try {
        await FirebaseMessaging.instance.subscribeToTopic('user_$uid');
        await FirebaseMessaging.instance.subscribeToTopic('all_users');
      } catch (_) {}

      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription =
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          final refreshData = {
            'fcmToken': newToken,
            'fcmTokens': [newToken],
            'lastTokenUpdated': FieldValue.serverTimestamp(),
          };
          await FirebaseFirestore.instance.collection('users').doc(uid).set(
            refreshData,
            SetOptions(merge: true),
          );
          debugPrint('[FCM TOKEN REFRESHED] Updated token for $uid');
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('[FCM TOKEN SYNC ERROR] $e');
    }
  }

  static String? _cachedAccessToken;
  static DateTime? _tokenExpiry;
  static Map<String, dynamic>? _cachedServiceAccount;

  /// Retrieves an OAuth2 Access Token for Google Cloud Messaging (HTTP v1)
  /// using Firebase Service Account credentials.
  /// Checks local asset first, then falls back to Firestore appConfig/fcm.
  Future<String?> _getFcmAccessToken() async {
    if (_cachedAccessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedAccessToken;
    }

    try {
      Map<String, dynamic>? saMap = _cachedServiceAccount;

      // 1. Try loading from bundled asset
      if (saMap == null) {
        try {
          final jsonStr =
              await rootBundle.loadString('assets/firebase/service-account.json');
          if (jsonStr.trim().isNotEmpty && jsonStr.trim() != '{}') {
            final decoded = jsonDecode(jsonStr);
            if (decoded is Map<String, dynamic> &&
                decoded.containsKey('private_key')) {
              saMap = decoded;
            }
          }
        } catch (_) {}
      }

      // 2. Fallback: load from Firestore appConfig/fcm
      if (saMap == null) {
        try {
          final fcmDoc = await FirebaseFirestore.instance
              .collection('appConfig')
              .doc('fcm')
              .get()
              .timeout(const Duration(seconds: 4));
          if (fcmDoc.exists && fcmDoc.data() != null) {
            final data = fcmDoc.data()!;
            if (data.containsKey('private_key')) {
              saMap = data;
            } else if (data['json'] is String) {
              final parsed = jsonDecode(data['json'] as String);
              if (parsed is Map<String, dynamic>) {
                saMap = parsed;
              }
            }
          }
        } catch (_) {}
      }

      // 3. Fallback: check appConfig/serviceAccount
      if (saMap == null) {
        try {
          final saDoc = await FirebaseFirestore.instance
              .collection('appConfig')
              .doc('serviceAccount')
              .get()
              .timeout(const Duration(seconds: 4));
          if (saDoc.exists && saDoc.data() != null) {
            final data = saDoc.data()!;
            if (data.containsKey('private_key')) {
              saMap = data;
            }
          }
        } catch (_) {}
      }

      if (saMap == null) {
        debugPrint(
          '[FCM v1] No service account found in assets or Firestore appConfig/fcm.',
        );
        return null;
      }

      _cachedServiceAccount = saMap;
      final creds = ServiceAccountCredentials.fromJson(saMap);
      final scopes = const ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(creds, scopes);
      _cachedAccessToken = client.credentials.accessToken.data;
      _tokenExpiry =
          client.credentials.accessToken.expiry.subtract(const Duration(minutes: 5));
      client.close();
      return _cachedAccessToken;
    } catch (e) {
      debugPrint('[FCM v1 AUTH ERROR] Failed to obtain OAuth token: $e');
      return null;
    }
  }

  /// Sends a single high-priority heads-up FCM v1 push notification to a device token or topic.
  /// When received on Android, Google Play Services immediately wakes up the device
  /// and shows the heads-up notification banner in the status bar/lock screen,
  /// even when the AutoShare app is completely closed or killed.
  Future<bool> _dispatchFcmV1({
    String? token,
    String? topic,
    required String title,
    required String body,
    required String type,
    String? relatedId,
    String? recipientUid,
  }) async {
    if ((token == null || token.isEmpty) && (topic == null || topic.isEmpty)) {
      return false;
    }
    try {
      final accessToken = await _getFcmAccessToken();
      if (accessToken == null) return false;

      final isChat = type == 'chat';
      final channelId = isChat ? kChatChannelId : kDefaultChannelId;
      final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
      final collapseTag = '${type}_${relatedId ?? (recipientUid ?? 'notif')}';

      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      );

      final Map<String, dynamic> messagePayload = {
        'notification': {
          'title': title,
          'body': body,
        },
        'android': {
          'priority': 'HIGH',
          'ttl': '2419200s',
          'notification': {
            'channel_id': channelId,
            'tag': collapseTag,
            'sound': 'default',
            'default_sound': true,
            'default_vibrate_timings': true,
            'notification_priority': 'PRIORITY_MAX',
            'visibility': 'PUBLIC',
            'icon': 'ic_launcher',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
        'apns': {
          'payload': {
            'aps': {
              'alert': {
                'title': title,
                'body': body,
              },
              'sound': 'default',
              'badge': 1,
              'content-available': 1,
            },
          },
        },
        'data': {
          'title': title,
          'body': body,
          'type': type,
          'relatedId': relatedId ?? '',
          'rideId': relatedId ?? '',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      };

      if (token != null && token.isNotEmpty) {
        messagePayload['token'] = token;
      } else if (topic != null && topic.isNotEmpty) {
        messagePayload['topic'] = topic;
      }

      final payload = {'message': messagePayload};

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );

      final targetStr = token != null
          ? 'Token: ${token.length > 12 ? token.substring(0, 12) : token}...'
          : 'Topic: $topic';
      debugPrint('[FCM v1 RESULT] $targetStr Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('[FCM v1 ERROR] ${response.body}');
        if (response.statusCode == 404 && recipientUid != null && token != null) {
          // Token is unregistered or invalid - clean up
          try {
            FirebaseFirestore.instance
                .collection('users')
                .doc(recipientUid)
                .update({
              'fcmTokens': FieldValue.arrayRemove([token]),
            });
          } catch (_) {}
        }
        return false;
      }
    } catch (e) {
      debugPrint('[FCM v1 DISPATCH EXCEPTION] $e');
      return false;
    }
  }

  /// Sends high-priority push notifications directly to the recipient's FCM tokens
  /// and user topic fallback, and queues in Firestore `push_notifications`.
  /// Ensures that closed / killed apps immediately receive the heads-up notification!
  Future<void> sendPushNotification({
    required String recipientUid,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    final cleanUid = recipientUid.trim();
    if (cleanUid.isEmpty) return;

    // 1. Fetch recipient's active FCM tokens from Firestore
    final List<String> targetTokens = [];
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(cleanUid)
          .get()
          .timeout(const Duration(seconds: 3));

      if (userDoc.exists && userDoc.data() != null) {
        final uData = userDoc.data()!;
        final singleToken = uData['fcmToken'] as String?;
        if (singleToken != null && singleToken.trim().isNotEmpty) {
          targetTokens.add(singleToken.trim());
        }

        final tokensList = uData['fcmTokens'];
        if (tokensList is List) {
          for (final t in tokensList) {
            if (t is String && t.trim().isNotEmpty && !targetTokens.contains(t.trim())) {
              targetTokens.add(t.trim());
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Fetch user tokens error for $cleanUid: $e');
    }

    // 2. Dispatch FCM v1 directly to tokens
    bool delivered = false;
    for (final token in targetTokens) {
      final ok = await _dispatchFcmV1(
        token: token,
        title: title,
        body: body,
        type: type,
        relatedId: relatedId,
        recipientUid: cleanUid,
      );
      if (ok) delivered = true;
    }

    // 3. Fallback to recipient's individual topic: user_$cleanUid
    if (!delivered || targetTokens.isEmpty) {
      debugPrint('[NotificationService] Dispatching to topic user_$cleanUid');
      await _dispatchFcmV1(
        topic: 'user_$cleanUid',
        title: title,
        body: body,
        type: type,
        relatedId: relatedId,
        recipientUid: cleanUid,
      );
    }

    // 4. Also record in push_notifications collection for server audit / redundancy
    try {
      await FirebaseFirestore.instance.collection('push_notifications').add({
        'recipientUids': [cleanUid],
        'title': title,
        'body': body,
        'type': type,
        'relatedId': relatedId,
        'status': delivered ? 'delivered' : 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'data': {
          'type': type,
          'relatedId': relatedId ?? '',
          'rideId': relatedId ?? '',
        },
      });
    } catch (_) {}
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

