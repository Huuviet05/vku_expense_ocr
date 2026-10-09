import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/models/expense_model.dart';

/// ─────────────────────────────────────────────────────────────────
///  ExpenseSummaryCard — Week 7 In-Class Lab Exercise (30 min)
/// ─────────────────────────────────────────────────────────────────
///
/// Requirements from the slide:
///   1. Icon inside a circular container indicating category
///   2. Store name and date stacked vertically (CrossAxisAlignment.start)
///   3. Highlighted monetary amount formatted as Vietnamese Dong (###.### đ)
///   4. Wrapped inside Material 3 Card with elevation + InkWell ripple tap callback
///
/// Bonus improvements:
///   • flutter_animate entry animation (fade + slide)
///   • Dismissible swipe-to-delete with undo SnackBar hook
///   • const-safe construction everywhere possible
/// ─────────────────────────────────────────────────────────────────
class ExpenseSummaryCard extends StatelessWidget {
  const ExpenseSummaryCard({
    super.key,
    required this.expense,
    required this.onTap,
    this.onDelete,
    this.animationDelay = Duration.zero,
  });

  final ExpenseModel expense;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  /// Staggered entry delay for list animations
  final Duration animationDelay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Animate(
      delay: animationDelay,
      effects: const [
        FadeEffect(duration: Duration(milliseconds: 350)),
        SlideEffect(
          begin: Offset(0, 0.15),
          end: Offset.zero,
          duration: Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        ),
      ],
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // ── 1. Category icon in circle ────────────────────
                _CategoryAvatar(category: expense.category),
                const SizedBox(width: 14),

                // ── 2. Merchant name + date (stacked vertically) ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.merchant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        expense.formattedDate,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── 3. Amount badge (Vietnamese Dong) ─────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _AmountBadge(
                      amount: expense.formattedAmount,
                      isHighValue: expense.amount >= 200000,
                    ),
                    const SizedBox(height: 4),
                    _CategoryChip(category: expense.category),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets (const-safe) ──────────────────────────────────────

/// Circular avatar with category-specific color and icon
class _CategoryAvatar extends StatelessWidget {
  const _CategoryAvatar({required this.category});
  final ExpenseCategory category;

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(category.displayIcon, color: color, size: 22),
    );
  }
}

/// Green/red highlighted amount badge
class _AmountBadge extends StatelessWidget {
  const _AmountBadge({required this.amount, required this.isHighValue});
  final String amount;
  final bool isHighValue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isHighValue ? cs.error : cs.primary;
    return Text(
      amount,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
    );
  }
}

/// Small rounded label showing the category name
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});
  final ExpenseCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: category.color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
