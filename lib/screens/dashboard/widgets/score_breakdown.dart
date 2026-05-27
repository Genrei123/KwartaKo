import 'package:flutter/material.dart';
import '../../../core/models/FinancialHealthScore/financial_health_score_result.dart';

class ScoreBreakdown extends StatelessWidget {
  final HealthScoreResult result;

  const ScoreBreakdown({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SCORE BREAKDOWN',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          _ScoreRow(
            label: 'Debt-to-Income Ratio',
            score: result.dtiScore,
            color: Colors.blue.shade400,
            icon: Icons.receipt_long_rounded,
          ),
          const SizedBox(height: 16),
          _ScoreRow(
            label: 'Emergency Fund',
            score: result.efScore,
            color: Colors.red.shade400,
            icon: Icons.shield_rounded,
          ),
          const SizedBox(height: 16),
          _ScoreRow(
            label: 'Savings Rate',
            score: result.savingsScore,
            color: Colors.purple.shade400,
            icon: Icons.savings_rounded,
          ),
          const SizedBox(height: 16),
          _ScoreRow(
            label: 'Net Cash Flow',
            score: result.cashFlowScore,
            color: Colors.green.shade400,
            icon: Icons.compare_arrows_rounded,
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final double score;
  final Color color;
  final IconData icon;

  const _ScoreRow({
    required this.label,
    required this.score,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final double maxScore = 25.0;
    final percent = (score / maxScore).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color.withOpacity(0.8), size: 16),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              '${score.toStringAsFixed(1)} / $maxScore',
              style: TextStyle(
                color: score > 15 ? Colors.white : Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: 6,
              width: percent * (MediaQuery.of(context).size.width - 80),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.6), color],
                ),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
