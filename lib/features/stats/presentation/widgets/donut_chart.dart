import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../expenses/data/models/expense_model.dart';

/// ─────────────────────────────────────────────────────────────────
///  Animated Donut / Pie Chart  (CustomPainter)
///  Rubric: "Custom-drawn animated Pie/Donut category chart"
///  Week 8 Part 6: Canvas Coordinate Geometry, Arcs & Animations
/// ─────────────────────────────────────────────────────────────────
class DonutChart extends StatefulWidget {
  const DonutChart({
    super.key,
    required this.data,
    this.size = 230,
    this.onCategorySelected,
  });

  final Map<ExpenseCategory, double> data;
  final double size;
  final ValueChanged<ExpenseCategory?>? onCategorySelected;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _sweep;
  ExpenseCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _sweep = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(DonutChart old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final total = widget.data.values.fold(0.0, (s, v) => s + v);

    final displayLabel = _selectedCategory != null
        ? _selectedCategory!.label
        : 'Tổng chi tiêu';
    final displayAmount = _selectedCategory != null
        ? (widget.data[_selectedCategory!] ?? 0.0)
        : total;
    final displayColor = _selectedCategory != null
        ? _selectedCategory!.color
        : cs.primary;

    return Column(
      children: [
        AnimatedBuilder(
          animation: _sweep,
          builder: (_, __) => GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = null;
              });
              widget.onCategorySelected?.call(null);
            },
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _DonutPainter(
                data: widget.data,
                total: total,
                progress: _sweep.value,
                selectedCategory: _selectedCategory,
                backgroundColor: cs.surfaceContainerHigh.withValues(alpha: 0.3),
              ),
              child: SizedBox.square(
                dimension: widget.size,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ExpenseCategory.formatVnd(displayAmount),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: displayColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_selectedCategory != null && total > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${((displayAmount / total) * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: displayColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.data,
    required this.total,
    required this.progress,
    this.selectedCategory,
    required this.backgroundColor,
  });

  final Map<ExpenseCategory, double> data;
  final double total;
  final double progress; // 0..1 animation progress
  final ExpenseCategory? selectedCategory;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const baseStrokeWidth = 34.0;
    final rect = Rect.fromCircle(center: center, radius: radius - baseStrokeWidth / 2);

    // 1. Draw light background ring
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseStrokeWidth
      ..color = backgroundColor;
    canvas.drawArc(rect, 0, 2 * math.pi, false, bgPaint);

    // 2. Draw animated arc segments
    double startAngle = -math.pi / 2; // Start from 12 o'clock

    for (final entry in data.entries) {
      if (entry.value <= 0) continue;
      final sweepAngle = (entry.value / total) * 2 * math.pi * progress;
      final isSelected = selectedCategory == entry.key;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? baseStrokeWidth + 6 : baseStrokeWidth
        ..strokeCap = StrokeCap.round
        ..color = isSelected
            ? entry.key.color
            : (selectedCategory == null
                ? entry.key.color
                : entry.key.color.withValues(alpha: 0.35));

      // Inset slightly to make rounded caps look separated
      const gapAngle = 0.04;
      final safeSweep = math.max(0.0, sweepAngle - gapAngle);

      canvas.drawArc(rect, startAngle + gapAngle / 2, safeSweep, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress ||
      old.data != data ||
      old.selectedCategory != selectedCategory;
}

// ─────────────────────────────────────────────────────────────────
//  Legend with tap to highlight category
// ─────────────────────────────────────────────────────────────────
class DonutLegend extends StatelessWidget {
  const DonutLegend({
    super.key,
    required this.data,
    this.selectedCategory,
    this.onSelect,
  });

  final Map<ExpenseCategory, double> data;
  final ExpenseCategory? selectedCategory;
  final ValueChanged<ExpenseCategory?>? onSelect;

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold(0.0, (s, v) => s + v);
    if (total == 0) return const SizedBox.shrink();

    return Column(
      children: data.entries
          .where((e) => e.value > 0)
          .map((e) {
            final pct = (e.value / total * 100).toStringAsFixed(1);
            final isSelected = selectedCategory == e.key;

            return Material(
              color: isSelected
                  ? e.key.color.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelect?.call(isSelected ? null : e.key);
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: e.key.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        e.key.label,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isSelected ? e.key.color : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        ExpenseCategory.formatVnd(e.value),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          })
          .toList(),
    );
  }
}
