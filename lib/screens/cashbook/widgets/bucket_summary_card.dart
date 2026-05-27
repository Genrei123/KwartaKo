import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../features/cashbook/cashbook_service.dart';

class BucketSummaryCard extends StatelessWidget {
  final BucketSummary summary;
  final VoidCallback? onTap;

  const BucketSummaryCard({
    super.key,
    required this.summary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart_rounded, color: Colors.green.shade400, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Monthly Budget',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '${formatter.format(summary.totalSpent)} / ${formatter.format(summary.totalAllocated)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _BucketBar(
              label: 'Needs',
              spent: summary.needsSpent,
              allocated: summary.needsAllocated,
              color: Colors.blue.shade400,
              icon: Icons.home_rounded,
            ),
            const SizedBox(height: 14),
            _BucketBar(
              label: 'Wants',
              spent: summary.wantsSpent,
              allocated: summary.wantsAllocated,
              color: Colors.purple.shade400,
              icon: Icons.shopping_bag_rounded,
            ),
            const SizedBox(height: 14),
            _BucketBar(
              label: 'Flex',
              spent: summary.flexSpent,
              allocated: summary.flexAllocated,
              color: Colors.orange.shade400,
              icon: Icons.bolt_rounded,
            ),
            const SizedBox(height: 14),
            _BucketBar(
              label: 'Emergency',
              spent: summary.emergencySpent,
              allocated: summary.emergencyAllocated,
              color: Colors.red.shade400,
              icon: Icons.shield_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _BucketBar extends StatelessWidget {
  final String label;
  final double spent;
  final double allocated;
  final Color color;
  final IconData icon;

  const _BucketBar({
    required this.label,
    required this.spent,
    required this.allocated,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 0);
    final progress = allocated > 0 ? (spent / allocated).clamp(0.0, 1.5) : 0.0;
    final isOver = spent > allocated && allocated > 0;
    final remaining = allocated - spent;

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              isOver
                  ? '${formatter.format(spent)} (over by ${formatter.format(-remaining)})'
                  : '${formatter.format(spent)} / ${formatter.format(allocated)}',
              style: TextStyle(
                color: isOver ? Colors.red.shade300 : Colors.white.withOpacity(0.45),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                // Background
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Progress
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => FractionallySizedBox(
                      widthFactor: value > 0 ? 1.0 : 0.0,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            colors: isOver
                                ? [Colors.red.shade400, Colors.red.shade600]
                                : [color, color.withOpacity(0.7)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
