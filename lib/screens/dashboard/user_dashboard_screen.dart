import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard/dashboard_providers.dart';
import 'widgets/health_score_gauge.dart';
import 'widgets/score_breakdown.dart';
import 'widgets/ef_progress_ring.dart';
import 'widgets/income_expense_chart.dart';
import 'widgets/savings_trend_chart.dart';
import 'widgets/debt_list.dart';
import 'widgets/savings_goals_list.dart';

class UserDashboardScreen extends ConsumerWidget {
  const UserDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthScoreAsync = ref.watch(financialHealthScoreProvider);
    final efProgressAsync = ref.watch(emergencyFundProgressProvider);
    final historyAsync = ref.watch(monthlyMetricsHistoryProvider);
    final debtsAsync = ref.watch(dashboardActiveDebtsProvider);
    final goalsAsync = ref.watch(dashboardSavingsGoalsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1B2D),
      appBar: AppBar(
        title: const Text(
          'Financial Analytics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: const Color(0xFF0F1B2D),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withOpacity(0.06),
            height: 1,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          invalidateDashboardProviders(ref);
        },
        color: Colors.green.shade400,
        backgroundColor: const Color(0xFF1E2D4A),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Health Score Section
              healthScoreAsync.when(
                data: (result) {
                  if (result == null) {
                    return _buildSetupPrompt(context);
                  }
                  return Column(
                    children: [
                      HealthScoreGauge(result: result),
                      const SizedBox(height: 16),
                      ScoreBreakdown(result: result),
                    ],
                  );
                },
                loading: () => _buildSkeleton(height: 240),
                error: (err, stack) => _buildErrorCard(err.toString()),
              ),
              const SizedBox(height: 20),

              // 2. EF Progress Section
              efProgressAsync.when(
                data: (progress) => EfProgressRing(progress: progress),
                loading: () => _buildSkeleton(height: 150),
                error: (err, stack) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // 3. Income vs Expense History Chart
              historyAsync.when(
                data: (metrics) => Column(
                  children: [
                    IncomeExpenseChart(metrics: metrics),
                    const SizedBox(height: 20),
                    SavingsTrendChart(metrics: metrics),
                  ],
                ),
                loading: () => _buildSkeleton(height: 180),
                error: (err, stack) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // 4. Active Installments
              debtsAsync.when(
                data: (debts) => DebtList(debts: debts),
                loading: () => _buildSkeleton(height: 130),
                error: (err, stack) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // 5. Savings Goals
              goalsAsync.when(
                data: (goals) => SavingsGoalsList(goals: goals),
                loading: () => _buildSkeleton(height: 130),
                error: (err, stack) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetupPrompt(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.green.shade400,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Setup Your Profile First',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please complete your onboarding and setup your monthly income and ratios in Settings first.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton({required double height}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.04),
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white30),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade400.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.shade400.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade400),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Error loading dashboard: $message',
              style: TextStyle(
                color: Colors.red.shade300,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
