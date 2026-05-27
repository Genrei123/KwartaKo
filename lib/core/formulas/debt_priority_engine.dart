import 'dart:math' as math;
import '../models/Debt/debt.dart';
import '../models/Debt/debt_payoff_result.dart';

class DebtPriorityEngine {
  const DebtPriorityEngine();

  /// Runs both Snowball and Avalanche payoff simulations side-by-side
  /// and returns a comparison.
  DebtPriorityComparison compare({
    required List<Debt> debts,
    required double monthlyPayoffBudget,
  }) {
    for (final d in debts) {
      d.validate();
    }

    final totalMinimums = debts.fold<double>(0, (sum, d) => sum + d.minimumPayment);
    // Ensure budget is at least the sum of minimum payments to make the comparison valid
    final actualBudget = math.max(monthlyPayoffBudget, totalMinimums);

    final snowballResult = _simulate(
      debts: debts,
      monthlyBudget: actualBudget,
      strategy: DebtPriorityStrategy.snowball,
    );

    final avalancheResult = _simulate(
      debts: debts,
      monthlyBudget: actualBudget,
      strategy: DebtPriorityStrategy.avalanche,
    );

    return DebtPriorityComparison(
      snowball: snowballResult,
      avalanche: avalancheResult,
      interestSaved: (snowballResult.totalInterestPaid - avalancheResult.totalInterestPaid).abs(),
      monthsSaved: (snowballResult.monthsToPayoff - avalancheResult.monthsToPayoff).abs(),
      recommendedStrategy: avalancheResult.totalInterestPaid <= snowballResult.totalInterestPaid
          ? DebtPriorityStrategy.avalanche
          : DebtPriorityStrategy.snowball,
    );
  }

  DebtPayoffResult _simulate({
    required List<Debt> debts,
    required double monthlyBudget,
    required DebtPriorityStrategy strategy,
  }) {
    // Clone initial debts into a mutable list of maps or objects
    List<SimulatedDebt> activeDebts = debts
        .where((d) => d.balance > 0)
        .map((d) => SimulatedDebt(
              name: d.name,
              balance: d.balance,
              interestRate: d.interestRate,
              minimumPayment: d.minimumPayment,
            ))
        .toList();

    if (activeDebts.isEmpty) {
      return const DebtPayoffResult(
        monthsToPayoff: 0,
        totalPaid: 0,
        totalInterestPaid: 0,
        schedule: [],
      );
    }

    final List<DebtMonthlySnapshot> schedule = [];
    double totalPaid = 0.0;
    double totalInterestPaid = 0.0;
    int month = 0;

    const int maxMonths = 360; // 30 years safety limit

    while (activeDebts.isNotEmpty && month < maxMonths) {
      month++;
      double interestAccruedThisMonth = 0.0;

      // 1. Accrue monthly interest
      for (final debt in activeDebts) {
        final monthlyInterest = debt.balance * (debt.interestRate / 12.0);
        debt.balance += monthlyInterest;
        interestAccruedThisMonth += monthlyInterest;
        totalInterestPaid += monthlyInterest;
      }

      double availableBudget = monthlyBudget;
      double paidThisMonth = 0.0;

      // 2. Pay minimums first for all active debts
      final Map<String, double> paymentsThisMonth = {};
      
      for (final debt in activeDebts) {
        final payment = math.min(debt.balance, debt.minimumPayment);
        debt.balance -= payment;
        availableBudget -= payment;
        paidThisMonth += payment;
        paymentsThisMonth[debt.name] = payment;
      }

      // Filter out debts that are completely paid off by minimum payments
      activeDebts = activeDebts.where((d) => d.balance > 0).toList();

      // 3. Apply extra budget to target debt based on strategy
      if (availableBudget > 0 && activeDebts.isNotEmpty) {
        // Sort active debts according to selected strategy
        if (strategy == DebtPriorityStrategy.snowball) {
          // Snowball: Smallest balance first
          activeDebts.sort((a, b) => a.balance.compareTo(b.balance));
        } else {
          // Avalanche: Highest interest rate first, then largest balance
          activeDebts.sort((a, b) {
            final rateComp = b.interestRate.compareTo(a.interestRate);
            if (rateComp != 0) return rateComp;
            return b.balance.compareTo(a.balance); // tie-breaker
          });
        }

        // Apply remaining budget sequentially
        int debtIndex = 0;
        while (availableBudget > 0 && debtIndex < activeDebts.length) {
          final target = activeDebts[debtIndex];
          final extraPayment = math.min(target.balance, availableBudget);
          target.balance -= extraPayment;
          availableBudget -= extraPayment;
          paidThisMonth += extraPayment;
          paymentsThisMonth[target.name] = (paymentsThisMonth[target.name] ?? 0.0) + extraPayment;
          debtIndex++;
        }

        // Filter out completed debts again
        activeDebts = activeDebts.where((d) => d.balance > 0).toList();
      }

      totalPaid += paidThisMonth;

      // Record monthly snapshot
      final remainingBalances = {
        for (final d in debts)
          d.name: activeDebts.any((ad) => ad.name == d.name)
              ? activeDebts.firstWhere((ad) => ad.name == d.name).balance
              : 0.0
      };

      schedule.add(DebtMonthlySnapshot(
        month: month,
        remainingBalances: remainingBalances,
        totalPaidThisMonth: paidThisMonth,
        interestPaidThisMonth: interestAccruedThisMonth,
      ));
    }

    return DebtPayoffResult(
      monthsToPayoff: month,
      totalPaid: totalPaid,
      totalInterestPaid: totalInterestPaid,
      schedule: schedule,
    );
  }
}

enum DebtPriorityStrategy { snowball, avalanche }

class SimulatedDebt {
  final String name;
  double balance;
  final double interestRate;
  final double minimumPayment;

  SimulatedDebt({
    required this.name,
    required this.balance,
    required this.interestRate,
    required this.minimumPayment,
  });
}

class DebtPriorityComparison {
  final DebtPayoffResult snowball;
  final DebtPayoffResult avalanche;
  final double interestSaved;
  final int monthsSaved;
  final DebtPriorityStrategy recommendedStrategy;

  const DebtPriorityComparison({
    required this.snowball,
    required this.avalanche,
    required this.interestSaved,
    required this.monthsSaved,
    required this.recommendedStrategy,
  });

  String get recommendedStrategyLabel => recommendedStrategy == DebtPriorityStrategy.avalanche
      ? 'Avalanche (Save Interest)'
      : 'Snowball (Boost Motivation)';
}
