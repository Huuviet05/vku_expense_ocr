import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/features/expenses/data/models/expense_model.dart';
import 'package:vku_expense_ocr/features/ocr/data/receipt_parser.dart';

void main() {
  group('ReceiptParser Regex Heuristics Unit Tests', () {
    test('Correctly extracts total amount from Vietnamese receipt format', () {
      const sampleOcr = '''
HIGHLANDS COFFEE
HÓA ĐƠN BÁN LẺ
Ngày: 09/10/2026
1. Cà phê sữa đá       35.000
2. Trà sen vàng        45.000
-----------------------------
TỔNG CỘNG THANH TOÁN: 80.000 VNĐ
Cảm ơn quý khách!
''';

      final result = ReceiptParser.parse(sampleOcr);

      expect(result.merchant, 'HIGHLANDS COFFEE');
      expect(result.amount, 80000.0);
      expect(result.category, ExpenseCategory.food);
      expect(result.date?.day, 9);
      expect(result.date?.month, 10);
      expect(result.date?.year, 2026);
    });

    test('Correctly classifies shopping and extracts multi-line amounts', () {
      const sampleOcr = '''
WINMART+
Địa chỉ: 470 Tran Dai Nghia
Ngày 05/10/2026
Sữa tươi tiệt trùng   32.000
Bánh mì               15.000
THANH TOÁN:
47.000 đ
''';

      final result = ReceiptParser.parse(sampleOcr);

      expect(result.merchant, 'WINMART+');
      expect(result.amount, 47000.0);
      expect(result.category, ExpenseCategory.shopping);
    });

    test('Correctly parses Grab transport receipt', () {
      const sampleOcr = '''
GRAB VIETNAM
Chuyến đi: VKU đến Cầu Rồng
Ngày: 01/10/2026
Cước phí: 55.000 đ
TỔNG TIỀN: 55.000 đ
''';

      final result = ReceiptParser.parse(sampleOcr);

      expect(result.merchant, 'GRAB VIETNAM');
      expect(result.amount, 55000.0);
      expect(result.category, ExpenseCategory.transport);
    });
  });
}
