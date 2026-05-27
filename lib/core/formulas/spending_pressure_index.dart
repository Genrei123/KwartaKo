import 'package:kwartako/core/models/SpendingPressureIndex/spending_pressure_index_interpretation.dart';
import 'package:kwartako/core/models/SpendingPressureIndex/spending_pressure_index_result.dart';

class SpiEngine {
  SpiResult calculate({
    required double expenseAmount,
    required double monthlyIncome,
    required double totalFixedExpenses,
    required double totalActiveDebts,
    double? currentNetWorth,
  }) {
    _validate(expenseAmount, monthlyIncome);

    var freeCash = _freeCashCalculation(
      monthlyIncome: monthlyIncome,
      totalFixedExpenses: totalFixedExpenses,
      totalActiveDebts: totalActiveDebts,
    );

    if (currentNetWorth != null) {
      if (currentNetWorth < freeCash) {
        freeCash = currentNetWorth.clamp(0.0, double.infinity);
      }
    }

    if (freeCash <= 0) {
      return SpiResult(
        freeCash: freeCash,
        remainingCash: -expenseAmount,
        spiPercent: double.infinity,
        interpretation: SpiInterpretation.noFreeCash,
      );
    }

    final spiPercent = (expenseAmount / freeCash) * 100;
    final remainingCash = freeCash - expenseAmount;
    final interpretation = SpiInterpretation.fromPercent(spiPercent);

    return SpiResult(
      freeCash: freeCash,
      remainingCash: remainingCash,
      spiPercent: spiPercent,
      interpretation: interpretation,
    );
  }

  void _validate(double expense, double income) {
    if (expense < 0) {
      throw ArgumentError('Expense amount cannot be negative.');
    }
    if (income <= 0) {
      throw ArgumentError('Monthly income must be greater than zero.');
    }
  }

  double _freeCashCalculation({
    required double monthlyIncome,
    required double totalFixedExpenses,
    required double totalActiveDebts,
  }) {
    return monthlyIncome - totalFixedExpenses - totalActiveDebts;
  }
}