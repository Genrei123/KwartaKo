import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/SpendingPressureIndex/spending_pressure_index_result.dart';
import '../../../core/models/Bucket/cascade_result.dart';
import '../../../core/models/EmergencyFundErosionRate/emergency_fund_erosion_rate_result.dart';

/// Shows the Transaction Impact Analysis card before saving an expense.
/// Displays SPI gauge, BBC cascade, and EFER delay.
class TransactionImpactCard extends StatelessWidget {
  final String categoryName;
  final double amount;
  final String walletName;
  final SpiResult? spiResult;
  final CascadeResult? cascadeResult;
  final EmergencyFundErosionRateResult? eferResult;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const TransactionImpactCard({
    super.key,
    required this.categoryName,
    required this.amount,
    required this.walletName,
    this.spiResult,
    this.cascadeResult,
    this.eferResult,
    required this.onConfirm,
    required this.onCancel,
  });

  Color _spiColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'green':
        return Colors.green.shade400;
      case 'blue':
        return Colors.blue.shade400;
      case 'yellow':
        return Colors.amber.shade400;
      case 'orange':
        return Colors.orange.shade400;
      case 'red':
        return Colors.red.shade400;
      default:
        return Colors.grey;
    }
  }

  Color _cascadeColor(CascadeWarningLevel level) {
    switch (level) {
      case CascadeWarningLevel.silent:
        return Colors.green.shade400;
      case CascadeWarningLevel.yellow:
        return Colors.amber.shade400;
      case CascadeWarningLevel.orange:
        return Colors.orange.shade400;
      case CascadeWarningLevel.red:
        return Colors.red.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF1A2940),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
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
                  color: Colors.orange.shade400.withOpacity(0.15),
                ),
                child: Icon(Icons.analytics_rounded, color: Colors.orange.shade400, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$categoryName — ${formatter.format(amount)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Wallet: $walletName',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(height: 1, color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: 16),

          // SPI Section
          if (spiResult != null) ...[
            _ImpactRow(
              icon: Icons.speed_rounded,
              label: 'Spending Pressure',
              value: '${spiResult!.spiPercent.isFinite ? spiResult!.spiPercent.toStringAsFixed(0) : '∞'}%',
              color: _spiColor(spiResult!.color),
              message: spiResult!.message,
            ),
            const SizedBox(height: 12),
          ],

          // BBC Section
          if (cascadeResult != null) ...[
            _ImpactRow(
              icon: Icons.waterfall_chart_rounded,
              label: 'Bucket Impact',
              value: cascadeResult!.steps.isEmpty
                  ? 'All Buckets Exhausted'
                  : cascadeResult!.steps.map((s) => s.bucket.name).join(' → '),
              color: cascadeResult!.steps.isEmpty
                  ? Colors.red.shade400
                  : _cascadeColor(cascadeResult!.warningLevel),
              message: cascadeResult!.message,
            ),
            const SizedBox(height: 12),
          ],

          // EFER Section
          if (eferResult != null) ...[
            _ImpactRow(
              icon: Icons.shield_rounded,
              label: 'EF Impact',
              value: eferResult!.daysDelayed > 0
                  ? '+${eferResult!.daysDelayed.toStringAsFixed(0)} days delay'
                  : 'No delay',
              color: eferResult!.daysDelayed > 0 ? Colors.orange.shade400 : Colors.green.shade400,
              message: eferResult!.message,
            ),
          ],

          const SizedBox(height: 20),
          Divider(height: 1, color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white.withOpacity(0.6),
                    side: BorderSide(color: Colors.white.withOpacity(0.15)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
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
                    'Log anyway',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String message;

  const _ImpactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: color.withOpacity(0.2),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
