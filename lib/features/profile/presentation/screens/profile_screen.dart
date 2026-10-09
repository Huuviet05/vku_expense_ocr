import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/platform/device_service.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../expenses/providers/expense_provider.dart';

/// User & Student Profile Screen
/// Displays Student Information, Monthly Budget settings with persistent storage,
/// Native MethodChannel hardware info, and Data Management controls.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const _kMonthlyBudgetPrefKey = 'vku_monthly_budget';
  double _monthlyBudget = 3000000; // Default 3.000.000 đ
  int? _batteryLevel;
  String? _deviceModel;
  bool _loadingHardware = true;

  @override
  void initState() {
    super.initState();
    _loadSavedBudget();
    _fetchHardwareInfo();
  }

  Future<void> _loadSavedBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_kMonthlyBudgetPrefKey);
    if (saved != null && mounted) {
      setState(() => _monthlyBudget = saved);
    }
  }

  Future<void> _saveBudget(double newBudget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kMonthlyBudgetPrefKey, newBudget);
    if (mounted) {
      setState(() => _monthlyBudget = newBudget);
    }
  }

  Future<void> _fetchHardwareInfo() async {
    final battery = await DevicePlatformService.instance.getBatteryLevel();
    final platformName =
        await DevicePlatformService.instance.getDevicePlatformName();
    if (mounted) {
      setState(() {
        _batteryLevel = battery;
        _deviceModel = platformName;
        _loadingHardware = false;
      });
    }
  }

  void _showEditBudgetDialog() {
    final ctrl = TextEditingController(text: _monthlyBudget.round().toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thiết lập ngân sách tháng'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Ngân sách (VNĐ)',
            suffixText: 'đ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text);
              if (val != null && val > 0) {
                _saveBudget(val);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '✅ Đã lưu ngân sách: ${ExpenseCategory.formatVnd(val)}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final expenses = ref.watch(expenseProvider).valueOrNull ?? [];
    final monthlyTotal = ref.watch(monthlyTotalProvider);
    final budgetPercent = _monthlyBudget > 0
        ? (monthlyTotal / _monthlyBudget).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài Khoản & Thông Tin'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── 1. Student / User Profile Card ────────────────────────
          Card(
            elevation: 0,
            color: cs.primaryContainer.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: cs.primary.withValues(alpha: 0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: cs.primary,
                    child: const Text(
                      'HV',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nguyễn Hữu Việt',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mã SV: 23IT309 • Lớp: 23IT3',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Khoa Khoa học Máy tính (VKU)',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── 2. Course & Mini-Project Info ──────────────────────────
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school_rounded, color: cs.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Học phần & Đồ án',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildInfoRow('Môn học', 'Lập trình ứng dụng đa nền tảng'),
                  _buildInfoRow('Giảng viên', 'TS. Nguyễn Thanh Tuấn'),
                  _buildInfoRow('Bài tập', 'Mini-Project 3 (Week 8)'),
                  _buildInfoRow(
                      'Kiến trúc', 'Clean Architecture + Riverpod 2'),
                  _buildInfoRow('Lưu trữ', 'SQLite (Mobile) + LocalStorage (Web)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── 3. Monthly Budget Card ────────────────────────────────
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet_rounded,
                              color: cs.tertiary, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Ngân sách hàng tháng',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: _showEditBudgetDialog,
                        tooltip: 'Chỉnh sửa ngân sách',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đã chi: ${ExpenseCategory.formatVnd(monthlyTotal)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: monthlyTotal > _monthlyBudget
                              ? cs.error
                              : cs.onSurface,
                        ),
                      ),
                      Text(
                        'Hạn mức: ${ExpenseCategory.formatVnd(_monthlyBudget)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: budgetPercent,
                      minHeight: 8,
                      backgroundColor: cs.surfaceContainerHighest,
                      color: budgetPercent > 0.9 ? cs.error : cs.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Đã sử dụng ${(budgetPercent * 100).toStringAsFixed(1)}% ngân sách tháng',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── 4. Native Hardware Bridge (MethodChannel) ─────────────
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.devices_rounded,
                          color: cs.secondary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Cầu nối phần cứng Native (MethodChannel)',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildInfoRow(
                    'Pin phần cứng',
                    _loadingHardware
                        ? 'Đang đọc...'
                        : (_batteryLevel != null && _batteryLevel! >= 0
                            ? '$_batteryLevel%'
                            : 'Không khả dụng trên Web/Simulator'),
                  ),
                  _buildInfoRow(
                    'Thiết bị OS',
                    _deviceModel ?? 'Khả dụng đa nền tảng',
                  ),
                  _buildInfoRow(
                    'Kênh Native',
                    'vn.edu.vku/device_info',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── 5. Data Management (Persistence) ─────────────────────
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storage_rounded,
                          color: cs.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Quản lý dữ liệu (${expenses.length} hóa đơn đã lưu)',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.restart_alt_rounded,
                        color: Colors.blue),
                    title: const Text('Khôi phục 4 hóa đơn mẫu (Demo)'),
                    subtitle: const Text(
                        'Nạp lại hóa đơn Highlands, WinMart, Grab, EVN'),
                    onTap: () async {
                      // Trigger database refresh
                      ref.invalidate(expenseProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Đã nạp lại dữ liệu hóa đơn mẫu!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_sweep_rounded,
                        color: cs.error),
                    title: const Text('Xóa tất cả chi tiêu'),
                    subtitle:
                        const Text('Xóa toàn bộ các khoản đã lưu trên thiết bị'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Xác nhận xóa'),
                          content: const Text(
                              'Bạn có chắc chắn muốn xóa toàn bộ danh sách chi tiêu không? Thao tác này không thể hoàn tác.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Hủy'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: cs.error),
                              onPressed: () async {
                                for (final e in List.from(expenses)) {
                                  await ref
                                      .read(expenseProvider.notifier)
                                      .deleteExpense(e.id);
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Đã xóa sạch toàn bộ chi tiêu.'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Xóa tất cả'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
