import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../theme.dart';

class HabitTile extends StatelessWidget {
  final Habit habit;
  const HabitTile({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HabitProvider>(context);
    final done = provider.isCompleted(habit.id);

    return Dismissible(
      key: Key(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (_) => provider.removeHabit(habit.id),
      child: GestureDetector(
        onTap: () => provider.toggleHabit(habit.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: done
                ? AppTheme.primary.withOpacity(0.15)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: done ? AppTheme.primary.withOpacity(0.5) : AppTheme.surfaceLight,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Text(habit.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  habit.name,
                  style: TextStyle(
                    color: done
                        ? AppTheme.textSecondary
                        : AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: done ? AppTheme.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done ? AppTheme.primary : AppTheme.textSecondary,
                    width: 2,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}