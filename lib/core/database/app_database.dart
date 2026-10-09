import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/expenses/data/models/expense_model.dart';

/// Singleton SQLite database helper with Web persistent storage (localStorage)
///
/// Usage:  `final db = await AppDatabase.instance.database;`
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static Database? _db;

  static const _kDatabaseName = 'vku_expense_ocr.db';
  static const _kDatabaseVersion = 1;
  static const _kTableExpenses = 'expenses';
  static const _kPrefExpensesKey = 'vku_saved_expenses_v1';

  // ── Default sample expenses for initial first-time launch ─────────
  static final List<ExpenseModel> _defaultSamples = [
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

  // In-memory runtime cache
  static List<ExpenseModel> _inMemoryList = [];
  static bool _webInitialized = false;

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

  // ── Persistent SharedPreferences / localStorage Helpers ───────────

  Future<void> _saveToPrefs(List<ExpenseModel> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(items.map((e) => e.toMap()).toList());
      await prefs.setString(_kPrefExpensesKey, jsonString);
    } catch (e) {
      debugPrint('SharedPreferences save error: $e');
    }
  }

  Future<List<ExpenseModel>?> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_kPrefExpensesKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded
            .map((item) =>
                ExpenseModel.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('SharedPreferences load error: $e');
    }
    return null;
  }

  // ── CRUD Operations ───────────────────────────────────────────────

  Future<void> insertExpense(ExpenseModel expense) async {
    if (kIsWeb) {
      _inMemoryList.removeWhere((e) => e.id == expense.id);
      _inMemoryList.insert(0, expense);
      await _saveToPrefs(_inMemoryList);
      return;
    }

    final db = await database;
    await db.insert(
      _kTableExpenses,
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Keep prefs in sync as secondary persistent store
    final all = await db.query(_kTableExpenses, orderBy: 'date DESC');
    await _saveToPrefs(all.map(ExpenseModel.fromMap).toList());
  }

  Future<List<ExpenseModel>> getAllExpenses() async {
    if (kIsWeb) {
      if (!_webInitialized) {
        final saved = await _loadFromPrefs();
        if (saved != null && saved.isNotEmpty) {
          _inMemoryList = saved;
        } else {
          _inMemoryList = List<ExpenseModel>.from(_defaultSamples);
          await _saveToPrefs(_inMemoryList);
        }
        _webInitialized = true;
      }
      return List<ExpenseModel>.from(_inMemoryList)
        ..sort((a, b) => b.date.compareTo(a.date));
    }

    final db = await database;
    final maps = await db.query(
      _kTableExpenses,
      orderBy: 'date DESC',
    );

    if (maps.isEmpty) {
      // First-time mobile launch: Check prefs or seed default samples
      final fromPrefs = await _loadFromPrefs();
      final toSeed = (fromPrefs != null && fromPrefs.isNotEmpty)
          ? fromPrefs
          : _defaultSamples;

      for (final e in toSeed) {
        await db.insert(_kTableExpenses, e.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await _saveToPrefs(toSeed);
      return List<ExpenseModel>.from(toSeed)
        ..sort((a, b) => b.date.compareTo(a.date));
    }

    final list = maps.map(ExpenseModel.fromMap).toList();
    // Background sync to prefs
    _saveToPrefs(list);
    return list;
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    if (kIsWeb) {
      final index = _inMemoryList.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _inMemoryList[index] = expense;
      } else {
        _inMemoryList.insert(0, expense);
      }
      await _saveToPrefs(_inMemoryList);
      return;
    }

    final db = await database;
    await db.update(
      _kTableExpenses,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );

    final all = await db.query(_kTableExpenses, orderBy: 'date DESC');
    await _saveToPrefs(all.map(ExpenseModel.fromMap).toList());
  }

  Future<void> deleteExpense(String id) async {
    if (kIsWeb) {
      _inMemoryList.removeWhere((e) => e.id == id);
      await _saveToPrefs(_inMemoryList);
      return;
    }

    final db = await database;
    await db.delete(
      _kTableExpenses,
      where: 'id = ?',
      whereArgs: [id],
    );

    final all = await db.query(_kTableExpenses, orderBy: 'date DESC');
    await _saveToPrefs(all.map(ExpenseModel.fromMap).toList());
  }
}
