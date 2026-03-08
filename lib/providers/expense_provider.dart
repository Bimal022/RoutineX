import 'package:flutter/material.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];

  List<Expense> get expenses => _expenses;

  final List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Health',
    'Entertainment',
    'Bills',
    'Other',
  ];

  void addExpense(
    double amount,
    String category,
    String note,
    DateTime date,
  ) {
    _expenses.add(
      Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        category: category,
        note: note,
        date: date,
      ),
    );
    notifyListeners();
  }

  void removeExpense(String id) {
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  double todayTotal() {
    DateTime today = DateTime.now();
    return _expenses
        .where(
          (e) =>
              e.date.day == today.day &&
              e.date.month == today.month &&
              e.date.year == today.year,
        )
        .fold(0, (sum, item) => sum + item.amount);
  }

  double weekTotal() {
    DateTime now = DateTime.now();
    DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _expenses
        .where(
          (e) =>
              e.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
              e.date.isBefore(now.add(const Duration(days: 1))),
        )
        .fold(0, (sum, item) => sum + item.amount);
  }

  List<Expense> get todayExpenses {
    DateTime today = DateTime.now();
    return _expenses
        .where(
          (e) =>
              e.date.day == today.day &&
              e.date.month == today.month &&
              e.date.year == today.year,
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Map<String, double> categoryTotals() {
    final map = <String, double>{};
    for (final e in _expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }
}