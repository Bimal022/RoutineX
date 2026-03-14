import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

/// Channel key constants
const String _habitChannelKey = 'habit_channel';
const String _habitChannelGroupKey = 'habit_channel_group';

/// Action button key used in notifications
const String kDoneActionKey = 'DONE_ACTION';

class NotificationService {
  // ── Initialization ────────────────────────────────────────────
  /// Call once in main() before runApp.
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // null = use default app icon
      [
        NotificationChannel(
          channelGroupKey: _habitChannelGroupKey,
          channelKey: _habitChannelKey,
          channelName: 'Habit Reminders',
          channelDescription: 'Reminders for your daily habits',
          defaultColor: const Color(0xFF6750A4),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: _habitChannelGroupKey,
          channelGroupName: 'Habits',
        ),
      ],
      debug: true,
    );
  }

  // ── Listeners (call inside MaterialApp's initState) ───────────
  /// Sets global notification event handlers.
  /// [onDoneAction] is called with the habitId when the user taps "Done".
  static void setListeners({
    required Future<void> Function(String habitId) onDoneAction,
  }) {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: (ReceivedAction action) async {
        if (action.buttonKeyPressed == kDoneActionKey) {
          final habitId = action.payload?['habitId'];
          if (habitId != null) {
            await onDoneAction(habitId);
          }
        }
      },
    );
  }

  // ── Permission ────────────────────────────────────────────────
  static Future<bool> requestPermission() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      return AwesomeNotifications().requestPermissionToSendNotifications();
    }
    return true;
  }

  // ── Schedule ──────────────────────────────────────────────────
  /// Schedules a repeating or one-shot notification for a habit.
  ///
  /// - [allDay] = true  → shows immediately and repeats daily at midnight (00:00).
  /// - [allDay] = false → repeats daily at [hour]:[minute].
  /// - [weekdays] (1=Mon … 7=Sun) restricts which days the notification fires.
  ///   Pass an empty list to fire every day.
  static Future<void> scheduleHabitNotification({
    required String habitId,
    required String habitName,
    required bool allDay,
    required int hour,
    required int minute,
    List<int> weekdays = const [],
    String emoji = '✅',
  }) async {
    final int notifId = notifIdFromHabitId(habitId);

    // Build schedule: either all-day (00:00 daily) or specific time
    final scheduleHour = hour;
  final scheduleMinute = minute;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notifId,
        channelKey: _habitChannelKey,
        title: '$emoji $habitName',
        body: allDay
            ? 'Tap Done when you complete it today!'
            : 'Time to complete your habit!',
        notificationLayout: NotificationLayout.Default,
        payload: {'habitId': habitId},
        category: NotificationCategory.Reminder,
        wakeUpScreen: true,
        autoDismissible: false,
      ),
      actionButtons: [
        NotificationActionButton(
          key: kDoneActionKey,
          label: '✅ Done',
          actionType: ActionType.SilentAction,
          autoDismissible: true,
        ),
      ],
      schedule: weekdays.isEmpty
          ? NotificationCalendar(
              hour: scheduleHour,
              minute: scheduleMinute,
              second: 0,
              millisecond: 0,
              repeats: true,
            )
          : NotificationCalendar(
              weekday: weekdays.first, // see note below for multi-day
              hour: scheduleHour,
              minute: scheduleMinute,
              second: 0,
              millisecond: 0,
              repeats: true,
            ),
    );

    // awesome_notifications' NotificationCalendar only accepts one weekday at a
    // time. For habits with multiple weekdays we schedule one notification per day.
    if (weekdays.length > 1) {
      await cancelHabitNotification(habitId); // remove the first one above
      for (int i = 0; i < weekdays.length; i++) {
        final subId = notifIdFromHabitId('${habitId}_$i');
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: subId,
            channelKey: _habitChannelKey,
            title: '$emoji $habitName',
            body: allDay
                ? 'Tap Done when you complete it today!'
                : 'Time to complete your habit!',
            notificationLayout: NotificationLayout.Default,
            payload: {'habitId': habitId},
            category: NotificationCategory.Reminder,
            wakeUpScreen: true,
            autoDismissible: false,
          ),
          actionButtons: [
            NotificationActionButton(
              key: kDoneActionKey,
              label: '✅ Done',
              actionType: ActionType.SilentAction,
              autoDismissible: true,
            ),
          ],
          schedule: NotificationCalendar(
            weekday: weekdays[i],
            hour: scheduleHour,
            minute: scheduleMinute,
            second: 0,
            millisecond: 0,
            repeats: true,
          ),
        );
      }
    }
  }

  // ── Dismiss for today (habit marked done) ─────────────────────
  /// Removes the currently-displayed notification for [habitId] today.
  /// The scheduled notification will still fire again on the next occurrence.
  static Future<void> dismissTodayNotification(String habitId) async {
    final int notifId = notifIdFromHabitId(habitId);
    await AwesomeNotifications().dismiss(notifId);

    // Also dismiss any weekday-split sub-notifications
    for (int i = 0; i < 7; i++) {
      await AwesomeNotifications()
          .dismiss(notifIdFromHabitId('${habitId}_$i'));
    }
  }

  // ── Cancel (habit deleted) ────────────────────────────────────
  /// Permanently cancels all scheduled notifications for [habitId].
  static Future<void> cancelHabitNotification(String habitId) async {
    await AwesomeNotifications().cancel(notifIdFromHabitId(habitId));

    // Cancel weekday-split sub-notifications
    for (int i = 0; i < 7; i++) {
      await AwesomeNotifications()
          .cancel(notifIdFromHabitId('${habitId}_$i'));
    }
  }

  // ── Cancel all ────────────────────────────────────────────────
  static Future<void> cancelAll() async {
    await AwesomeNotifications().cancelAll();
  }

  // ── Helper ────────────────────────────────────────────────────
  /// Converts a String habitId into a stable int notification id.
  static int notifIdFromHabitId(String habitId) =>
      habitId.hashCode.abs() % 2147483647;
}