import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/expense_model.dart';
import '../../providers/expense_provider.dart';

/// Expense detail view with photo viewer and reactive edit dialog
class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({super.key, required this.expense});
  final ExpenseModel expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Reactively watch for edits from expenseProvider
    final expenses = ref.watch(expenseProvider).valueOrNull ?? [];
    final current = expenses.firstWhere(
      (e) => e.id == expense.id,
      orElse: () => expense,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết khoản chi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Chỉnh sửa',
            onPressed: () => _showEditDialog(context, ref, current),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: cs.error),
            tooltip: 'Xóa',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Xác nhận xóa'),
                  content: Text('Xóa khoản chi tiêu "${current.merchant}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Hủy'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: cs.error),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await ref.read(expenseProvider.notifier).deleteExpense(current.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Amount & Category Highlight Card ───────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: current.category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: current.category.color.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: current.category.color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      current.category.displayIcon,
                      color: current.category.color,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    current.formattedAmount,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: current.category.color,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: current.category.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      current.category.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: current.category.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Information Details ───────────────────────────────
            _DetailCard(
              children: [
                _DetailRow(
                  icon: Icons.storefront_outlined,
                  label: 'Cửa hàng / Đối tác',
                  value: current.merchant,
                ),
                const Divider(height: 16),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Ngày chi tiêu',
                  value: current.formattedDate,
                ),
                if (current.note != null && current.note!.isNotEmpty) ...[
                  const Divider(height: 16),
                  _DetailRow(
                    icon: Icons.notes_outlined,
                    label: 'Ghi chú',
                    value: current.note!,
                  ),
                ],
              ],
            ),

            // ── Receipt Photo (Rubric: Receipt photo storage) ──────
            if (current.photoPath != null && File(current.photoPath!).existsSync()) ...[
              const SizedBox(height: 20),
              Text(
                'Ảnh hóa đơn lưu trữ',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Card(
                clipBehavior: Clip.antiAlias,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: InkWell(
                  onTap: () => _showFullImage(context, current.photoPath!),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Image.file(
                        File(current.photoPath!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        color: Colors.black.withValues(alpha: 0.5),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.zoom_in, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Nhấn để xem ảnh phóng to',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ── Raw OCR Text ──────────────────────────────────────
            if (current.rawOcrText != null && current.rawOcrText!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                color: cs.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: ExpansionTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Văn bản OCR gốc từ hóa đơn', style: TextStyle(fontSize: 14)),
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
                          current.rawOcrText!,
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
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String path) {
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
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, ExpenseModel expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditExpenseSheet(expense: expense),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 22, color: cs.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditExpenseSheet extends ConsumerStatefulWidget {
  const _EditExpenseSheet({required this.expense});
  final ExpenseModel expense;

  @override
  ConsumerState<_EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends ConsumerState<_EditExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _merchantCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late ExpenseCategory _category;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _merchantCtrl = TextEditingController(text: widget.expense.merchant);
    _amountCtrl = TextEditingController(text: widget.expense.amount.toStringAsFixed(0));
    _noteCtrl = TextEditingController(text: widget.expense.note ?? '');
    _category = widget.expense.category;
    _date = widget.expense.date;
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
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Chỉnh sửa khoản chi', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              TextFormField(
                controller: _merchantCtrl,
                decoration: const InputDecoration(labelText: 'Cửa hàng / Đối tác'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số tiền (VNĐ)'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số tiền';
                  final clean = v.replaceAll(RegExp(r'[^\d]'), '');
                  if (double.tryParse(clean) == null) return 'Số tiền không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(DateFormat('dd/MM/yyyy', 'vi_VN').format(_date)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 16),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExpenseCategory.values.map((cat) {
                  final selected = _category == cat;
                  return ChoiceChip(
                    label: Text(cat.label),
                    selected: selected,
                    selectedColor: cat.color,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : cs.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    onSelected: (_) => setState(() => _category = cat),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    final cleanAmount = _amountCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
                    final updated = widget.expense.copyWith(
                      merchant: _merchantCtrl.text.trim(),
                      amount: double.parse(cleanAmount),
                      category: _category,
                      date: _date,
                      note: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
                    );
                    await ref.read(expenseProvider.notifier).updateExpense(updated);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Lưu thay đổi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
