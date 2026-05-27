import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../infrastructure/models/db_models.dart';

class WalletCard extends StatelessWidget {
  final DbWallet wallet;
  final double balance;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const WalletCard({
    super.key,
    required this.wallet,
    required this.balance,
    required this.onTap,
    this.onLongPress,
  });

  Color _parseColor(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return Colors.green.shade400;
    }
  }

  IconData _walletIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('gcash') || lower.contains('maya')) return Icons.phone_android_rounded;
    if (lower.contains('bdo') || lower.contains('bpi') || lower.contains('east') || lower.contains('bank')) {
      return Icons.account_balance_rounded;
    }
    if (lower.contains('cash')) return Icons.payments_rounded;
    if (lower.contains('sav')) return Icons.savings_rounded;
    return Icons.wallet_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final color = _parseColor(wallet.color);
    final isNegative = balance < 0;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.25),
              color.withOpacity(0.08),
              const Color(0xFF1A2940).withOpacity(0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.4, 1.0],
          ),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top row: icon + name
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: color.withOpacity(0.2),
                  ),
                  child: Icon(
                    _walletIcon(wallet.name),
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    wallet.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.25),
                  size: 20,
                ),
              ],
            ),

            const Spacer(),

            // Balance
            Text(
              formatter.format(balance),
              style: TextStyle(
                color: isNegative ? Colors.red.shade300 : Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 6),

            // Label
            Text(
              'Available Balance',
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
