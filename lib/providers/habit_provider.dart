import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HabitProvider extends ChangeNotifier {
  final List<Habit> _habits = [];
  final List<HabitLog> _logs = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Habit> get habits => _habits;

  /// Only habits scheduled for today
  List<Habit> get todaysHabits {
    final today = DateTime.now();
    return _habits.where((h) => h.isScheduledFor(today)).toList();
  }

  Future<void> loadHabits() async {
    final snapshot = await _firestore.collection('habits').get();

    _habits.clear();

    for (var doc in snapshot.docs) {
      final data = doc.data();

      _habits.add(
        Habit(
          id: data['id'],
          name: data['name'],
          emoji: data['emoji'],
          weekdays: List<int>.from(data['weekdays'] ?? []),
        ),
      );
    }

    notifyListeners();
  }

  Future<void> addHabit(
    String name,
    String emoji, {
    HabitType type = HabitType.recurring,
    List<int> weekdays = const [],
  }) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      Habit habit = Habit(
        id: id,
        name: name,
        emoji: emoji,
        type: type,
        weekdays: weekdays,
      );

      _habits.add(habit);

      await _firestore.collection('habits').doc(id).set({
        'id': id,
        'name': name,
        'emoji': emoji,
        'type': type.toString(),
        'weekdays': weekdays,
      });

      print("Habit added to Firestore");

      notifyListeners();
    } catch (e) {
      print("Firestore error: $e");
    }
  }

  Future<void> removeHabit(String habitId) async {
    _habits.removeWhere((h) => h.id == habitId);
    _logs.removeWhere((l) => l.habitId == habitId);

    await _firestore.collection('habits').doc(habitId).delete();

    notifyListeners();
  }

  Future<void> toggleHabit(String habitId) async {
    DateTime today = DateTime.now();

    final index = _logs.indexWhere(
      (log) =>
          log.habitId == habitId &&
          log.date.day == today.day &&
          log.date.month == today.month &&
          log.date.year == today.year,
    );

    bool completed;

    if (index >= 0) {
      _logs[index].completed = !_logs[index].completed;
      completed = _logs[index].completed;
    } else {
      _logs.add(HabitLog(habitId: habitId, date: today, completed: true));
      completed = true;
    }

    await _firestore.collection('habit_logs').add({
      'habitId': habitId,
      'date': today.toIso8601String(),
      'completed': completed,
    });

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
      final scheduledOnDay = _habits
          .where((h) => h.isScheduledFor(day))
          .toList();
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
