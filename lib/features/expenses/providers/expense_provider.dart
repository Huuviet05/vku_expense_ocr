import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/expense_model.dart';
import '../data/repositories/expense_repository.dart';
import '../../../core/database/app_database.dart';

// ── Database repository provider ──────────────────────────────────
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(AppDatabase.instance);
});

/// Async notifier that manages the full list of expenses in memory
/// and syncs with SQLite for persistence.
class ExpenseNotifier extends AsyncNotifier<List<ExpenseModel>> {
  static const _uuid = Uuid();

  ExpenseRepository get _repo => ref.read(expenseRepositoryProvider);

  @override
  Future<List<ExpenseModel>> build() async {
    return _repo.getAllExpenses();
  }

  // ── Commands ─────────────────────────────────────────────────────

  Future<void> addExpense({
    required String merchant,
    required double amount,
    required DateTime date,
    required ExpenseCategory category,
    String? note,
    String? photoPath,
    String? rawOcrText,
  }) async {
    final expense = ExpenseModel(
      id: _uuid.v4(),
      merchant: merchant,
      amount: amount,
      date: date,
      category: category,
      note: note,
      photoPath: photoPath,
      rawOcrText: rawOcrText,
    );
    await _repo.insertExpense(expense);
    // Optimistic prepend — avoids full reload from DB
    final prev = state.valueOrNull ?? [];
    state = AsyncData([expense, ...prev]);
  }

  Future<void> updateExpense(ExpenseModel updated) async {
    await _repo.updateExpense(updated);
    state = AsyncData(
      (state.valueOrNull ?? []).map((e) => e.id == updated.id ? updated : e).toList(),
    );
  }

  Future<void> deleteExpense(String id) async {
    await _repo.deleteExpense(id);
    state = AsyncData(
      (state.valueOrNull ?? []).where((e) => e.id != id).toList(),
    );
  }
}

/// The main provider used throughout the app
final expenseProvider =
    AsyncNotifierProvider<ExpenseNotifier, List<ExpenseModel>>(
  ExpenseNotifier.new,
);

// ── Derived providers ─────────────────────────────────────────────

/// Total spent this month
final monthlyTotalProvider = Provider<double>((ref) {
  final now = DateTime.now();
  return ref
          .watch(expenseProvider)
          .valueOrNull
          ?.where((e) => e.date.year == now.year && e.date.month == now.month)
          .fold<double>(0.0, (sum, e) => sum + e.amount) ??
      0;
});

/// Totals grouped by category for the pie chart
final categoryTotalsProvider = Provider<Map<ExpenseCategory, double>>((ref) {
  final expenses = ref.watch(expenseProvider).valueOrNull ?? [];
  final map = <ExpenseCategory, double>{};
  for (final e in expenses) {
    map[e.category] = (map[e.category] ?? 0) + e.amount;
  }
  return map;
});

/// Daily totals for the last 7 days (for bar chart)
final weeklyDailyTotalsProvider = Provider<List<({DateTime day, double total})>>((ref) {
  final expenses = ref.watch(expenseProvider).valueOrNull ?? [];
  final now = DateTime.now();

  return List.generate(7, (i) {
    final day = DateTime(now.year, now.month, now.day - (6 - i));
    final total = expenses
        .where((e) =>
            e.date.year == day.year &&
            e.date.month == day.month &&
            e.date.day == day.day)
        .fold(0.0, (s, e) => s + e.amount);
    return (day: day, total: total);
  });
});
