import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  Future<void> scheduleRideReminder(String rideId, DateTime departureTime) async {
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
