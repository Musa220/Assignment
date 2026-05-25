import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
    );
  }

  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleWaterReminder({
    required int intervalHours,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    await cancelWaterReminders();

    final now = tz.TZDateTime.now(tz.local);

    int notifId = 100;
    int startMinutes = startTime.hour * 60 + startTime.minute;
    int endMinutes = endTime.hour * 60 + endTime.minute;
    int intervalMinutes = intervalHours * 60;

    const notifDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'water_reminder_channel',
        'Water Reminders',
        channelDescription: 'Daily water intake reminders',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFF2196F3),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    for (
      int minutes = startMinutes;
      minutes <= endMinutes;
      minutes += intervalMinutes
    ) {
      final hour = minutes ~/ 60;
      final minute = minutes % 60;

      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        notifId++,
        '💧 Time to drink water!',
        _getReminderMessage(),
        scheduledTime,
        notifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        // ✅ iOS er jonno required
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> cancelWaterReminders() async {
    for (int i = 100; i <= 200; i++) {
      await _plugin.cancel(i);
    }
  }

  static Future<void> showTestNotification() async {
    await _plugin.show(
      999,
      '💧 Test Notification',
      'Water reminders are working! Stay hydrated 🌊',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_reminder_channel',
          'Water Reminders',
          channelDescription: 'Daily water intake reminders',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF2196F3),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
    );
  }

  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }

  static String _getReminderMessage() {
    final messages = [
      'Drink a glass of water now! 🥤',
      'Stay hydrated for better health! 💙',
      'Your body needs water! Drink up! 🌊',
      'Time for your water break! 💧',
      'Hydration check! Have some water 🚰',
    ];
    final index = DateTime.now().minute % messages.length;
    return messages[index];
  }
}
