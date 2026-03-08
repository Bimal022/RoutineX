class Habit {
  final String id;
  final String name;
  final String emoji;
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.name,
    this.emoji = '✅',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}