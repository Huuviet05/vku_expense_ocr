import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/expenses/data/models/expense_model.dart';

/// Singleton SQLite database helper with Web fallback
///
/// Usage:  `final db = await AppDatabase.instance.database;`
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static Database? _db;

  static const _kDatabaseName = 'vku_expense_ocr.db';
  static const _kDatabaseVersion = 1;
  static const _kTableExpenses = 'expenses';

  // ── In-memory store for Web demo (Cloudflare Pages / Vercel) ──────
  static final List<ExpenseModel> _webExpenses = [
    ExpenseModel(
      id: 'demo-1',
      merchant: 'Highlands Coffee',
      amount: 89000,
      date: DateTime.now().subtract(const Duration(hours: 4)),
      category: ExpenseCategory.food,
      note: 'Cà phê phin sữa đá & Trà sen vàng',
      rawOcrText: 'HIGHLANDS COFFEE\nTỔNG CỘNG THANH TOÁN: 89.000 VNĐ',
    ),
    ExpenseModel(
      id: 'demo-2',
      merchant: 'WinMart+',
      amount: 145000,
      date: DateTime.now().subtract(const Duration(days: 1)),
      category: ExpenseCategory.shopping,
      note: 'Sữa tươi Vinamilk, Bánh mì',
      rawOcrText: 'WINMART+\nTHANH TOÁN: 145.000 VNĐ',
    ),
    ExpenseModel(
      id: 'demo-3',
      merchant: 'Grab Car',
      amount: 62000,
      date: DateTime.now().subtract(const Duration(days: 2)),
      category: ExpenseCategory.transport,
      note: 'Chuyến xe VKU đến Cầu Rồng',
      rawOcrText: 'GRAB VIETNAM\nTỔNG THANH TOÁN: 62.000 VNĐ',
    ),
    ExpenseModel(
      id: 'demo-4',
      merchant: 'Điện lực EVN',
      amount: 215000,
      date: DateTime.now().subtract(const Duration(days: 3)),
      category: ExpenseCategory.utilities,
      note: 'Hóa đơn tiền điện sinh hoạt',
      rawOcrText: 'EVN ĐÀ NẴNG\nTỔNG TIỀN: 215.000 VNĐ',
    ),
  ];

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
    if (kIsWeb) {
      _webExpenses.removeWhere((e) => e.id == expense.id);
      _webExpenses.insert(0, expense);
      return;
    }
    final db = await database;
    await db.insert(
      _kTableExpenses,
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExpenseModel>> getAllExpenses() async {
    if (kIsWeb) {
      return List<ExpenseModel>.from(_webExpenses)
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    final db = await database;
    final maps = await db.query(
      _kTableExpenses,
      orderBy: 'date DESC',
    );
    return maps.map(ExpenseModel.fromMap).toList();
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    if (kIsWeb) {
      final index = _webExpenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _webExpenses[index] = expense;
      }
      return;
    }
    final db = await database;
    await db.update(
      _kTableExpenses,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteExpense(String id) async {
    if (kIsWeb) {
      _webExpenses.removeWhere((e) => e.id == id);
      return;
    }
    final db = await database;
    await db.delete(
      _kTableExpenses,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
