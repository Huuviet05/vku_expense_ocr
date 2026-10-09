import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../expenses/providers/expense_provider.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../widgets/donut_chart.dart';
import '../widgets/weekly_bar_chart.dart';

/// Statistics screen — 2 CustomPainter charts + summary metrics
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  ExpenseCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final categoryTotals = ref.watch(categoryTotalsProvider);
    final weeklyData = ref.watch(weeklyDailyTotalsProvider);
    final monthlyTotal = ref.watch(monthlyTotalProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Calculate top category
    ExpenseCategory? topCategory;
    double topCategoryAmount = 0;
    categoryTotals.forEach((cat, amt) {
      if (amt > topCategoryAmount) {
        topCategoryAmount = amt;
        topCategory = cat;
      }
    });

    // Calculate weekly average
    final weeklySum = weeklyData.fold(0.0, (s, d) => s + d.total);
    final dailyAvg = weeklySum / 7;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống Kê Chi Tiêu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Quick Summary Metric Cards ────────────────────────
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.calendar_month_rounded,
                    iconColor: cs.primary,
                    title: 'Tháng này',
                    value: ExpenseCategory.formatVnd(monthlyTotal),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.trending_up_rounded,
                    iconColor: cs.tertiary,
                    title: 'TB / ngày (7d)',
                    value: ExpenseCategory.formatVnd(dailyAvg),
                  ),
                ),
              ],
            ),
            if (topCategory != null) ...[
              const SizedBox(height: 12),
              _MetricCard(
                icon: topCategory!.displayIcon,
                iconColor: topCategory!.color,
                title: 'Chi nhiều nhất',
                value: '${topCategory!.label} (${ExpenseCategory.formatVnd(topCategoryAmount)})',
                isWide: true,
              ),
            ],
            const SizedBox(height: 20),

            // ── Weekly bar chart section ──────────────────────────
            _SectionCard(
              title: 'Biểu đồ chi tiêu 7 ngày gần nhất',
              subtitle: 'Vẽ bằng CustomPainter với hoạt ảnh tăng trưởng',
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: WeeklyBarChart(data: weeklyData),
              ),
            ),
            const SizedBox(height: 18),

            // ── Donut chart + legend section ──────────────────────
            _SectionCard(
              title: 'Phân bổ theo danh mục',
              subtitle: 'Biểu đồ tròn Animated Donut Chart (chạm để chọn)',
              child: categoryTotals.isEmpty ||
                      categoryTotals.values.every((v) => v == 0)
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('Chưa có dữ liệu chi tiêu để hiển thị biểu đồ'),
                      ),
                    )
                  : Column(
                      children: [
                        const SizedBox(height: 12),
                        Center(
                          child: DonutChart(
                            data: categoryTotals,
                            onCategorySelected: (cat) {
                              setState(() => _selectedCategory = cat);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        DonutLegend(
                          data: categoryTotals,
                          selectedCategory: _selectedCategory,
                          onSelect: (cat) {
                            setState(() => _selectedCategory = cat);
                          },
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 18),

            // ── Per-category breakdown ────────────────────────────
            if (categoryTotals.isNotEmpty &&
                categoryTotals.values.any((v) => v > 0)) ...[
              Text(
                'Chi tiết từng hạng mục',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...categoryTotals.entries.where((e) => e.value > 0).map((e) => _CategoryBar(
                    category: e.key,
                    amount: e.value,
                    maxAmount: categoryTotals.values
                        .fold(0.0, (a, b) => a > b ? a : b),
                  )),
            ],

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// ── Metric Card ───────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.isWide = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isWide ? 14 : 15,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Category progress bar ─────────────────────────────────────────
class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.category,
    required this.amount,
    required this.maxAmount,
  });

  final ExpenseCategory category;
  final double amount;
  final double maxAmount;

  @override
  Widget build(BuildContext context) {
    final ratio = maxAmount > 0 ? (amount / maxAmount).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(category.displayIcon, size: 16, color: category.color),
              const SizedBox(width: 8),
              Text(
                category.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                ExpenseCategory.formatVnd(amount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: category.color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(category.color),
            ),
          ),
        ],
      ),
    );
  }
}
