class HabitLog {
  final String habitId;
  final DateTime date;
  bool completed;

  HabitLog({
    required this.habitId,
    required this.date,
    this.completed = false,
  });
}