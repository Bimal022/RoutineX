import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';

class HabitProvider extends ChangeNotifier {
  List<Habit> _habits = [];
  List<HabitLog> _logs = [];

  List<Habit> get habits => _habits;

  /// Only habits scheduled for today
  List<Habit> get todaysHabits {
    final today = DateTime.now();
    return _habits.where((h) => h.isScheduledFor(today)).toList();
  }

  void addHabit(
    String name,
    String emoji, {
    HabitType type = HabitType.recurring,
    List<int> weekdays = const [],
  }) {
    _habits.add(
      Habit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        emoji: emoji,
        type: type,
        weekdays: weekdays,
      ),
    );
    notifyListeners();
  }

  void removeHabit(String habitId) {
    _habits.removeWhere((h) => h.id == habitId);
    _logs.removeWhere((l) => l.habitId == habitId);
    notifyListeners();
  }

  void toggleHabit(String habitId) {
    DateTime today = DateTime.now();
    final index = _logs.indexWhere(
      (log) =>
          log.habitId == habitId &&
          log.date.day == today.day &&
          log.date.month == today.month &&
          log.date.year == today.year,
    );
    if (index >= 0) {
      _logs[index].completed = !_logs[index].completed;
    } else {
      _logs.add(HabitLog(habitId: habitId, date: today, completed: true));
    }
    notifyListeners();
  }

  bool isCompleted(String habitId) {
    DateTime today = DateTime.now();
    final log = _logs.where(
      (log) =>
          log.habitId == habitId &&
          log.date.day == today.day &&
          log.date.month == today.month &&
          log.date.year == today.year,
    );
    if (log.isEmpty) return false;
    return log.first.completed;
  }

  int completedToday() {
    DateTime today = DateTime.now();
    final scheduled = todaysHabits.map((h) => h.id).toSet();
    return _logs
        .where(
          (l) =>
              l.completed &&
              scheduled.contains(l.habitId) &&
              l.date.day == today.day &&
              l.date.month == today.month &&
              l.date.year == today.year,
        )
        .length;
  }

  double get completionPercent {
    final total = todaysHabits.length;
    if (total == 0) return 0.0;
    return completedToday() / total;
  }

  int get currentStreak {
    if (_habits.isEmpty) return 0;
    int streak = 0;
    DateTime day = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final scheduledOnDay =
          _habits.where((h) => h.isScheduledFor(day)).toList();
      if (scheduledOnDay.isEmpty) {
        day = day.subtract(const Duration(days: 1));
        continue;
      }
      final completedOnDay = _logs
          .where(
            (l) =>
                l.completed &&
                scheduledOnDay.any((h) => h.id == l.habitId) &&
                l.date.day == day.day &&
                l.date.month == day.month &&
                l.date.year == day.year,
          )
          .length;
      if (completedOnDay == scheduledOnDay.length) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}