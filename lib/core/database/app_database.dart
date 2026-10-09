import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/expenses/data/models/expense_model.dart';

/// Singleton SQLite database helper
///
/// Usage:  `final db = await AppDatabase.instance.database;`
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static Database? _db;

  static const _kDatabaseName = 'vku_expense_ocr.db';
  static const _kDatabaseVersion = 1;
  static const _kTableExpenses = 'expenses';

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _kDatabaseName);
    return openDatabase(path, version: _kDatabaseVersion, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_kTableExpenses (
        id         TEXT    PRIMARY KEY NOT NULL,
        merchant   TEXT    NOT NULL,
        amount     REAL    NOT NULL,
        date       TEXT    NOT NULL,
        category   TEXT    NOT NULL,
        photoPath  TEXT,
        rawOcrText TEXT,
        note       TEXT
      )
    ''');
  }

  // ── CRUD ─────────────────────────────────────────────────────────

  Future<void> insertExpense(ExpenseModel expense) async {
    final db = await database;
    await db.insert(
      _kTableExpenses,
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExpenseModel>> getAllExpenses() async {
    final db = await database;
    final maps = await db.query(
      _kTableExpenses,
      orderBy: 'date DESC',
    );
    return maps.map(ExpenseModel.fromMap).toList();
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    final db = await database;
    await db.update(
      _kTableExpenses,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteExpense(String id) async {
    final db = await database;
    await db.delete(
      _kTableExpenses,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
