import 'package:kwartako/core/formulas/free_cash_calculator.dart';
import 'package:kwartako/core/models/Affordability/affordability_check_result.dart';
import 'package:kwartako/core/models/EmergencyFundErosionRate/emergency_fund_context.dart';

class InstallmentAffordabilityCheck {


  AffordabilityCheckResult check({
    required double itemPrice,
    required double monthsToPay,
    required totalFixedExpenses,
    required totalActiveDebts,
    required EmergencyFundContext emergencyFund,
  }) {
    
    final monthlyInstallment = itemPrice / monthsToPay;
    final freeCash = FreeCashCalculator(
      monthlyIncome: emergencyFund.monthlyContribution,
      totalFixedExpenses: totalFixedExpenses,
      totalActiveDebts: totalActiveDebts,
    ).calculate();

    final bufferAfter = freeCash - monthlyInstallment;
    final safetyBuffer = totalFixedExpenses * 0.10;
    String message = affordabilityMessage(bufferAfter, safetyBuffer);

    return AffordabilityCheckResult(
      isAffordable: bufferAfter >= safetyBuffer,
      message: message,
    );
  }

  String affordabilityMessage(double bufferAfter, double safetyBuffer) {
    if (bufferAfter >= safetyBuffer) {
      return "This purchase is affordable within your current budget.";
    } else {
      return "This purchase may strain your budget. Consider adjusting your expenses or choosing a less expensive item.";
    }
  }
}