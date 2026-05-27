import 'dart:math' as math;
import '../../core/formulas/financial_health_score.dart';
import '../../core/models/FinancialHealthScore/financial_health_score_context.dart';
import '../../core/models/FinancialHealthScore/financial_health_score_result.dart';
import '../../infrastructure/models/db_models.dart';
import '../../infrastructure/repositories/app_repository.dart';

class DashboardService {
  final AppRepository _repository;

  DashboardService({required AppRepository repository}) : _repository = repository;

  /// Fetches the user profile
  Future<DbUserProfile?> getUserProfile() => _repository.getUserProfile();

  /// Gets the calculated Financial Health Score (F5)
  Future<HealthScoreResult?> getFinancialHealthScore() async {
    final profile = await _repository.getUserProfile();
    if (profile == null) return null;

    final now = DateTime.now();
    final currentIncome = await _repository.getMonthlyIncome(now.month, now.year);
    final income = currentIncome > 0 ? currentIncome : profile.monthlyIncome;

    final debtPayments = await _repository.getTotalActiveDebtPayments();

    // 1. Calculate Emergency Fund Balance (net accumulated emergency bucket)
    final efBalance = await getEmergencyFundBalance();

    // Average monthly needs/wants expenses (denominator)
    final expectedExpenses = income * (profile.needsRatio + profile.wantsRatio + profile.flexRatio);
    final denominator = expectedExpenses > 0 ? expectedExpenses : income;
    final efMonths = efBalance / denominator;

    // 2. Monthly Saved (current savings rate based on last 6 months or default ratio)
    final recentHistory = await getMonthlyMetricsHistory(limit: 6);
    double avgSavingsRate = profile.emergencyRatio; // default ratio
    if (recentHistory.isNotEmpty) {
      double totalIncome = 0;
      double totalSavings = 0;
      for (final m in recentHistory) {
        totalIncome += m.income;
        totalSavings += math.max(0.0, m.income - m.expenses);
      }
      if (totalIncome > 0) {
        avgSavingsRate = totalSavings / totalIncome;
      }
    }
    final monthlySaved = income * avgSavingsRate;

    // 3. Current month cash flow
    final currentExpenses = await _getCurrentMonthExpenses(now.month, now.year);
    final cashFlow = income - currentExpenses;

    // Get actual net worth (sum of all wallets)
    final balances = await _repository.getAllWalletBalances();
    double netWorth = 0.0;
    for (final val in balances.values) {
      netWorth += val;
    }

    final context = HealthScoreContext(
      monthlyDebtPayments: debtPayments,
      monthlyIncome: income,
      emergencyFunds: efMonths,
      monthlySaved: monthlySaved,
      cashFlow: cashFlow,
      netWorth: netWorth,
    );

    // Save/Upsert this budget period to DB for history tracking
    final period = DbBudgetPeriod(
      id: '${now.year}-${now.month.toString().padLeft(2, '0')}',
      month: now.month,
      year: now.year,
      totalIncome: income,
      needsAllocated: income * profile.needsRatio,
      wantsAllocated: income * profile.wantsRatio,
      emergencyAllocated: income * profile.emergencyRatio,
      flexAllocated: income * profile.flexRatio,
      totalDebtPayments: debtPayments,
      needsSpent: currentExpenses, // overall spent approximate
      wantsSpent: 0.0,
      healthScore: 0, // Will be computed or updated later
      savedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _repository.upsertBudgetPeriod(period);

    return const HealthScoreEngine().calculate(context);
  }

  /// Calculates the net Emergency Fund balance (income - expense in 'emergency' bucket)
  Future<double> getEmergencyFundBalance() async {
    final transactions = await _repository.getRecentTransactions(limit: 1000);
    double balance = 0.0;
    for (final tx in transactions) {
      if (tx.bucket == 'emergency') {
        if (tx.type == 'income') {
          balance += tx.amount;
        } else if (tx.type == 'expense') {
          balance -= tx.amount;
        }
      }
    }
    return math.max(0.0, balance);
  }

  /// Gets the emergency fund progress stats (current EF balance, target balance, target months, actual months)
  Future<EmergencyFundProgress> getEmergencyFundProgress() async {
    final profile = await _repository.getUserProfile();
    final efBalance = await getEmergencyFundBalance();

    if (profile == null) {
      return EmergencyFundProgress(
        currentBalance: efBalance,
        targetBalance: 15000.0,
        targetMonths: 6,
        monthsCovered: 0.0,
        progressPercent: 0.0,
      );
    }

    final now = DateTime.now();
    final currentIncome = await _repository.getMonthlyIncome(now.month, now.year);
    final income = currentIncome > 0 ? currentIncome : profile.monthlyIncome;

    final expectedExpenses = income * (profile.needsRatio + profile.wantsRatio + profile.flexRatio);
    final denominator = expectedExpenses > 0 ? expectedExpenses : income;

    final targetMonths = 6;
    final targetBalance = denominator * targetMonths;
    final monthsCovered = efBalance / denominator;
    final progressPercent = targetBalance > 0 ? (efBalance / targetBalance).clamp(0.0, 1.0) : 0.0;

    return EmergencyFundProgress(
      currentBalance: efBalance,
      targetBalance: targetBalance > 0 ? targetBalance : 15000.0,
      targetMonths: targetMonths,
      monthsCovered: monthsCovered,
      progressPercent: progressPercent,
    );
  }

  /// Gets the monthly income, expense and savings rate history for the last 6 months
  Future<List<MonthlyMetrics>> getMonthlyMetricsHistory({int limit = 6}) async {
    final List<MonthlyMetrics> history = [];
    final now = DateTime.now();

    for (int i = limit - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final month = date.month;
      final year = date.year;

      final income = await _repository.getMonthlyIncome(month, year);
      final expenses = await _getCurrentMonthExpenses(month, year);

      final savingsRate = income > 0 ? (income - expenses) / income : 0.0;

      history.add(MonthlyMetrics(
        month: month,
        year: year,
        income: income,
        expenses: expenses,
        savingsRate: savingsRate,
      ));
    }

    return history;
  }

  Future<double> _getCurrentMonthExpenses(int month, int year) async {
    final Map<String, double> spendingMap = await _repository.getMonthlyBucketSpending(month, year);
    return spendingMap.values.fold<double>(0.0, (double sum, double val) => sum + val);
  }

  /// Gets active installments
  Future<List<DbInstallment>> getActiveInstallments() => _repository.getActiveInstallments();

  /// Gets active savings goals
  Future<List<DbSavingsGoal>> getActiveSavingsGoals() => _repository.getActiveSavingsGoals();
}

class MonthlyMetrics {
  final int month;
  final int year;
  final double income;
  final double expenses;
  final double savingsRate; // e.g. 0.20 for 20%

  const MonthlyMetrics({
    required this.month,
    required this.year,
    required this.income,
    required this.expenses,
    required this.savingsRate,
  });

  String get monthName => switch (month) {
        1 => 'Jan',
        2 => 'Feb',
        3 => 'Mar',
        4 => 'Apr',
        5 => 'May',
        6 => 'Jun',
        7 => 'Jul',
        8 => 'Aug',
        9 => 'Sep',
        10 => 'Oct',
        11 => 'Nov',
        12 => 'Dec',
        _ => '',
      };
}

class EmergencyFundProgress {
  final double currentBalance;
  final double targetBalance;
  final int targetMonths;
  final double monthsCovered;
  final double progressPercent; // 0.0 to 1.0

  const EmergencyFundProgress({
    required this.currentBalance,
    required this.targetBalance,
    required this.targetMonths,
    required this.monthsCovered,
    required this.progressPercent,
  });
}
