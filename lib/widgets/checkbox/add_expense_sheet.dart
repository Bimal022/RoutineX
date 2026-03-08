import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:routinex/providers/expense_provider.dart';
import '../../theme.dart';
class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = 'Food';

  final Map<String, String> _categoryEmojis = {
    'Food': '🍔',
    'Transport': '🚗',
    'Shopping': '🛍️',
    'Health': '💊',
    'Entertainment': '🎬',
    'Bills': '📄',
    'Other': '💸',
  };

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    Provider.of<ExpenseProvider>(context, listen: false).addExpense(
      amount,
      _selectedCategory,
      _noteController.text.trim(),
      DateTime.now(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categoryEmojis.keys.toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Add Expense",
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            // Category selector
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = categories[i];
                  final selected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primary.withOpacity(0.2)
                            : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppTheme.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _categoryEmojis[cat]!,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat,
                            style: TextStyle(
                              color: selected
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: "Amount (₹)",
                hintText: "0.00",
                prefixText: "₹ ",
                prefixStyle: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: "Note (optional)",
                hintText: "e.g. Lunch with team",
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                ),
                child: const Text(
                  "Add Expense",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}