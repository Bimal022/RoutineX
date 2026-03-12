import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routinex/services/notification_service.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';

class HabitProvider extends ChangeNotifier {
  final List<Habit> _habits = [];
  final List<HabitLog> _logs = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Helpers ───────────────────────────────────────────────────
  /// Current user's UID. Throws if not signed in.
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  /// Root reference: users/{uid}
  DocumentReference get _userDoc => _firestore.collection('users').doc(_uid);

  /// users/{uid}/habits
  CollectionReference get _habitsCol => _userDoc.collection('habits');

  /// users/{uid}/habit_logs
  CollectionReference get _logsCol => _userDoc.collection('habit_logs');

  // ── Getters ───────────────────────────────────────────────────
  List<Habit> get habits => _habits;

  List<Habit> get todaysHabits {
    final today = DateTime.now();
    return _habits.where((h) => h.isScheduledFor(today)).toList();
  }

  // ── Load ──────────────────────────────────────────────────────
  /// Call once after sign-in / onboarding completes.
  Future<void> loadHabits() async {
    try {
      // Load habits
      final habitsSnap = await _habitsCol.get();
      _habits.clear();
      for (final doc in habitsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        _habits.add(_habitFromMap(data));
      }

      // Load today's logs so completion state is correct immediately
      await _loadTodayLogs();

      notifyListeners();
    } catch (e) {
      debugPrint('HabitProvider.loadHabits error: $e');
    }
  }

  Future<void> _loadTodayLogs() async {
    final today = DateTime.now();
    // Firestore date range for today
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    final logsSnap = await _logsCol
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('date', isLessThanOrEqualTo: endOfDay.toIso8601String())
        .get();

    _logs.clear();
    for (final doc in logsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      _logs.add(
        HabitLog(
          habitId: data['habitId'] as String,
          date: DateTime.parse(data['date'] as String),
          completed: data['completed'] as bool,
        ),
      );
    }
  }

  // ── Add ───────────────────────────────────────────────────────
  Future<void> addHabit(
    String name,
    String emoji, {
    HabitType type = HabitType.recurring,
    List<int> weekdays = const [],
    int? hour,
    int? minute,
  }) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      final habit = Habit(
        id: id,
        name: name,
        emoji: emoji,
        type: type,
        weekdays: weekdays,
        hour: hour,
        minute: minute,
      );

      _habits.add(habit);
      notifyListeners();

      await _habitsCol.doc(id).set({
        'id': id,
        'name': name,
        'emoji': emoji,
        'type': type.name,
        'weekdays': weekdays,
        'hour': hour,
        'minute': minute,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (hour != null && minute != null) {
        await NotificationService.scheduleHabitNotification(
          habitId: id,
          habitName: name,
          hour: hour,
          minute: minute,
        );
      }
    } catch (e) {
      debugPrint('HabitProvider.addHabit error: $e');
    }
  }

  // ── Remove ────────────────────────────────────────────────────
  Future<void> removeHabit(String habitId) async {
    _habits.removeWhere((h) => h.id == habitId);
    _logs.removeWhere((l) => l.habitId == habitId);

    notifyListeners();

    try {
      await NotificationService.cancelHabitNotification(habitId);

      await _habitsCol.doc(habitId).delete();

      final logDocs = await _logsCol.where('habitId', isEqualTo: habitId).get();

      final batch = _firestore.batch();

      for (final doc in logDocs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('HabitProvider.removeHabit error: $e');
    }
  }

  // ── Toggle ────────────────────────────────────────────────────
  Future<void> toggleHabit(String habitId) async {
    final today = DateTime.now();

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
    notifyListeners(); // optimistic update

    try {
      // Use habitId + date as a deterministic doc ID so toggling
      // updates the same document instead of creating duplicates.
      final logId =
          '${habitId}_${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

      await _logsCol.doc(logId).set({
        'habitId': habitId,
        'date': today.toIso8601String(),
        'completed': completed,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('HabitProvider.toggleHabit error: $e');
    }
  }

  // ── Queries ───────────────────────────────────────────────────
  bool isCompleted(String habitId) {
    final today = DateTime.now();
    final log = _logs.where(
      (l) =>
          l.habitId == habitId &&
          l.date.day == today.day &&
          l.date.month == today.month &&
          l.date.year == today.year,
    );
    if (log.isEmpty) return false;
    return log.first.completed;
  }

  int completedToday() {
    final today = DateTime.now();
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

  // ── Clear local state on sign-out ─────────────────────────────
  void clear() {
    _habits.clear();
    _logs.clear();
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────
  Habit _habitFromMap(Map<String, dynamic> data) {
    final typeStr = data['type'] as String? ?? 'recurring';
    final type = typeStr == 'oneTime' ? HabitType.oneTime : HabitType.recurring;

    return Habit(
      id: data['id'] as String,
      name: data['name'] as String,
      emoji: data['emoji'] as String? ?? '✅',
      type: type,
      weekdays: List<int>.from(data['weekdays'] ?? []),
    );
  }
}
