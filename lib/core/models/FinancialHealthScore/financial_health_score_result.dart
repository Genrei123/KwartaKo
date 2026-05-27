import 'package:kwartako/core/enums/financial_health_grade.dart';

class HealthScoreResult {
  final double dtiScore;
  final double efScore;
  final double savingsScore;
  final double cashFlowScore;
  final double total;
  final HealthGrade grade;
  final String weakestPoint;
  final String advice;

  const HealthScoreResult({
    required this.dtiScore,
    required this.efScore,
    required this.savingsScore,
    required this.cashFlowScore,
    required this.total,
    required this.grade,
    required this.weakestPoint,
    required this.advice,
  });

  String get gradeLabel => switch (grade) {
    HealthGrade.a      => 'A',
    HealthGrade.b      => 'B',
    HealthGrade.c      => 'C',
    HealthGrade.atRisk => 'At Risk',
  };

  @override
  String toString() => '''
HealthScoreResult:
  DTI score      : ${dtiScore.toStringAsFixed(2)} / 25
  EF score       : ${efScore.toStringAsFixed(2)} / 25
  Savings score  : ${savingsScore.toStringAsFixed(2)} / 25
  Cash flow score: ${cashFlowScore.toStringAsFixed(2)} / 25
  ─────────────────────────────────
  Total          : ${total.toStringAsFixed(2)} / 100  →  Grade: $gradeLabel
  Weakest point  : $weakestPoint
  Advice         : $advice
''';
}