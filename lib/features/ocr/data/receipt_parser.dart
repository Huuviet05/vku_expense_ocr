import '../../expenses/data/models/expense_model.dart';

/// Data class representing structured receipt details extracted via OCR + Regex heuristics
class ParsedReceiptResult {
  const ParsedReceiptResult({
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    required this.candidateAmounts,
    required this.rawText,
    this.photoPath,
  });

  final String merchant;
  final double amount;
  final DateTime? date;
  final ExpenseCategory category;
  final List<double> candidateAmounts;
  final String rawText;
  final String? photoPath;

  ParsedReceiptResult copyWith({
    String? merchant,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    List<double>? candidateAmounts,
    String? rawText,
    String? photoPath,
  }) {
    return ParsedReceiptResult(
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      candidateAmounts: candidateAmounts ?? this.candidateAmounts,
      rawText: rawText ?? this.rawText,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}

/// Advanced Regex Heuristics Engine for Vietnamese & International receipts
/// (Compliant with Week 8 Lecture & Rubric Specifications)
class ReceiptParser {
  ReceiptParser._();

  /// Parse raw OCR string into structured receipt information
  static ParsedReceiptResult parse(String rawText, {String? photoPath}) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final candidateAmounts = _extractAllAmounts(lines);
    final total = _extractTotalAmount(lines, candidateAmounts);
    final merchant = _extractMerchant(lines);
    final date = _extractDate(lines);
    final category = _guessCategory(merchant, rawText);

    return ParsedReceiptResult(
      merchant: merchant,
      amount: total,
      date: date,
      category: category,
      candidateAmounts: candidateAmounts,
      rawText: rawText,
      photoPath: photoPath,
    );
  }

  /// ── 1. Total Amount Extraction with Multi-pass Regex ───────────
  static double _extractTotalAmount(
    List<String> lines,
    List<double> candidateAmounts,
  ) {
    // High-confidence Vietnamese & English total keywords
    final totalKeywords = RegExp(
      r'(?:tổng\s*tiền|tổng\s*cộng|thanh\s*toán|tiền\s*thanh\s*toán|'
      r'tổng\s*thanh\s*toán|thành\s*tiền|cộng\s*tiền\s*hàng|'
      r'cộng\s*tiền|phải\s*trả|tổng\s*bill|tiền\s*mặt|'
      r'total|grand\s*total|amount\s*due|net\s*amount|total\s*due|sum)',
      caseSensitive: false,
    );

    // Number extraction pattern matching 150.000, 150,000, 150000, etc.
    final numberPattern = RegExp(r'[\d]{1,3}(?:[.,\s]\d{3})*(?:[.,]\d{1,2})?|\b\d{4,9}\b');

    // Pass 1: Look for total keyword on the line and extract number from that line
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (totalKeywords.hasMatch(line)) {
        final matches = numberPattern.allMatches(line);
        if (matches.isNotEmpty) {
          // Typically the last match on a "Total" line is the grand total
          final parsed = _parseCleanNumber(matches.last.group(0)!);
          if (parsed != null && parsed > 0) {
            return parsed;
          }
        }

        // Pass 2: Look-ahead on subsequent 1-2 lines (common when keyword is label and number is below)
        for (int j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j];
          final nextMatches = numberPattern.allMatches(nextLine);
          if (nextMatches.isNotEmpty) {
            final parsed = _parseCleanNumber(nextMatches.last.group(0)!);
            if (parsed != null && parsed > 0) {
              return parsed;
            }
          }
        }
      }
    }

    // Pass 3: Fallback to largest detected candidate amount (often total bill is largest)
    if (candidateAmounts.isNotEmpty) {
      return candidateAmounts.first; // candidateAmounts is sorted descending
    }

    return 0.0;
  }

  /// ── 2. Candidate Amounts Collector ─────────────────────────────
  static List<double> _extractAllAmounts(List<String> lines) {
    final numberPattern = RegExp(r'[\d]{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?|\b\d{4,9}\b');
    final setOfAmounts = <double>{};

    for (final line in lines) {
      for (final m in numberPattern.allMatches(line)) {
        final val = _parseCleanNumber(m.group(0)!);
        // Realistic expense bounds: between 1,000 VND and 100,000,000 VND
        if (val != null && val >= 1000 && val <= 100000000) {
          setOfAmounts.add(val);
        }
      }
    }

    final sorted = setOfAmounts.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }

  /// Clean number string like "150.000", "150,000", "150.000đ" into double
  static double? _parseCleanNumber(String raw) {
    var cleaned = raw.replaceAll(RegExp(r'[^\d.,]'), '').trim();
    if (cleaned.isEmpty) return null;

    // If format is 150.000 (Vietnamese thousands separator)
    if (cleaned.contains('.') && !cleaned.contains(',')) {
      final parts = cleaned.split('.');
      if (parts.length > 1 && parts.last.length == 3) {
        cleaned = cleaned.replaceAll('.', '');
      } else if (parts.length > 2) {
        cleaned = cleaned.replaceAll('.', '');
      }
    } else if (cleaned.contains(',') && !cleaned.contains('.')) {
      final parts = cleaned.split(',');
      if (parts.length > 1 && parts.last.length == 3) {
        cleaned = cleaned.replaceAll(',', '');
      } else if (parts.length > 2) {
        cleaned = cleaned.replaceAll(',', '');
      }
    } else if (cleaned.contains('.') && cleaned.contains(',')) {
      // E.g. 150.000,00 or 150,000.00
      if (cleaned.lastIndexOf(',') > cleaned.lastIndexOf('.')) {
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        cleaned = cleaned.replaceAll(',', '');
      }
    }

    return double.tryParse(cleaned);
  }

  /// ── 3. Merchant Name Extraction ────────────────────────────────
  static String _extractMerchant(List<String> lines) {
    // Boilerplate headers to ignore
    final ignorePattern = RegExp(
      r'^(?:hóa\s*đơn|phiếu\s*thanh\s*toán|phiếu\s*tính\s*tiền|'
      r'phiếu\s*thu|hóa\s*đơn\s*bán\s*lẻ|hóa\s*đơn\s*gtgt|'
      r'receipt|tax\s*invoice|vat\s*invoice|bill|order|'
      r'kính\s*chào|xin\s*cảm\s*ơn|welcome|thank\s*you|'
      r'đt:|tel:|hotline:|địa\s*chỉ:|đc:|mst:|stk:|ngày|date)',
      caseSensitive: false,
    );

    for (final line in lines.take(8)) {
      final clean = line.replaceAll(RegExp(r'[#*_\-=~]'), '').trim();
      if (clean.length >= 3 && !ignorePattern.hasMatch(clean)) {
        // Exclude lines with only numbers or dates
        if (!RegExp(r'^[\d\s/.:\-]+$').hasMatch(clean)) {
          return clean;
        }
      }
    }

    return lines.isNotEmpty ? lines.first : 'Cửa hàng';
  }

  /// ── 4. Date Extraction ─────────────────────────────────────────
  static DateTime? _extractDate(List<String> lines) {
    // Format: dd/MM/yyyy, dd-MM-yyyy, dd.MM.yyyy
    final slashDate = RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})');

    // Format: Ngày dd tháng MM năm yyyy
    final vnDate = RegExp(
      r'ngày\s*(\d{1,2})\s*tháng\s*(\d{1,2})\s*năm\s*(\d{2,4})',
      caseSensitive: false,
    );

    for (final line in lines) {
      final vnMatch = vnDate.firstMatch(line);
      if (vnMatch != null) {
        final d = int.tryParse(vnMatch.group(1)!);
        final m = int.tryParse(vnMatch.group(2)!);
        var y = int.tryParse(vnMatch.group(3)!);
        if (d != null && m != null && y != null) {
          if (y < 100) y += 2000;
          if (m >= 1 && m <= 12 && d >= 1 && d <= 31) {
            return DateTime(y, m, d);
          }
        }
      }

      final mMatch = slashDate.firstMatch(line);
      if (mMatch != null) {
        final d = int.tryParse(mMatch.group(1)!);
        final m = int.tryParse(mMatch.group(2)!);
        var y = int.tryParse(mMatch.group(3)!);
        if (d != null && m != null && y != null) {
          if (y < 100) y += 2000;
          if (m >= 1 && m <= 12 && d >= 1 && d <= 31) {
            return DateTime(y, m, d);
          }
        }
      }
    }

    return null;
  }

  /// ── 5. Category Heuristic Classification ───────────────────────
  static ExpenseCategory _guessCategory(String merchant, String fullText) {
    final mLower = merchant.toLowerCase();
    final fullLower = '$merchant $fullText'.toLowerCase();

    // Check merchant first (highest confidence)
    if (RegExp(
      r'(?:mart|coop|winmart|vinmart|circle\s*k|gs25|7-eleven|family\s*mart|'
      r'siêu\s*thị|mini\s*mart|shop|store|boutique|zara|uniqlo|shopee|lazada|tiki)',
    ).hasMatch(mLower)) {
      return ExpenseCategory.shopping;
    }

    if (RegExp(
      r'(?:grab|be|xanh\s*sm|gojek|taxi|xăng|petrol|pvoil|'
      r'vé\s*xe|gửi\s*xe|bãi\s*đỗ|vận\s*chuyển|xe\s*buýt|bus|train|vé\s*tàu)',
    ).hasMatch(mLower)) {
      return ExpenseCategory.transport;
    }

    if (RegExp(
      r'(?:điện|nước|internet|wifi|vnpt|viettel|fpt|tiện\s*ích|'
      r'rác|chung\s*cư|phí\s*dịch\s*vụ|tiền\s*nhà|học\s*phí|bill)',
    ).hasMatch(mLower)) {
      return ExpenseCategory.utilities;
    }

    if (RegExp(
      r'(?:cafe|coffee|cà\s*phê|trà\s*sữa|tea|quán|nhà\s*hàng|'
      r'restaurant|bakery|bánh|phở|bún|cơm|mì|lẩu|nướng|'
      r'highlands|phúc\s*long|kfc|lotteria|mcdonald|jollibee|'
      r'pizza|starbucks|food|drink|canteen|ăn\s*uống)',
    ).hasMatch(mLower)) {
      return ExpenseCategory.food;
    }

    // Fallback: check full text
    if (RegExp(
      r'(?:mart|coop|winmart|vinmart|circle\s*k|gs25|7-eleven|family\s*mart|'
      r'siêu\s*thị|mini\s*mart|shop|store|boutique|zara|uniqlo|shopee|lazada|tiki)',
    ).hasMatch(fullLower)) {
      return ExpenseCategory.shopping;
    }

    if (RegExp(
      r'(?:grab|be|xanh\s*sm|gojek|taxi|xăng|petrol|pvoil|'
      r'vé\s*xe|gửi\s*xe|bãi\s*đỗ|vận\s*chuyển|xe\s*buýt|bus|train|vé\s*tàu)',
    ).hasMatch(fullLower)) {
      return ExpenseCategory.transport;
    }

    if (RegExp(
      r'(?:điện|nước|internet|wifi|vnpt|viettel|fpt|tiện\s*ích|'
      r'rác|chung\s*cư|phí\s*dịch\s*vụ|tiền\s*nhà|học\s*phí|bill)',
    ).hasMatch(fullLower)) {
      return ExpenseCategory.utilities;
    }

    if (RegExp(
      r'(?:cafe|coffee|cà\s*phê|trà\s*sữa|tea|quán|nhà\s*hàng|'
      r'restaurant|bakery|bánh|phở|bún|cơm|mì|lẩu|nướng|'
      r'highlands|phúc\s*long|kfc|lotteria|mcdonald|jollibee|'
      r'pizza|starbucks|food|drink|canteen|ăn\s*uống)',
    ).hasMatch(fullLower)) {
      return ExpenseCategory.food;
    }

    return ExpenseCategory.food;
  }
}
