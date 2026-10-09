import 'package:vku_expense_ocr/core/database/app_database.dart';
import 'package:vku_expense_ocr/features/expenses/data/models/expense_model.dart';

/// Repository layer — isolates database calls from business logic
class ExpenseRepository {
  const ExpenseRepository(this._db);
  final AppDatabase _db;

  Future<List<ExpenseModel>> getAllExpenses() => _db.getAllExpenses();
  Future<void> insertExpense(ExpenseModel e) => _db.insertExpense(e);
  Future<void> updateExpense(ExpenseModel e) => _db.updateExpense(e);
  Future<void> deleteExpense(String id) => _db.deleteExpense(id);
}
