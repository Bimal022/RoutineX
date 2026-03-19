import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:routinex/models/expense.dart';
import '../../providers/habit_provider.dart';
import '../../providers/expense_provider.dart';
import '../../theme.dart';

class ExpensesTab extends StatefulWidget {
  const ExpensesTab({super.key, required this.expenses});
  final ExpenseProvider expenses;

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab>
    with SingleTickerProviderStateMixin {
  // ── Filter state ──────────────────────────────────────────────
  String _dateFilter = 'Today'; // Today | Week | Month | All
  String? _categoryFilter; // null = all categories

  static const _dateOptions = ['Today', 'Week', 'Month', 'All'];

  // ── Derived data ──────────────────────────────────────────────
  List<Expense> get _filtered {
    final all = widget.expenses.expenses;

    // Date window
    final now = DateTime.now();
    DateTime? from;
    if (_dateFilter == 'Today') {
      from = DateTime(now.year, now.month, now.day);
    } else if (_dateFilter == 'Week') {
      from = now.subtract(Duration(days: now.weekday - 1));
      from = DateTime(from.year, from.month, from.day);
    } else if (_dateFilter == 'Month') {
      from = DateTime(now.year, now.month, 1);
    }

    return all.where((e) {
      final afterDate = from == null || !e.date.isBefore(from);
      final matchCat = _categoryFilter == null || e.category == _categoryFilter;
      return afterDate && matchCat;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  double get _filteredTotal => _filtered.fold(0.0, (s, e) => s + e.amount);

  Map<String, double> get _filteredCategoryTotals {
    final map = <String, double>{};
    for (final e in _filtered) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  // Group expenses by calendar date
  Map<String, List<Expense>> get _groupedByDate {
    final groups = <String, List<Expense>>{};
    for (final e in _filtered) {
      final key = DateFormat('yyyy-MM-dd').format(e.date);
      groups.putIfAbsent(key, () => []).add(e);
    }
    return groups;
  }

  // ── UI ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final grouped = _groupedByDate;
    final cats = widget.expenses.categories;
    final catTotals = _filteredCategoryTotals;
    final total = _filteredTotal;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── At-a-glance hero ────────────────────────────────────
          _HeroSummary(
            total: total,
            dateFilter: _dateFilter,
            expenseCount: _filtered.length,
          ),
          const SizedBox(height: 20),

          // ── Date filter pills ───────────────────────────────────
          _FilterRow(
            options: _dateOptions,
            selected: _dateFilter,
            onSelect: (v) => setState(() => _dateFilter = v),
          ),
          const SizedBox(height: 12),

          // ── Category filter chips ───────────────────────────────
          _CategoryChips(
            categories: cats,
            totals: catTotals,
            selected: _categoryFilter,
            onSelect: (c) => setState(
              () => _categoryFilter = _categoryFilter == c ? null : c,
            ),
          ),
          const SizedBox(height: 24),

          // ── Category breakdown bars ─────────────────────────────
          if (catTotals.isNotEmpty) ...[
            _SectionLabel('Spending Breakdown'),
            const SizedBox(height: 10),
            _CategoryBars(totals: catTotals, grandTotal: total),
            const SizedBox(height: 28),
          ],

          // ── Timeline grouped by date ────────────────────────────
          if (grouped.isEmpty)
            _EmptyState(filter: _dateFilter, category: _categoryFilter)
          else ...[
            _SectionLabel('Activity Log'),
            const SizedBox(height: 12),
            ...grouped.entries.map((entry) {
              final dayTotal = entry.value.fold(0.0, (s, e) => s + e.amount);
              return _DayGroup(
                dateKey: entry.key,
                expenses: entry.value,
                dayTotal: dayTotal,
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  HERO SUMMARY  — big number, contextual label
// ═══════════════════════════════════════════════════════════════════
class _HeroSummary extends StatelessWidget {
  const _HeroSummary({
    required this.total,
    required this.dateFilter,
    required this.expenseCount,
  });

  final double total;
  final String dateFilter;
  final int expenseCount;

  String get _label {
    switch (dateFilter) {
      case 'Today':
        return "spent today";
      case 'Week':
        return "spent this week";
      case 'Month':
        return "spent this month";
      default:
        return "total recorded";
    }
  }

  String get _emoji {
    if (total == 0) return '🌿';
    if (dateFilter == 'Today' && total > 2000) return '🔥';
    if (dateFilter == 'Today' && total > 1000) return '⚡';
    return '📊';
  }

  Color get _accentColor {
    if (total == 0) return const Color(0xFF4CAF50);
    if (dateFilter == 'Today' && total > 2000) return const Color(0xFFFF5252);
    if (dateFilter == 'Today' && total > 1000) return const Color(0xFFFF9800);
    return AppTheme.accent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accentColor.withOpacity(0.18),
            _accentColor.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(_emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "₹${_fmt(total)}",
                  style: TextStyle(
                    color: _accentColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$expenseCount txn${expenseCount == 1 ? '' : 's'}",
                  style: TextStyle(
                    color: _accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DATE FILTER ROW
// ═══════════════════════════════════════════════════════════════════
class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((opt) {
        final isActive = opt == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.accent : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? AppTheme.accent : AppTheme.surfaceLight,
                ),
              ),
              child: Text(
                opt,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CATEGORY CHIPS  — tap to filter, shows amount inline
// ═══════════════════════════════════════════════════════════════════
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.totals,
    required this.selected,
    required this.onSelect,
  });

  final List<String> categories;
  final Map<String, double> totals;
  final String? selected;
  final ValueChanged<String> onSelect;

  static const _catEmoji = {
    'Food': '🍜',
    'Transport': '🚌',
    'Shopping': '🛍️',
    'Health': '💊',
    'Entertainment': '🎬',
    'Bills': '📃',
    'Other': '📦',
  };

  @override
  Widget build(BuildContext context) {
    // Only show categories that have expenses in current filter
    final activeCats = categories.where((c) => (totals[c] ?? 0) > 0).toList();

    if (activeCats.isEmpty) return const SizedBox();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: activeCats.map((cat) {
          final isActive = selected == cat;
          final amt = totals[cat] ?? 0;
          final emoji = _catEmoji[cat] ?? '💳';
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.accent.withOpacity(0.15)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppTheme.accent : AppTheme.surfaceLight,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(
                    cat,
                    style: TextStyle(
                      color: isActive
                          ? AppTheme.accent
                          : AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "₹${_fmt(amt)}",
                    style: TextStyle(
                      color: isActive
                          ? AppTheme.accent
                          : AppTheme.textSecondary.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CATEGORY BARS
// ═══════════════════════════════════════════════════════════════════
class _CategoryBars extends StatelessWidget {
  const _CategoryBars({required this.totals, required this.grandTotal});
  final Map<String, double> totals;
  final double grandTotal;

  static const _barColors = [
    Color(0xFF6C63FF),
    Color(0xFFFF6584),
    Color(0xFF43C59E),
    Color(0xFFFFB347),
    Color(0xFF4FC3F7),
    Color(0xFFBA68C8),
    Color(0xFFFF8A65),
  ];

  @override
  Widget build(BuildContext context) {
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.first.value;

    return Column(
      children: List.generate(sorted.length, (i) {
        final entry = sorted[i];
        final pct = grandTotal > 0 ? entry.value / grandTotal : 0.0;
        final color = _barColors[i % _barColors.length];

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
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
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.key,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        "${(pct * 100).toStringAsFixed(0)}%",
                        style: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "₹${_fmt(entry.value)}",
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: maxVal > 0 ? entry.value / maxVal : 0,
                  backgroundColor: AppTheme.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DAY GROUP  — header with date + day total, then timeline
// ═══════════════════════════════════════════════════════════════════
class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.dateKey,
    required this.expenses,
    required this.dayTotal,
  });

  final String dateKey; // 'yyyy-MM-dd'
  final List<Expense> expenses;
  final double dayTotal;

  String get _humanDate {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    return DateFormat('EEE, d MMM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _humanDate,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "₹${_fmt(dayTotal)}",
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Timeline for the day
        _ExpenseTimeline(items: expenses),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  TIMELINE  — unchanged visual, now takes List<Expense>
// ═══════════════════════════════════════════════════════════════════
class _ExpenseTimeline extends StatelessWidget {
  const _ExpenseTimeline({required this.items});
  final List<Expense> items;

  static const _catEmoji = {
    'Food': '🍜',
    'Transport': '🚌',
    'Shopping': '🛍️',
    'Health': '💊',
    'Entertainment': '🎬',
    'Bills': '📃',
    'Other': '📦',
  };

  @override
  Widget build(BuildContext context) {
    final sorted = [...items]..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: List.generate(sorted.length, (i) {
        final e = sorted[i];
        final isLast = i == sorted.length - 1;
        final h = e.date.hour;
        final m = e.date.minute.toString().padLeft(2, '0');
        final period = h >= 12 ? 'PM' : 'AM';
        final displayH = h % 12 == 0 ? 12 : h % 12;
        final timeLabel = "$displayH:$m $period";
        final emoji = _catEmoji[e.category] ?? '💳';

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time column
              SizedBox(
                width: 68,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    timeLabel,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Dot + line
              Column(
                children: [
                  const SizedBox(height: 18),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accent.withOpacity(0.12),
                      border: Border.all(color: AppTheme.accent, width: 2),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(width: 2, color: AppTheme.surfaceLight),
                    ),
                  if (isLast) const SizedBox(height: 14),
                ],
              ),
              const SizedBox(width: 10),
              // Card
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.surfaceLight),
                  ),
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.note.isNotEmpty ? e.note : 'Expense',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              e.category,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "₹${_fmt(e.amount)}",
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
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

// ═══════════════════════════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: AppTheme.textSecondary.withOpacity(0.6),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter, required this.category});
  final String filter;
  final String? category;

  @override
  Widget build(BuildContext context) {
    final msg = category != null
        ? 'No $category expenses for $filter'
        : 'No expenses for $filter';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        children: [
          const Text('🌿', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          Text(
            msg,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Format: 1234 → "1,234"  |  12345 → "12.3k"
String _fmt(double v) {
  if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
  if (v >= 1000) {
    final s = v.toStringAsFixed(0);
    // insert comma
    if (s.length > 3) {
      return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
    }
    return s;
  }
  return v.toStringAsFixed(0);
}
