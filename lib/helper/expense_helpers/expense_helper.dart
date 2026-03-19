import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:routinex/models/expense.dart';
import 'package:routinex/models/habit.dart';
import 'package:routinex/providers/expense_provider.dart';
import 'package:routinex/providers/habit_provider.dart';
import 'package:routinex/theme.dart';

class ExpenseHelper {
  static void showEditExpenseSheet(
  BuildContext context,
  Expense expense,
  ExpenseProvider provider,
) {
  final amountController =
      TextEditingController(text: expense.amount.toStringAsFixed(0));
  final noteController = TextEditingController(text: expense.note);
  String selectedCategory = expense.category;
  DateTime selectedDate = expense.date;

  final Map<String, String> emojis = {
    'Food': '🍜', 'Transport': '🚗', 'Shopping': '🛍️',
    'Health': '💊', 'Entertainment': '🎬', 'Bills': '📄', 'Other': '💸',
  };

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Edit expense',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                // Delete button in sheet
                IconButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    provider.removeExpense(expense.id);
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Amount ──────────────────────────────────────
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                prefixText: '₹  ',
                prefixStyle: TextStyle(
                    color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                hintText: 'Amount',
                hintStyle: TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Note ────────────────────────────────────────
            TextField(
              controller: noteController,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Note (optional)',
                hintStyle: TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Category chips ───────────────────────────────
            Text('Category',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.categories.map((cat) {
                final selected = cat == selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary.withOpacity(0.15)
                          : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primary.withOpacity(0.5)
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      '${emojis[cat]} $cat',
                      style: TextStyle(
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Date picker ──────────────────────────────────
            Text('Date',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: selectedDate,
                  firstDate: DateTime.now().subtract(
                      const Duration(days: 365)), // up to 1 year back
                  lastDate: DateTime.now(),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: AppTheme.primary,
                        surface: AppTheme.surface,
                        onSurface: AppTheme.textPrimary,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => selectedDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 16, color: AppTheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('EEE, d MMM yyyy').format(selectedDate),
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right,
                        size: 18, color: AppTheme.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Save button ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final amount =
                      double.tryParse(amountController.text.trim()) ?? 0;
                  if (amount <= 0) return;

                  provider.updateExpense(
                    expense.id,
                    amount: amount,
                    category: selectedCategory,
                    note: noteController.text.trim(),
                    date: selectedDate,
                  );
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save changes',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
