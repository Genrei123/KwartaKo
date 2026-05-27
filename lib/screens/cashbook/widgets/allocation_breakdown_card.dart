import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/allocation_result.dart';

/// Shows the allocation breakdown card after logging income.
class AllocationBreakdownCard extends StatelessWidget {
  final AllocationResult result;
  final VoidCallback onDismiss;

  const AllocationBreakdownCard({
    super.key,
    required this.result,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF1A2940),
        border: Border.all(color: Colors.green.shade400.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade900.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.green.shade400.withOpacity(0.15),
                ),
                child: Icon(Icons.auto_awesome_rounded, color: Colors.green.shade400, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Income Allocated',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Zero-sum check
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: result.isBalanced
                      ? Colors.green.shade400.withOpacity(0.15)
                      : Colors.red.shade400.withOpacity(0.15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      result.isBalanced ? Icons.check_circle_rounded : Icons.warning_rounded,
                      size: 14,
                      color: result.isBalanced ? Colors.green.shade300 : Colors.red.shade300,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      result.isBalanced ? 'Balanced' : 'Drift',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: result.isBalanced ? Colors.green.shade300 : Colors.red.shade300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _AllocationRow(
            label: 'Emergency Fund',
            amount: formatter.format(result.emergencyContribution),
            color: Colors.red.shade400,
            icon: Icons.shield_rounded,
          ),
          const SizedBox(height: 8),
          _AllocationRow(
            label: 'Debt Payments',
            amount: formatter.format(result.debtDeduction),
            color: Colors.orange.shade400,
            icon: Icons.credit_card_rounded,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.white.withOpacity(0.08)),
          ),

          _AllocationRow(
            label: 'Assignable Cash',
            amount: formatter.format(result.assignableCash),
            color: Colors.white.withOpacity(0.6),
            icon: Icons.account_balance_wallet_rounded,
            isBold: true,
          ),

          const SizedBox(height: 12),

          _AllocationRow(
            label: 'Needs',
            amount: formatter.format(result.needsAllocation),
            color: Colors.blue.shade400,
            icon: Icons.home_rounded,
          ),
          const SizedBox(height: 8),
          _AllocationRow(
            label: 'Wants',
            amount: formatter.format(result.wantsAllocation),
            color: Colors.purple.shade400,
            icon: Icons.shopping_bag_rounded,
          ),
          const SizedBox(height: 8),
          _AllocationRow(
            label: 'Flex',
            amount: formatter.format(result.flexAllocation),
            color: Colors.orange.shade400,
            icon: Icons.bolt_rounded,
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDismiss,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade500,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Got it',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllocationRow extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;
  final bool isBold;

  const _AllocationRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isBold ? Colors.white : Colors.white.withOpacity(0.6),
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
