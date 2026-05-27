import 'package:kwartako/core/common/util.dart';
import 'package:kwartako/core/enums/financial_health_grade.dart';
import 'package:kwartako/core/models/FinancialHealthScore/financial_health_score_context.dart';
import 'package:kwartako/core/models/FinancialHealthScore/financial_health_score_result.dart';

class HealthScoreEngine {
  const HealthScoreEngine();

  HealthScoreResult calculate(HealthScoreContext context) {
    context.validate();

    final dti     = _dtiScore(context);
    final ef      = _efScore(context);
    final savings = _savingsScore(context);
    final cf      = _cashFlowScore(context);
    final total   = dti + ef + savings + cf;
    final grade   = _grade(total);

    // Find the weakest component
    final scores  = { 'dti': dti, 'ef': ef, 'savings': savings, 'cf': cf };
    final weakest = scores.entries.reduce((a, b) => a.value < b.value ? a : b);

    return HealthScoreResult(
      dtiScore: dti,
      efScore: ef,
      savingsScore: savings,
      cashFlowScore: cf,
      total: total,
      grade: grade,
      weakestPoint: weakest.key,
      advice: _advice(weakest.key, context),
    );
  }

  // ── Component scores ────────────────────────────────────────────────────────

  double _dtiScore(HealthScoreContext c) {
    final dti = c.monthlyDebtPayments / c.monthlyIncome;
    final raw = KwartaKoConstants.healthMaxPerComponent * (1 - dti);
    return raw.clamp(0, KwartaKoConstants.healthMaxPerComponent);
  }

  double _efScore(HealthScoreContext c) {
    return (c.emergencyFunds * KwartaKoConstants.healthEfMultiplier)
        .clamp(0, KwartaKoConstants.healthMaxPerComponent);
  }

  double _savingsScore(HealthScoreContext c) {
    final rate = c.monthlySaved / c.monthlyIncome;
    final baseScore = (rate * KwartaKoConstants.healthSavingsMultiplier)
        .clamp(0, KwartaKoConstants.healthMaxPerComponent);
    
    // Scale savings score by actual liquidity relative to monthly income.
    // If they have extremely low cash assets, penalize the savings grade.
    final liquidityScale = (c.netWorth / c.monthlyIncome).clamp(0.0, 1.0);
    return baseScore * (0.2 + 0.8 * liquidityScale);
  }

  double _cashFlowScore(HealthScoreContext c) {
    if (c.cashFlow <= 0) return 0.0;
    
    // Gradient cash flow score based on profit margin (reaches max at 20% margin)
    final cashFlowMargin = c.cashFlow / c.monthlyIncome;
    final baseScore = (KwartaKoConstants.healthMaxPerComponent * (cashFlowMargin / 0.20))
        .clamp(0.0, KwartaKoConstants.healthMaxPerComponent);
        
    // Scale by actual liquidity to avoid artificial high score when no transactions have been logged.
    final liquidityScale = (c.netWorth / c.monthlyIncome).clamp(0.0, 1.0);
    return baseScore * (0.1 + 0.9 * liquidityScale);
  }

  // ── Grade ───────────────────────────────────────────────────────────────────

  HealthGrade _grade(double total) {
    if (total >= 90) return HealthGrade.a;
    if (total >= 75) return HealthGrade.b;
    if (total >= 60) return HealthGrade.c;
    return HealthGrade.atRisk;
  }

  // ── Advice — grounded in Genrey's actual situation ─────────────────────────
  String _advice(String weakestKey, HealthScoreContext c) => switch (weakestKey) {
    'dti' => 'Your debt load is high relative to your income. '
        'Focus on clearing existing installments before taking new ones.',
    'ef'  => 'Build your emergency fund first. '
        'Even ₱500/month helps. Target ₱15,000 as your first milestone.',
    'savings' => 'You are not saving yet. '
        'Once your debt clears, redirect that payment into savings immediately.',
    'cf'  => 'You are spending more than you earn this month. '
        'Review your variable expenses — office days and wants are your biggest levers.',
    _     => 'Keep monitoring your spending month over month.',
  };
}