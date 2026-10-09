import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:vku_expense_ocr/features/ocr/data/receipt_parser.dart';
import 'review_receipt_screen.dart';

/// ─────────────────────────────────────────────────────────────────
///  OCR Scan Screen — Camera / Gallery Capture with ML Kit
///  Week 8: "Connecting the System Pipeline: Camera -> ML Kit OCR ->
///  ReceiptParser (Regex Engine) -> Review Screen -> Riverpod -> SQLite"
/// ─────────────────────────────────────────────────────────────────
class OcrScanScreen extends ConsumerStatefulWidget {
  const OcrScanScreen({super.key});

  @override
  ConsumerState<OcrScanScreen> createState() => _OcrScanScreenState();
}

class _OcrScanScreenState extends ConsumerState<OcrScanScreen> {
  File? _imageFile;
  bool _processing = false;

  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét hóa đơn OCR'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: _processing
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      'Đang xử lý nhận dạng văn bản (ML Kit)...',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Phân tích tổng tiền và cửa hàng theo regex',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.outline,
                          ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.document_scanner_rounded,
                        size: 56,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Chụp hoặc chọn ảnh hóa đơn',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hệ thống On-Device OCR và Heuristic Regex sẽ tự động trích xuất Tên cửa hàng, Ngày, và Tổng tiền.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 36),

                    // ── Primary Actions: Camera & Gallery ───────────────
                    Row(
                      children: [
                        Expanded(
                          child: _CaptureOptionButton(
                            icon: Icons.camera_alt_rounded,
                            label: 'Chụp ảnh',
                            subtitle: 'Dùng camera',
                            onTap: () => _pickAndProcess(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _CaptureOptionButton(
                            icon: Icons.photo_library_rounded,
                            label: 'Thư viện',
                            subtitle: 'Chọn từ máy',
                            onTap: () => _pickAndProcess(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),

                    // ── Quick Demo Presets (Guarantees testing without physical camera) ──
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '💡 Thử nghiệm nhanh hóa đơn mẫu (Demo Presets):',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _DemoReceiptCard(
                      title: 'Highlands Coffee (Hóa đơn cà phê)',
                      snippet: 'Cà phê Phin Sữa Đá • 89.000 đ',
                      icon: Icons.coffee_rounded,
                      onTap: () => _runDemoReceipt(
                        '''
HIGHLANDS COFFEE
Chi nhánh: Da Nang Riverside
HÓA ĐƠN BÁN LẺ
Ngày: 09/10/2026 14:32:10
Thu ngân: NV01
1. Cà phê phin sữa đá size L      45.000
2. Trà sen vàng size M           44.000
---------------------------------------
CỘNG TIỀN HÀNG:                  89.000
VAT (8%):                         7.120
TỔNG CỘNG THANH TOÁN:            89.000 VNĐ
TIỀN MẶT:                       100.000
TIỀN THỪA:                       11.000
Cảm ơn quý khách và hẹn gặp lại!
''',
                        'Highlands Coffee',
                      ),
                    ),
                    const SizedBox(height: 10),

                    _DemoReceiptCard(
                      title: 'WinMart+ (Hóa đơn siêu thị mini)',
                      snippet: 'Sữa tươi, Bánh mì • 145.000 đ',
                      icon: Icons.shopping_basket_rounded,
                      onTap: () => _runDemoReceipt(
                        '''
WINMART+ DA NANG
PHIẾU THANH TOÁN
ĐC: 470 Tran Dai Nghia, Ngu Hanh Son, Da Nang
MST: 0104918404
Ngày 08/10/2026  18:45
1. Sữa tươi tiệt trùng Vinamilk  38.000
2. Bánh mì sandwich mè đen       27.000
3. Táo Envy nhập khẩu           80.000
---------------------------------------
TỔNG TIỀN:                      145.000 đ
CHIẾT KHẤU:                          0 đ
THANH TOÁN:                     145.000 VNĐ
Thanh toán qua: Chuyển khoản VietQR
Xin cảm ơn Quý Khách!
''',
                        'WinMart+',
                      ),
                    ),
                    const SizedBox(height: 10),

                    _DemoReceiptCard(
                      title: 'Grab Car (Hóa đơn di chuyển)',
                      snippet: 'Chuyến xe VKU đến Cầu Rồng • 62.000 đ',
                      icon: Icons.directions_car_rounded,
                      onTap: () => _runDemoReceipt(
                        '''
GRAB VIETNAM
BIÊN NHẬN ĐIỆN TỬ
Chuyến đi: VKU -> Cầu Rồng, Đà Nẵng
Ngày: 07/10/2026
Tài xế: Nguyễn Văn A
Cước phí chuyến đi:             62.000 đ
Phí cầu đường:                       0 đ
TỔNG THANH TOÁN:                62.000 VNĐ
Phương thức: Ví MoMo
''',
                        'Grab Car',
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _pickAndProcess(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked == null) return;

      setState(() {
        _imageFile = File(picked.path);
        _processing = true;
      });

      final inputImage = InputImage.fromFile(_imageFile!);
      final recognized = await _textRecognizer.processImage(inputImage);
      final rawText = recognized.text;

      final parsed = ReceiptParser.parse(rawText, photoPath: _imageFile!.path);

      if (!mounted) return;
      setState(() => _processing = false);

      // Navigate directly to ReviewReceiptScreen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReviewReceiptScreen(initialResult: parsed),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi quét hóa đơn: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _runDemoReceipt(String sampleText, String merchantHint) {
    HapticFeedback.lightImpact();
    final parsed = ReceiptParser.parse(sampleText);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewReceiptScreen(initialResult: parsed),
      ),
    );
  }
}

// ── Capture Option Button ─────────────────────────────────────────
class _CaptureOptionButton extends StatelessWidget {
  const _CaptureOptionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 26, color: cs.onPrimaryContainer),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Demo Receipt Item Card ────────────────────────────────────────
class _DemoReceiptCard extends StatelessWidget {
  const _DemoReceiptCard({
    required this.title,
    required this.snippet,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String snippet;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: cs.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          snippet,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      ),
    );
  }
}
