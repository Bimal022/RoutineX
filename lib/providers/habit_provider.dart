import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';

class HabitProvider extends ChangeNotifier {
  List<Habit> _habits = [];
  List<HabitLog> _logs = [];

  List<Habit> get habits => _habits;

  void addHabit(String name, String emoji) {
    _habits.add(
      Habit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        emoji: emoji,
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
      _logs.add(
        HabitLog(habitId: habitId, date: today, completed: true),
      );
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
    return _logs
        .where(
          (l) =>
              l.completed &&
              l.date.day == today.day &&
              l.date.month == today.month &&
              l.date.year == today.year,
        )
        .length;
  }

  double get completionPercent {
    if (_habits.isEmpty) return 0.0;
    return completedToday() / _habits.length;
  }

  /// Returns number of days in a row where ALL habits were completed (streak)
  int get currentStreak {
    if (_habits.isEmpty) return 0;
    int streak = 0;
    DateTime day = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final dayLogs = _logs.where(
        (l) =>
            l.completed &&
            l.date.day == day.day &&
            l.date.month == day.month &&
            l.date.year == day.year,
      );
      final completed = dayLogs.length;
      if (completed == _habits.length && _habits.isNotEmpty) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}