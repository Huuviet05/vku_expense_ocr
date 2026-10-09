import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/expense_model.dart';
import '../../providers/expense_provider.dart';

/// Modal bottom sheet for manually adding an expense with optional photo
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({
    super.key,
    this.initialMerchant,
    this.initialAmount,
    this.initialDate,
    this.initialPhotoPath,
  });

  final String? initialMerchant;
  final double? initialAmount;
  final DateTime? initialDate;
  final String? initialPhotoPath;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _merchantCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;

  ExpenseCategory _category = ExpenseCategory.food;
  DateTime _date = DateTime.now();
  String? _photoPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _merchantCtrl = TextEditingController(text: widget.initialMerchant ?? '');
    _amountCtrl = TextEditingController(
      text: widget.initialAmount != null && widget.initialAmount! > 0
          ? widget.initialAmount!.toStringAsFixed(0)
          : '',
    );
    _noteCtrl = TextEditingController();
    _date = widget.initialDate ?? DateTime.now();
    _photoPath = widget.initialPhotoPath;
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

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Thêm khoản chi tiêu mới',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Merchant
              TextFormField(
                controller: _merchantCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên cửa hàng / Dịch vụ *',
                  hintText: 'VD: Canteen VKU, Cà phê...',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Vui lòng nhập tên cửa hàng' : null,
              ),
              const SizedBox(height: 14),

              // Amount
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền chi tiêu (VNĐ) *',
                  hintText: 'VD: 35000',
                  prefixIcon: Icon(Icons.payments_outlined),
                  suffixText: 'VNĐ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số tiền';
                  final clean = v.replaceAll(RegExp(r'[^\d]'), '');
                  final val = double.tryParse(clean);
                  if (val == null || val <= 0) return 'Số tiền phải lớn hơn 0';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Date picker
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Ngày chi tiêu'),
                subtitle: Text(
                  '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),

              // Category ChoiceChips
              Text(
                'Danh mục',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExpenseCategory.values.map((cat) {
                  final isSelected = _category == cat;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat.displayIcon,
                          size: 16,
                          color: isSelected ? Colors.white : cat.color,
                        ),
                        const SizedBox(width: 6),
                        Text(cat.label),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: cat.color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : cs.onSurface,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _category = cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Photo attachment section
              if (_photoPath != null && File(_photoPath!).existsSync()) ...[
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_photoPath!),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Đã đính kèm ảnh hóa đơn',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => setState(() => _photoPath = null),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _attachPhoto,
                  icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                  label: const Text('Đính kèm ảnh hóa đơn (tùy chọn)'),
                ),
                const SizedBox(height: 14),
              ],

              // Note
              TextFormField(
                controller: _noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Lưu chi tiêu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
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
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _attachPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _photoPath = picked.path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    final rawAmount = _amountCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
    final amount = double.parse(rawAmount);

    await ref.read(expenseProvider.notifier).addExpense(
          merchant: _merchantCtrl.text.trim(),
          amount: amount,
          date: _date,
          category: _category,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          photoPath: _photoPath,
        );

    if (mounted) Navigator.of(context).pop();
  }
}
