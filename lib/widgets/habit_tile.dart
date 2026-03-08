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
    final isOneTime = habit.type == HabitType.oneTime;

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
                ? AppTheme.primary.withOpacity(0.12)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: done
                  ? AppTheme.primary.withOpacity(0.4)
                  : AppTheme.surfaceLight,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Text(habit.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(
                        color: done
                            ? AppTheme.textSecondary
                            : AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration:
                            done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _scheduleBadge(isOneTime),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color:
                      done ? AppTheme.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                    width: 2,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check,
                        size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scheduleBadge(bool isOneTime) {
    if (isOneTime) {
      return _badge("One-time", AppTheme.accent, Icons.looks_one_outlined);
    }
    if (habit.weekdays.isEmpty) {
      return _badge("Every day", AppTheme.secondary, Icons.repeat_rounded);
    }
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = habit.weekdays.toList()..sort();
    final label = sorted.map((d) => dayNames[d - 1]).join(' · ');
    return _badge(label, AppTheme.primary, Icons.repeat_rounded);
  }

  Widget _badge(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color.withOpacity(0.8)),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}