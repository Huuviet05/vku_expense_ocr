import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/platform/device_service.dart';
import '../../providers/expense_provider.dart';
import '../../data/models/expense_model.dart';
import '../widgets/expense_summary_card.dart';
import 'add_expense_screen.dart';

/// State provider for search query
final _searchQueryProvider = StateProvider<String>((ref) => '');

/// State provider for selected category filter (null means All)
final _selectedCategoryFilterProvider = StateProvider<ExpenseCategory?>((ref) => null);

/// Filtered expenses provider based on search and category
final filteredExpensesProvider = Provider<List<ExpenseModel>>((ref) {
  final all = ref.watch(expenseProvider).valueOrNull ?? [];
  final query = ref.watch(_searchQueryProvider).trim().toLowerCase();
  final cat = ref.watch(_selectedCategoryFilterProvider);

  return all.where((e) {
    final matchesCat = cat == null || e.category == cat;
    final matchesQuery = query.isEmpty ||
        e.merchant.toLowerCase().contains(query) ||
        (e.note != null && e.note!.toLowerCase().contains(query));
    return matchesCat && matchesQuery;
  }).toList();
});

/// Main home screen: expense list with total summary header & search
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expenseProvider);
    final monthlyTotal = ref.watch(monthlyTotalProvider);
    final filtered = ref.watch(filteredExpensesProvider);
    final selectedCategory = ref.watch(_selectedCategoryFilterProvider);
    final batteryAsync = ref.watch(batteryLevelProvider);

    return Scaffold(
      // ── AppBar ───────────────────────────────────────────────────
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Tìm theo cửa hàng hoặc ghi chú...',
                  border: InputBorder.none,
                  filled: false,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(_searchQueryProvider.notifier).state = '';
                    },
                  ),
                ),
                onChanged: (val) {
                  ref.read(_searchQueryProvider.notifier).state = val;
                },
              )
            : const Text('Sổ Chi Tiêu VKU'),
        actions: [
          // Native platform battery indicator (Week 8 Part 7)
          batteryAsync.when(
            data: (battery) => battery >= 0
                ? Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ActionChip(
                      avatar: Icon(
                        battery > 20
                            ? Icons.battery_charging_full_rounded
                            : Icons.battery_alert_rounded,
                        size: 16,
                        color: battery > 20 ? Colors.green : Colors.red,
                      ),
                      label: Text('$battery%'),
                      padding: EdgeInsets.zero,
                      onPressed: () => _showNativeInfoDialog(context),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search_rounded),
            tooltip: _isSearching ? 'Đóng tìm kiếm' : 'Tìm kiếm',
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref.read(_searchQueryProvider.notifier).state = '';
                }
              });
            },
          ),
        ],
      ),

      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (expenses) => CustomScrollView(
          slivers: [
            // ── Monthly summary header ────────────────────────────
            SliverToBoxAdapter(
              child: _MonthlySummaryBanner(
                total: monthlyTotal,
                count: expenses.length,
              ),
            ),

            // ── Category Filter Bar ───────────────────────────────
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tất cả'),
                      selected: selectedCategory == null,
                      onSelected: (_) {
                        ref.read(_selectedCategoryFilterProvider.notifier).state = null;
                      },
                    ),
                    const SizedBox(width: 8),
                    ...ExpenseCategory.values.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: Icon(cat.displayIcon, size: 14, color: cat.color),
                          label: Text(cat.label),
                          selected: isSelected,
                          onSelected: (_) {
                            ref.read(_selectedCategoryFilterProvider.notifier).state =
                                isSelected ? null : cat;
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ── Expense list ─────────────────────────────────────
            filtered.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(
                      isSearching: _isSearching || selectedCategory != null,
                    ),
                  )
                : SliverList.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final expense = filtered[i];
                      return Dismissible(
                        key: ValueKey(expense.id),
                        direction: DismissDirection.endToStart,
                        background: _DismissBackground(),
                        confirmDismiss: (_) async {
                          final messenger = ScaffoldMessenger.of(ctx);
                          ref.read(expenseProvider.notifier).deleteExpense(expense.id);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Đã xóa "${expense.merchant}"'),
                              behavior: SnackBarBehavior.floating,
                              action: SnackBarAction(
                                label: 'Hoàn tác',
                                onPressed: () {
                                  ref.read(expenseProvider.notifier).addExpense(
                                        merchant: expense.merchant,
                                        amount: expense.amount,
                                        date: expense.date,
                                        category: expense.category,
                                        note: expense.note,
                                        photoPath: expense.photoPath,
                                        rawOcrText: expense.rawOcrText,
                                      );
                                },
                              ),
                            ),
                          );
                          return false; // Handled optimistically via deleteExpense
                        },
                        child: ExpenseSummaryCard(
                          expense: expense,
                          animationDelay: Duration(milliseconds: (i % 8) * 40),
                          onTap: () => ctx.push(
                            '/expense/${expense.id}',
                            extra: expense,
                          ),
                        ),
                      );
                    },
                  ),

            // Bottom padding for FAB
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),

      // ── FAB: scan receipt & manual add ───────────────────────────
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Secondary: manual add
          FloatingActionButton.small(
            heroTag: 'manual_add',
            tooltip: 'Nhập thủ công',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => const AddExpenseScreen(),
            ),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          // Primary: OCR scan
          FloatingActionButton.extended(
            heroTag: 'scan',
            onPressed: () => context.push('/scan'),
            icon: const Icon(Icons.document_scanner_rounded),
            label: const Text('Quét Hóa Đơn OCR'),
          ),
        ],
      ),
    );
  }

  void _showNativeInfoDialog(BuildContext context) async {
    final platformName = await DevicePlatformService.instance.getDevicePlatformName();
    final battery = await DevicePlatformService.instance.getBatteryLevel();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hub_rounded, color: Colors.blueAccent),
                const SizedBox(width: 10),
                Text(
                  'Platform Channel (MethodChannel)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Kênh giao tiếp: vn.edu.vku/device_info', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Nền tảng host: $platformName'),
            const SizedBox(height: 6),
            Text('Trạng thái pin native: ${battery >= 0 ? '$battery%' : 'Không khả dụng'}'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Monthly Summary Banner ─────────────────────────────────────────
class _MonthlySummaryBanner extends StatelessWidget {
  const _MonthlySummaryBanner({required this.total, required this.count});
  final double total;
  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final monthStr = 'Tháng ${now.month}/${now.year}';
    final formatted = ExpenseCategory.formatVnd(total);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthStr,
                style: TextStyle(
                  color: cs.onPrimary.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$count giao dịch',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            formatted,
            style: TextStyle(
              color: cs.onPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tổng chi tiêu trong tháng hiện tại',
            style: TextStyle(
              color: cs.onPrimary.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.delete_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.isSearching = false});
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off_rounded : Icons.receipt_long_outlined,
              size: 68,
              color: cs.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              isSearching
                  ? 'Không tìm thấy chi tiêu phù hợp'
                  : 'Chưa có khoản chi tiêu nào',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Hãy thử thay đổi từ khóa hoặc bộ lọc danh mục'
                  : 'Chụp hoặc chọn ảnh hóa đơn bằng nút bên dưới để bắt đầu',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.outline,
                  ),
            ),
            if (!isSearching) ...[
              const SizedBox(height: 20),
              Consumer(
                builder: (context, ref, _) => FilledButton.tonalIcon(
                  onPressed: () async {
                    await ref.read(expenseProvider.notifier).resetToSamples();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Đã nạp lại 4 hóa đơn mẫu thành công!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Nạp 4 hóa đơn mẫu (Demo)'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
