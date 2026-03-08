import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/expense_provider.dart';
import '../../theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final habits = Provider.of<HabitProvider>(context);
    final expenses = Provider.of<ExpenseProvider>(context);
    final totals = expenses.categoryTotals();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Stats",
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 20),

              // Habit stats
              _sectionTitle("Habits Overview"),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      "Total Habits",
                      "${habits.habits.length}",
                      "📋",
                      AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      "Done Today",
                      "${habits.completedToday()}",
                      "✅",
                      AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      "Streak",
                      "${habits.currentStreak}d",
                      "🔥",
                      AppTheme.warning,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),
              _sectionTitle("Habit List"),
              const SizedBox(height: 12),
              if (habits.habits.isEmpty)
                _emptyCard("No habits added yet", "💪")
              else
                ...habits.habits.map((h) {
                  final done = habits.isCompleted(h.id);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.surfaceLight),
                    ),
                    child: Row(
                      children: [
                        Text(h.emoji,
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            h.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: done
                                ? AppTheme.success.withOpacity(0.15)
                                : AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            done ? "Done" : "Pending",
                            style: TextStyle(
                              color: done
                                  ? AppTheme.success
                                  : AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 28),
              _sectionTitle("Expense Breakdown"),
              const SizedBox(height: 12),
              if (totals.isEmpty)
                _emptyCard("No expenses recorded", "💰")
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        "Today",
                        "₹${expenses.todayTotal().toStringAsFixed(0)}",
                        "📅",
                        AppTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        "This Week",
                        "₹${expenses.weekTotal().toStringAsFixed(0)}",
                        "📆",
                        AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...totals.entries.map((entry) {
                  final maxVal = totals.values
                      .reduce((a, b) => a > b ? a : b);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.surfaceLight),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "₹${entry.value.toStringAsFixed(0)}",
                              style: const TextStyle(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: entry.value / maxVal,
                            backgroundColor: AppTheme.surfaceLight,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.accent,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _statCard(
      String label, String value, String emoji, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String msg, String emoji) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            msg,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}