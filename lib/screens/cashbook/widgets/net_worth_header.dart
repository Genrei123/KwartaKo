import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NetWorthHeader extends StatelessWidget {
  final double netWorth;
  final double monthlyChange;
  final VoidCallback? onTap;

  const NetWorthHeader({
    super.key,
    required this.netWorth,
    this.monthlyChange = 0.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final isPositiveChange = monthlyChange >= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
            Colors.green.shade700.withOpacity(0.4),
            const Color(0xFF1A2940).withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.green.shade400.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade900.withOpacity(0.25),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.shade400.withOpacity(0.15),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.green.shade300,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Net Worth',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: netWorth),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text(
              formatter.format(value),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (monthlyChange != 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isPositiveChange
                    ? Colors.green.shade400.withOpacity(0.15)
                    : Colors.red.shade400.withOpacity(0.15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositiveChange
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 14,
                    color: isPositiveChange
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isPositiveChange ? '+' : ''}${formatter.format(monthlyChange)} this month',
                    style: TextStyle(
                      color: isPositiveChange
                          ? Colors.green.shade300
                          : Colors.red.shade300,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
}
