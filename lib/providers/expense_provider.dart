import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  final List<Expense> _expenses = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Helpers ───────────────────────────────────────────────────
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  CollectionReference get _expensesCol =>
      _firestore.collection('users').doc(_uid).collection('expenses');

  // ── Getters ───────────────────────────────────────────────────
  List<Expense> get expenses => _expenses;

  final List<String> categories = [
    'Food', 'Transport', 'Shopping', 'Health',
    'Entertainment', 'Bills', 'Other',
  ];

  // ── Load ──────────────────────────────────────────────────────
  /// Call once after sign-in / onboarding completes.
  Future<void> loadExpenses() async {
    try {
      // Load only the last 30 days to keep it snappy
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      final snap = await _expensesCol
          .where('date', isGreaterThanOrEqualTo: cutoff.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      _expenses.clear();
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        _expenses.add(_expenseFromMap(data));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ExpenseProvider.loadExpenses error: $e');
    }
  }

  // ── Add ───────────────────────────────────────────────────────
  Future<void> addExpense(
    double amount,
    String category,
    String note,
    DateTime date,
  ) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final expense = Expense(
      id: id,
      amount: amount,
      category: category,
      note: note,
      date: date,
    );

    _expenses.insert(0, expense); // optimistic — newest first
    notifyListeners();

    try {
      await _expensesCol.doc(id).set({
        'id': id,
        'amount': amount,
        'category': category,
        'note': note,
        'date': date.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('ExpenseProvider.addExpense error: $e');
      // Roll back on failure
      _expenses.removeWhere((e) => e.id == id);
      notifyListeners();
    }
  }
  // ── Update ────────────────────────────────────────────────────
Future<void> updateExpense(
  String id, {
  required double amount,
  required String category,
  required String note,
  required DateTime date,
}) async {
  final index = _expenses.indexWhere((e) => e.id == id);
  if (index < 0) return;

  final old = _expenses[index];

  // Optimistic update
  _expenses[index] = Expense(
    id: id,
    amount: amount,
    category: category,
    note: note,
    date: date,
  );
  notifyListeners();

  try {
    await _expensesCol.doc(id).update({
      'amount': amount,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
    });
  } catch (e) {
    debugPrint('ExpenseProvider.updateExpense error: $e');
    // Roll back on failure
    _expenses[index] = old;
    notifyListeners();
  }
}
  // ── Remove ────────────────────────────────────────────────────
  Future<void> removeExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();

    try {
      await _expensesCol.doc(id).delete();
    } catch (e) {
      debugPrint('ExpenseProvider.removeExpense error: $e');
    }
  }

  // ── Queries ───────────────────────────────────────────────────
  double todayTotal() {
    final today = DateTime.now();
    return _expenses
        .where((e) =>
            e.date.day == today.day &&
            e.date.month == today.month &&
            e.date.year == today.year)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double weekTotal() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek =
        DateTime(weekStart.year, weekStart.month, weekStart.day);
    return _expenses
        .where((e) => e.date.isAfter(
            startOfWeek.subtract(const Duration(seconds: 1))))
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  List<Expense> get todayExpenses {
    final today = DateTime.now();
    return _expenses
        .where((e) =>
            e.date.day == today.day &&
            e.date.month == today.month &&
            e.date.year == today.year)
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

  // ── Clear on sign-out ─────────────────────────────────────────
  void clear() {
    _expenses.clear();
    notifyListeners();
  }

  // ── Helper ────────────────────────────────────────────────────
  Expense _expenseFromMap(Map<String, dynamic> data) {
    return Expense(
      id: data['id'] as String,
      amount: (data['amount'] as num).toDouble(),
      category: data['category'] as String,
      note: data['note'] as String? ?? '',
      date: DateTime.parse(data['date'] as String),
    );
  }
}