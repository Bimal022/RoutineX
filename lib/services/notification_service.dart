import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: android);

    await _notifications.initialize(settings: settings);
  }

  static Future<void> scheduleHabitNotification({
    required String habitId,
    required String habitName,
    required bool allDay,
    required int hour,
    required int minute,
  }) async {
    final now = DateTime.now();
    log(
      'NotiTest Scheduling notification for habit $habitName at $hour:$minute',
    );
    log('NotiTest Current time: ${now.hour}:${now.minute}');
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (allDay) {
      // If it's an all-day habit, schedule from now to 12:00 AM next day
      scheduled = now.add(
        const Duration(seconds: 5),
      ); // Start in 5 seconds for testing
    }

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id: habitId.hashCode,
      title: "Habit Reminder",
      body: "Time to complete $habitName",
      scheduledDate: tz.TZDateTime.from(scheduled, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_channel',
          'Habit Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelHabitNotification(String habitId) async {
    await _notifications.cancel(id: habitId.hashCode);
  }
}
