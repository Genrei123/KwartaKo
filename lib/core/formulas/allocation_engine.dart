import 'dart:math' as math;
import '../models/Budget/budget_ratios.dart';
import '../models/allocation_result.dart';

class AllocationEngine {
  final BudgetRatios ratios;

  const AllocationEngine({required this.ratios});

  AllocationResult calculate({
    required double incomeAmount,
    required List<double> activeInstallments,
  }) {
    _validate(incomeAmount, activeInstallments);

    final emergency = incomeAmount * ratios.emergency;
    final debtDeduction = activeInstallments.fold(0.0, (sum, i) => sum + i);
    final assignable = incomeAmount - emergency - debtDeduction;

    final totalNeedsWantsFlex = ratios.needs + ratios.wants + ratios.flex;
    final needsRatio = totalNeedsWantsFlex > 0 ? ratios.needs / totalNeedsWantsFlex : 0.0;
    final wantsRatio = totalNeedsWantsFlex > 0 ? ratios.wants / totalNeedsWantsFlex : 0.0;
    final flexRatio = totalNeedsWantsFlex > 0 ? ratios.flex / totalNeedsWantsFlex : 0.0;

    final needs = assignable * needsRatio;
    final wants = assignable * wantsRatio;
    final flex = assignable * flexRatio;

    final allocatedTotal = emergency + debtDeduction + needs + wants + flex;
    final zeroDrift = math.max(0.0, incomeAmount - allocatedTotal);

    return AllocationResult(
      emergencyContribution: emergency,
      debtDeduction: debtDeduction,
      assignableCash: assignable,
      needsAllocation: needs,
      wantsAllocation: wants,
      flexAllocation: flex,
      zeroDrift: zeroDrift,
    );
  }

  void _validate(double income, List<double> installments) {
    if (income <= 0) {
      throw ArgumentError('Income must be greater than zero.');
    }
    if (installments.any((i) => i < 0)) {
      throw ArgumentError('Installments cannot contain negative values.');
    }
    ratios.validate();
  }
}