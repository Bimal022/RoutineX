enum HabitType { recurring, oneTime }

class Habit {
  final String id;
  final String name;
  final String emoji;
  final DateTime createdAt;
  final HabitType type;

  /// For recurring habits: list of weekdays (1=Mon … 7=Sun).
  /// Empty list means every day.
  final List<int> weekdays;

  Habit({
    required this.id,
    required this.name,
    this.emoji = '✅',
    DateTime? createdAt,
    this.type = HabitType.recurring,
    this.weekdays = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  /// Returns true if this habit should be shown on the given [date].
  bool isScheduledFor(DateTime date) {
    if (type == HabitType.oneTime) {
      return date.day == createdAt.day &&
          date.month == createdAt.month &&
          date.year == createdAt.year;
    }
    // Recurring
    if (weekdays.isEmpty) return true; // every day
    return weekdays.contains(date.weekday);
  }
}