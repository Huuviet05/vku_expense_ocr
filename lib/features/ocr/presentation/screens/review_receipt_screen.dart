import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../expenses/data/models/expense_model.dart';
import '../../../expenses/providers/expense_provider.dart';
import 'package:vku_expense_ocr/features/ocr/data/receipt_parser.dart';

/// ─────────────────────────────────────────────────────────────────
///  ReviewReceiptScreen — Week 8 Mandated Review & Verification Screen
///  Rubric: "Review & Verification Screen where students can manually
///  inspect bounding values, correct OCR mistakes before committing
///  records to SQLite."
/// ─────────────────────────────────────────────────────────────────
class ReviewReceiptScreen extends ConsumerStatefulWidget {
  const ReviewReceiptScreen({
    super.key,
    required this.initialResult,
  });

  final ParsedReceiptResult initialResult;

  @override
  ConsumerState<ReviewReceiptScreen> createState() => _ReviewReceiptScreenState();
}

class _ReviewReceiptScreenState extends ConsumerState<ReviewReceiptScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _merchantCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;

  late ExpenseCategory _category;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final res = widget.initialResult;
    _merchantCtrl = TextEditingController(text: res.merchant);
    _amountCtrl = TextEditingController(
      text: res.amount > 0 ? res.amount.toStringAsFixed(0) : '',
    );
    _noteCtrl = TextEditingController();
    _category = res.category;
    _date = res.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _merchantCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final photoPath = widget.initialResult.photoPath;
    final candidateAmounts = widget.initialResult.candidateAmounts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận & Kiểm tra OCR'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _saveExpense,
            icon: const Icon(Icons.check),
            label: const Text('Lưu'),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Receipt Image Card with Zoom Preview ─────────────
                if (photoPath != null && File(photoPath).existsSync())
                  _ReceiptPhotoCard(photoPath: photoPath),

                const SizedBox(height: 16),

                // ── 2. OCR Detection Summary Badge ──────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: cs.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ML Kit đã trích xuất các trường thông tin. Vui lòng kiểm tra và chỉnh sửa nếu cần.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── 3. Merchant Name Field ──────────────────────────────
                TextFormField(
                  controller: _merchantCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cửa hàng / Người bán *',
                    hintText: 'VD: Highlands Coffee, WinMart...',
                    prefixIcon: Icon(Icons.storefront_rounded),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập tên cửa hàng';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ── 4. Amount Field & Candidate Chips ───────────────────
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tổng tiền thanh toán (VNĐ) *',
                    hintText: 'VD: 45000',
                    prefixIcon: Icon(Icons.payments_rounded),
                    suffixText: 'VNĐ',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập số tiền';
                    }
                    final clean = val.replaceAll(RegExp(r'[^\d]'), '');
                    final num = double.tryParse(clean);
                    if (num == null || num <= 0) {
                      return 'Số tiền phải lớn hơn 0';
                    }
                    return null;
                  },
                ),

                // Quick candidate amounts from OCR detection
                if (candidateAmounts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Số tiền tìm thấy trên hóa đơn (chạm để chọn):',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: candidateAmounts.take(5).map((amount) {
                      final formatted = ExpenseCategory.formatVnd(amount);
                      final isSelected =
                          _amountCtrl.text == amount.toStringAsFixed(0);
                      return ActionChip(
                        avatar: isSelected
                            ? const Icon(Icons.check, size: 14)
                            : null,
                        label: Text(formatted),
                        backgroundColor: isSelected
                            ? cs.primaryContainer
                            : cs.surfaceContainerHigh,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? cs.primary : cs.onSurface,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _amountCtrl.text = amount.toStringAsFixed(0);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 16),

                // ── 5. Date Picker Field ────────────────────────────────
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: cs.outlineVariant),
                  ),
                  leading: Icon(Icons.event_rounded, color: cs.primary),
                  title: const Text('Ngày lập hóa đơn'),
                  subtitle: Text(
                    '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                    style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
                  ),
                  trailing: Icon(Icons.edit_calendar_rounded, color: cs.primary),
                  onTap: _pickDate,
                ),

                const SizedBox(height: 20),

                // ── 6. Category Selection Chips ─────────────────────────
                Text(
                  'Danh mục chi tiêu',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ExpenseCategory.values.map((cat) {
                    final selected = _category == cat;
                    return FilterChip(
                      selected: selected,
                      avatar: Icon(
                        cat.displayIcon,
                        size: 16,
                        color: selected ? Colors.white : cat.color,
                      ),
                      label: Text(cat.label),
                      selectedColor: cat.color,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : cs.onSurface,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _category = cat);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // ── 7. Note Field ───────────────────────────────────────
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú thêm (tùy chọn)',
                    hintText: 'VD: Ăn trưa cùng nhóm đồ án...',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),

                const SizedBox(height: 20),

                // ── 8. Raw OCR Inspector Accordion ─────────────────────
                Card(
                  elevation: 0,
                  color: cs.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: ExpansionTile(
                    leading: const Icon(Icons.code_rounded),
                    title: const Text(
                      'Xem văn bản OCR gốc',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Toàn bộ ${widget.initialResult.rawText.split('\n').length} dòng được nhận dạng',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SelectableText(
                            widget.initialResult.rawText.isNotEmpty
                                ? widget.initialResult.rawText
                                : '(Không có văn bản)',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── 9. Submit Button ────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _saveExpense,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_rounded),
                    label: Text(
                      _saving ? 'Đang lưu vào cơ sở dữ liệu...' : 'Xác nhận & Lưu chi tiêu',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    final cleanAmountStr = _amountCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
    final amount = double.parse(cleanAmountStr);
    final merchant = _merchantCtrl.text.trim();
    final note = _noteCtrl.text.trim();

    try {
      await ref.read(expenseProvider.notifier).addExpense(
            merchant: merchant,
            amount: amount,
            date: _date,
            category: _category,
            note: note.isNotEmpty ? note : null,
            photoPath: widget.initialResult.photoPath,
            rawOcrText: widget.initialResult.rawText,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã lưu khoản chi tiêu "$merchant" (${ExpenseCategory.formatVnd(amount)})'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Navigate back to Home screen where the list and charts automatically rebuild!
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lưu: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

// ── Photo Thumbnail Card with Tap-to-Zoom ─────────────────────────
class _ReceiptPhotoCard extends StatelessWidget {
  const _ReceiptPhotoCard({required this.photoPath});
  final String photoPath;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: () => _showFullImageDialog(context, photoPath),
        child: SizedBox(
          height: 160,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(photoPath),
                fit: BoxFit.cover,
              ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 14,
                right: 14,
                child: Row(
                  children: [
                    const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Ảnh hóa đơn gốc (chạm để phóng to)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'OCR OK',
                        style: TextStyle(
                          color: Colors.lightGreenAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullImageDialog(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              clipBehavior: Clip.none,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(File(path)),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton.filled(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
