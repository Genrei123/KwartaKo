import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../../../infrastructure/models/db_models.dart';

/// Donut chart showing net worth distribution across wallets.
class WalletPieChart extends StatelessWidget {
  final List<DbWallet> wallets;
  final Map<String, double> balances;

  const WalletPieChart({
    super.key,
    required this.wallets,
    required this.balances,
  });

  Color _parseColor(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return Colors.green.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

    // Filter out zero/negative balance wallets
    final activeWallets = wallets.where((w) => (balances[w.id] ?? 0) > 0).toList();

    if (activeWallets.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(
          children: [
            Icon(Icons.pie_chart_outline_rounded, color: Colors.white.withOpacity(0.15), size: 48),
            const SizedBox(height: 12),
            Text(
              'Add wallets with balance to see distribution',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    double totalBalance = 0.0;
    for (final w in activeWallets) {
      totalBalance += balances[w.id] ?? 0.0;
    }

    // Build slice data
    final slices = <_SliceData>[];
    for (final w in activeWallets) {
      final bal = balances[w.id] ?? 0.0;
      slices.add(_SliceData(
        name: w.name,
        amount: bal,
        fraction: totalBalance > 0 ? bal / totalBalance : 0,
        color: _parseColor(w.color),
      ));
    }

    // Sort by fraction descending
    slices.sort((a, b) => b.fraction.compareTo(a.fraction));

    return Container(
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
              Icon(Icons.donut_large_rounded, color: Colors.green.shade400, size: 18),
              const SizedBox(width: 8),
              Text(
                'Net Worth Distribution',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Chart + center text
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: CustomPaint(
                painter: _DonutPainter(slices: slices),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatter.format(totalBalance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Total',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Legend
          ...slices.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: s.color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      formatter.format(s.amount),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: s.color.withOpacity(0.15),
                      ),
                      child: Text(
                        '${(s.fraction * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: s.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _SliceData {
  final String name;
  final double amount;
  final double fraction;
  final Color color;

  _SliceData({
    required this.name,
    required this.amount,
    required this.fraction,
    required this.color,
  });
}

class _DonutPainter extends CustomPainter {
  final List<_SliceData> slices;

  _DonutPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 24.0;
    const gapAngle = 0.04; // Small gap between slices

    double startAngle = -math.pi / 2;

    for (int i = 0; i < slices.length; i++) {
      final sweep = slices[i].fraction * 2 * math.pi - gapAngle;
      if (sweep <= 0) continue;

      final paint = Paint()
        ..color = slices[i].color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle + gapAngle / 2,
        sweep,
        false,
        paint,
      );

      startAngle += slices[i].fraction * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}
