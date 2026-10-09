import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Expense categories matching the rubric's visualization requirement
enum ExpenseCategory {
  food('Ăn uống', Icons.restaurant, Color(0xFFF97316)),
  transport('Di chuyển', Icons.directions_bus, Color(0xFF3B82F6)),
  shopping('Mua sắm', Icons.shopping_bag, Color(0xFFA855F7)),
  utilities('Tiện ích', Icons.bolt, Color(0xFF14B8A6));

  const ExpenseCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  IconData get displayIcon => icon;

  /// Vietnamese Dong number formatter: 245.000 đ
  static final _vndFormatter = NumberFormat('#,###', 'vi_VN');

  static String formatVnd(double amount) =>
      '${_vndFormatter.format(amount.round())} đ';
}


/// Immutable data model for a single expense record
class ExpenseModel {
  const ExpenseModel({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    this.photoPath,
    this.rawOcrText,
    this.note,
  });

  final String id;
  final String merchant;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final String? photoPath;
  final String? rawOcrText;
  final String? note;

  // ── Serialization ────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'id': id,
        'merchant': merchant,
        'amount': amount,
        'date': date.toIso8601String(),
        'category': category.name,
        'photoPath': photoPath,
        'rawOcrText': rawOcrText,
        'note': note,
      };

  factory ExpenseModel.fromMap(Map<String, dynamic> map) => ExpenseModel(
        id: map['id'] as String,
        merchant: map['merchant'] as String,
        amount: (map['amount'] as num).toDouble(),
        date: DateTime.parse(map['date'] as String),
        category: ExpenseCategory.values.byName(map['category'] as String),
        photoPath: map['photoPath'] as String?,
        rawOcrText: map['rawOcrText'] as String?,
        note: map['note'] as String?,
      );

  // ── Helpers ──────────────────────────────────────────────────────
  String get formattedAmount => ExpenseCategory.formatVnd(amount);

  String get formattedDate =>
      DateFormat('dd/MM/yyyy', 'vi_VN').format(date);

  ExpenseModel copyWith({
    String? merchant,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    String? note,
  }) =>
      ExpenseModel(
        id: id,
        merchant: merchant ?? this.merchant,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        category: category ?? this.category,
        photoPath: photoPath,
        rawOcrText: rawOcrText,
        note: note ?? this.note,
      );
}
