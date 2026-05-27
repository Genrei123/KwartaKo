import 'package:flutter/material.dart';
import '../../../core/models/FinancialHealthScore/financial_health_score_result.dart';
import '../../../core/enums/financial_health_grade.dart';

class HealthScoreGauge extends StatelessWidget {
  final HealthScoreResult result;

  const HealthScoreGauge({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gradeColor = _getGradeColor(result.grade);
    final scorePercent = (result.total / 100.0).clamp(0.0, 1.0);

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
        children: [
          Text(
            'FINANCIAL HEALTH SCORE',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          // Circular gauge
          Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gradeColor.withOpacity(0.12),
                      blurRadius: 36,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              // Background track
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 10,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.04)),
                ),
              ),
              // Foreground progress
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: scorePercent,
                  strokeWidth: 10,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
                ),
              ),
              // Center Label
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    result.gradeLabel,
                    style: TextStyle(
                      color: gradeColor,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    '${result.total.toStringAsFixed(0)} / 100',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Weakest point badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: gradeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: gradeColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: gradeColor,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'Weakest area: ${_formatWeakestPoint(result.weakestPoint)}',
                  style: TextStyle(
                    color: gradeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Dynamic Advice
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.04),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Colors.amber.shade400,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.advice,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(HealthGrade grade) {
    return switch (grade) {
      HealthGrade.a => Colors.green.shade400,
      HealthGrade.b => Colors.teal.shade300,
      HealthGrade.c => Colors.orange.shade400,
      HealthGrade.atRisk => Colors.red.shade400,
    };
  }

  String _formatWeakestPoint(String key) {
    return switch (key) {
      'dti' => 'Debt-to-Income (DTI) Ratio',
      'ef' => 'Emergency Fund Coverage',
      'savings' => 'Savings Rate',
      'cf' => 'Monthly Cash Flow',
      _ => key.toUpperCase(),
    };
  }
}
