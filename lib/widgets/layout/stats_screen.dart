import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/expense_provider.dart';
import '../../theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // Which tab is active: 0 = Habits, 1 = Expenses
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final habits = Provider.of<HabitProvider>(context);
    final expenses = Provider.of<ExpenseProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(habits, expenses),
            Expanded(
              child: _tab == 0
                  ? _HabitsTab(habits: habits)
                  : _ExpensesTab(expenses: expenses),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(HabitProvider habits, ExpenseProvider expenses) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
          const SizedBox(height: 16),
          // Tab switcher
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceLight),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _tabBtn("Habits", 0, '📋'),
                _tabBtn("Expenses", 1, '💸'),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, int index, String emoji) {
    final active = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.primary.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? AppTheme.primary : AppTheme.textSecondary,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HABITS TAB
// ─────────────────────────────────────────────────────────────────────────────

class _HabitsTab extends StatelessWidget {
  const _HabitsTab({required this.habits});
  final HabitProvider habits;

  @override
  Widget build(BuildContext context) {
    final total = habits.todaysHabits.length;
    final done = habits.completedToday();
    final pct = total == 0 ? 0.0 : done / total;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Motivational card ──────────────────────────────────────
          _MotivationalCard(
            message: _habitMotivation(done, total),
            color: _habitColor(done, total),
            emoji: _habitEmoji(done, total),
          ),
          const SizedBox(height: 20),

          // ── Summary row ────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _statCard(
                  "Total",
                  "${habits.habits.length}",
                  "📋",
                  AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard("Done Today", "$done", "✅", AppTheme.success),
              ),
              const SizedBox(width: 10),
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
          const SizedBox(height: 8),

          // ── Progress bar ───────────────────────────────────────────
          if (total > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's progress",
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "$done / $total",
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: AppTheme.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _habitColor(done, total),
                ),
                minHeight: 8,
              ),
            ),
          ],

          const SizedBox(height: 28),
          _sectionTitle("Today's Activity"),
          const SizedBox(height: 12),

          // ── Daily activity timeline ────────────────────────────────
          if (habits.todaysHabits.isEmpty)
            _emptyCard("No habits scheduled for today", "💪")
          else
            _HabitTimeline(habits: habits),

          // ── All habits quick list ──────────────────────────────────
          if (habits.habits.isNotEmpty) ...[
            const SizedBox(height: 28),
            _sectionTitle("All Habits"),
            const SizedBox(height: 12),
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
                    Text(h.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (h.weekdays.isNotEmpty)
                            Text(
                              _weekdayLabel(h.weekdays),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _statusBadge(done ? "Done" : "Pending", done),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// Timeline widget — shows each habit with time and done/pending indicator
class _HabitTimeline extends StatelessWidget {
  const _HabitTimeline({required this.habits});
  final HabitProvider habits;

  @override
  Widget build(BuildContext context) {
    final todayHabits = habits.todaysHabits;

    return Column(
      children: List.generate(todayHabits.length, (i) {
        final h = todayHabits[i];
        final done = habits.isCompleted(h.id);
        final isLast = i == todayHabits.length - 1;

        // Build time label
        String timeLabel;
        if (h.allDay) {
          timeLabel = "All day";
        } else if (h.hour != null && h.minute != null) {
          final hour = h.hour!;
          final min = h.minute!.toString().padLeft(2, '0');
          final period = hour >= 12 ? 'PM' : 'AM';
          final displayHour = hour % 12 == 0 ? 12 : hour % 12;
          timeLabel = "$displayHour:$min $period";
        } else {
          timeLabel = "Anytime";
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time column
              SizedBox(
                width: 72,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    timeLabel,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Timeline line + dot
              Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? AppTheme.success : AppTheme.surfaceLight,
                      border: Border.all(
                        color: done
                            ? AppTheme.success
                            : AppTheme.textSecondary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: done
                        ? const Icon(Icons.check, size: 8, color: Colors.white)
                        : null,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(width: 2, color: AppTheme.surfaceLight),
                    ),
                  if (isLast) const SizedBox(height: 16),
                ],
              ),
              const SizedBox(width: 12),
              // Habit card
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: done
                        ? AppTheme.success.withOpacity(0.05)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: done
                          ? AppTheme.success.withOpacity(0.25)
                          : AppTheme.surfaceLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(h.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.name,
                              style: TextStyle(
                                color: done
                                    ? AppTheme.textSecondary
                                    : AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                decoration: done
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              done ? "Completed today" : "Not yet done",
                              style: TextStyle(
                                color: done
                                    ? AppTheme.success.withOpacity(0.8)
                                    : AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _statusBadge(done ? "Done" : "Pending", done),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPENSES TAB
// ─────────────────────────────────────────────────────────────────────────────

class _ExpensesTab extends StatelessWidget {
  const _ExpensesTab({required this.expenses});
  final ExpenseProvider expenses;

  @override
  Widget build(BuildContext context) {
    final totals = expenses.categoryTotals();
    final todayTotal = expenses.todayTotal();
    final weekTotal = expenses.weekTotal();
    final todayItems = expenses.todayExpenses;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Motivational card ──────────────────────────────────────
          _MotivationalCard(
            message: _expenseMotivation(todayTotal, weekTotal),
            color: _expenseColor(todayTotal),
            emoji: _expenseEmoji(todayTotal),
          ),
          const SizedBox(height: 20),

          // ── Summary row ────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _statCard(
                  "Today",
                  "₹${todayTotal.toStringAsFixed(0)}",
                  "📅",
                  AppTheme.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  "This Week",
                  "₹${weekTotal.toStringAsFixed(0)}",
                  "📆",
                  AppTheme.secondary,
                ),
              ),
            ],
          ),

          if (totals.isEmpty) ...[
            const SizedBox(height: 20),
            _emptyCard("No expenses recorded yet", "💰"),
          ] else ...[
            // ── Today's expense log ────────────────────────────────
            const SizedBox(height: 28),
            _sectionTitle("Today's Activity"),
            const SizedBox(height: 12),
            if (todayItems.isEmpty)
              _emptyCard("No expenses logged today", "🌿")
            else
              _ExpenseTimeline(
                items: todayItems
                    .map((e) => {'amount': e.amount, 'category': e.category})
                    .toList(),
              ),

            // ── Category breakdown ─────────────────────────────────
            const SizedBox(height: 28),
            _sectionTitle("By Category"),
            const SizedBox(height: 12),
            ...() {
              final maxVal = totals.values.reduce((a, b) => a > b ? a : b);
              return totals.entries.map(
                (entry) => Container(
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                ),
              );
            }(),
          ],
        ],
      ),
    );
  }
}

// Expense timeline - shows today's individual expense entries with time
class _ExpenseTimeline extends StatelessWidget {
  const _ExpenseTimeline({required this.items});

  /// Each item is a map: { 'name': String, 'amount': double, 'category': String,
  ///                        'time': DateTime, 'emoji': String? }
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    // Sort by time descending (most recent first)
    final sorted = [
      ...items,
    ]..sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));

    return Column(
      children: List.generate(sorted.length, (i) {
        final item = sorted[i];
        final time = item['time'] as DateTime;
        final isLast = i == sorted.length - 1;
        final hour = time.hour;
        final min = time.minute.toString().padLeft(2, '0');
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour % 12 == 0 ? 12 : hour % 12;
        final timeLabel = "$displayHour:$min $period";

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time
              SizedBox(
                width: 72,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    timeLabel,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Dot + line
              Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accent.withOpacity(0.15),
                      border: Border.all(color: AppTheme.accent, width: 2),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(width: 2, color: AppTheme.surfaceLight),
                    ),
                  if (isLast) const SizedBox(height: 16),
                ],
              ),
              const SizedBox(width: 12),
              // Expense card
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.surfaceLight),
                  ),
                  child: Row(
                    children: [
                      Text(
                        item['emoji'] as String? ?? '💳',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] as String? ?? 'Expense',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['category'] as String? ?? 'Uncategorized',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "₹${(item['amount'] as double).toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOTIVATIONAL CARD
// ─────────────────────────────────────────────────────────────────────────────

class _MotivationalCard extends StatelessWidget {
  const _MotivationalCard({
    required this.message,
    required this.color,
    required this.emoji,
  });

  final String message;
  final Color color;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

Widget _sectionTitle(String title) => Text(
  title,
  style: const TextStyle(
    color: AppTheme.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w800,
  ),
);

Widget _statCard(String label, String value, String emoji, Color color) =>
    Container(
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
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );

Widget _statusBadge(String text, bool success) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: success ? AppTheme.success.withOpacity(0.15) : AppTheme.surfaceLight,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    text,
    style: TextStyle(
      color: success ? AppTheme.success : AppTheme.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
  ),
);

Widget _emptyCard(String msg, String emoji) => Container(
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
      Text(msg, style: const TextStyle(color: AppTheme.textSecondary)),
    ],
  ),
);

String _weekdayLabel(List<int> days) {
  const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days.map((d) => names[d]).join(', ');
}

// ── Habit motivation ───────────────────────────────────────────────────────

String _habitMotivation(int done, int total) {
  if (total == 0) return "Add your first habit and start building momentum!";
  if (done == 0)
    return "A new day, a fresh start. You've got this — let's knock out today's habits!";
  if (done == total)
    return "Perfect day! Every single habit done. You're unstoppable! 🎉";
  final remaining = total - done;
  if (done >= total * 0.75)
    return "Almost there! Just $remaining more to go. Finish strong!";
  if (done >= total * 0.5)
    return "Halfway through! Keep the momentum going — $remaining habits left.";
  return "Great start! $done down, $remaining to go. Keep moving!";
}

Color _habitColor(int done, int total) {
  if (total == 0) return AppTheme.primary;
  if (done == total && total > 0) return AppTheme.success;
  if (done == 0) return AppTheme.textSecondary;
  final pct = done / total;
  if (pct >= 0.75) return AppTheme.success;
  if (pct >= 0.5) return AppTheme.warning;
  return AppTheme.primary;
}

String _habitEmoji(int done, int total) {
  if (total == 0) return '🌱';
  if (done == total && total > 0) return '🏆';
  if (done == 0) return '☀️';
  final pct = done / total;
  if (pct >= 0.75) return '🔥';
  if (pct >= 0.5) return '💪';
  return '⚡';
}

// ── Expense motivation ─────────────────────────────────────────────────────

String _expenseMotivation(double todayTotal, double weekTotal) {
  if (todayTotal == 0 && weekTotal == 0) {
    return "No spending today — your wallet is looking healthy!";
  }
  if (todayTotal == 0) {
    return "Zero spending today! Your week total is ₹${weekTotal.toStringAsFixed(0)} — great self-control.";
  }
  if (todayTotal < 200) {
    return "Light spending day at ₹${todayTotal.toStringAsFixed(0)}. You're being mindful with money!";
  }
  if (todayTotal < 500) {
    return "Moderate spending today. Track your categories to see where your money flows.";
  }
  return "You've spent ₹${todayTotal.toStringAsFixed(0)} today. Keep an eye on the weekly total!";
}

Color _expenseColor(double todayTotal) {
  if (todayTotal == 0) return AppTheme.success;
  if (todayTotal < 300) return AppTheme.primary;
  if (todayTotal < 600) return AppTheme.warning;
  return AppTheme.accent;
}

String _expenseEmoji(double todayTotal) {
  if (todayTotal == 0) return '🌿';
  if (todayTotal < 300) return '👍';
  if (todayTotal < 600) return '👀';
  return '💸';
}
