import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../expenses/data/models/expense_model.dart';

/// ─────────────────────────────────────────────────────────────────
///  Animated Weekly Bar Chart  (CustomPainter)
///  Rubric: "Weekly bar chart using CustomPainter"
///  Week 8 Part 6: Canvas drawing, coordinate systems & animations
/// ─────────────────────────────────────────────────────────────────
class WeeklyBarChart extends StatefulWidget {
  const WeeklyBarChart({
    super.key,
    required this.data,
    this.height = 190,
  });

  /// List of 7 days with their spending totals
  final List<({DateTime day, double total})> data;
  final double height;

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _grow;
  int? _selectedBarIndex;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _grow = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(WeeklyBarChart old) {
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
    final cs = Theme.of(context).colorScheme;
    final max = widget.data.map((d) => d.total).fold(0.0, (a, b) => a > b ? a : b);

    final selectedItem = (_selectedBarIndex != null &&
            _selectedBarIndex! >= 0 &&
            _selectedBarIndex! < widget.data.length)
        ? widget.data[_selectedBarIndex!]
        : null;

    return Column(
      children: [
        // Selected Bar Info Tooltip
        if (selectedItem != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _tooltipDate(selectedItem.day, selectedItem.total),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onPrimaryContainer,
              ),
            ),
          )
        else
          const SizedBox(height: 24),

        // ── Custom Painted Bars ───────────────────────────────────
        AnimatedBuilder(
          animation: _grow,
          builder: (_, __) => GestureDetector(
            onTapDown: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box != null && widget.data.isNotEmpty) {
                final width = box.size.width;
                final colWidth = width / widget.data.length;
                final index = (details.localPosition.dx / colWidth).floor();
                if (index >= 0 && index < widget.data.length) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedBarIndex =
                        _selectedBarIndex == index ? null : index;
                  });
                }
              }
            },
            child: SizedBox(
              height: widget.height,
              width: double.infinity,
              child: CustomPaint(
                painter: _BarPainter(
                  data: widget.data,
                  maxValue: max == 0 ? 1 : max,
                  progress: _grow.value,
                  selectedIndex: _selectedBarIndex,
                  barColor: cs.primary,
                  todayColor: cs.tertiary,
                  highlightColor: cs.secondary,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── Day labels ─────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(widget.data.length, (i) {
            final d = widget.data[i];
            final isToday = _isToday(d.day);
            final isSelected = _selectedBarIndex == i;

            return Text(
              _dayLabel(d.day),
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                  ? cs.primary
                  : (isToday ? cs.tertiary : cs.onSurfaceVariant),
                fontWeight: (isToday || isSelected)
                  ? FontWeight.w800
                  : FontWeight.w500,
              ),
            );
          }),
        ),
      ],
    );
  }

  static const List<String> _vietnameseDays = [
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN'
  ];

  static const List<String> _vietnameseFullDays = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật'
  ];

  String _dayLabel(DateTime d) {
    final idx = d.weekday - 1;
    if (idx >= 0 && idx < _vietnameseDays.length) {
      return _vietnameseDays[idx];
    }
    return '${d.day}';
  }

  String _tooltipDate(DateTime d, double total) {
    final idx = d.weekday - 1;
    final dayName = (idx >= 0 && idx < _vietnameseFullDays.length)
        ? _vietnameseFullDays[idx]
        : '';
    final dayStr = d.day.toString().padLeft(2, '0');
    final monthStr = d.month.toString().padLeft(2, '0');
    return '$dayName, $dayStr/$monthStr: ${ExpenseCategory.formatVnd(total)}';
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.data,
    required this.maxValue,
    required this.progress,
    this.selectedIndex,
    required this.barColor,
    required this.todayColor,
    required this.highlightColor,
  });

  final List<({DateTime day, double total})> data;
  final double maxValue;
  final double progress;
  final int? selectedIndex;
  final Color barColor;
  final Color todayColor;
  final Color highlightColor;

  @override
  void paint(Canvas canvas, Size size) {
    final n = data.length;
    if (n == 0) return;

    final now = DateTime.now();
    final barWidth = size.width / n * 0.52;
    final gap = size.width / n;

    for (int i = 0; i < n; i++) {
      final item = data[i];
      final isToday = item.day.year == now.year &&
          item.day.month == now.month &&
          item.day.day == now.day;
      final isSelected = selectedIndex == i;

      final ratio = (item.total / maxValue) * progress;
      final barH = (size.height - 24) * ratio.clamp(0.0, 1.0);

      final x = gap * i + gap / 2 - barWidth / 2;
      final y = size.height - barH - 20;

      final rrect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, barH),
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
      );

      // 1. Background column track
      final bgPaint = Paint()
        ..color = barColor.withValues(alpha: isSelected ? 0.22 : 0.08);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, 0, barWidth, size.height - 20),
          topLeft: const Radius.circular(8),
          topRight: const Radius.circular(8),
        ),
        bgPaint,
      );

      // 2. Bar fill with gradient
      if (barH > 0) {
        final activeColor = isSelected
            ? highlightColor
            : (isToday ? todayColor : barColor);

        final paint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              activeColor,
              activeColor.withValues(alpha: 0.7),
            ],
          ).createShader(Rect.fromLTWH(x, y, barWidth, barH));

        canvas.drawRRect(rrect, paint);
      }

      // 3. Short value label above bar
      if (item.total > 0) {
        final label = _shortAmount(item.total);
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? highlightColor
                  : (isToday ? todayColor : barColor),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(x + barWidth / 2 - tp.width / 2, y - tp.height - 3),
        );
      }
    }
  }

  String _shortAmount(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.progress != progress ||
      old.data != data ||
      old.selectedIndex != selectedIndex;
}
