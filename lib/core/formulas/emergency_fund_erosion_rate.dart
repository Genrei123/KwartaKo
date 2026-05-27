import 'package:kwartako/core/common/util.dart';
import 'package:kwartako/core/models/EmergencyFundErosionRate/emergency_fund_context.dart';
import 'package:kwartako/core/models/EmergencyFundErosionRate/emergency_fund_erosion_rate_result.dart';

class EmergencyFundErosionRate {

  EmergencyFundErosionRateResult calculate({
    required double expenseAmount,
    required double remainingFreeCash,
    required EmergencyFundContext emergencyFund,
  }) {
    _validateInputs(expenseAmount, remainingFreeCash, emergencyFund);

    final overspend = (expenseAmount - remainingFreeCash).clamp(0.0, double.infinity); 
    final dailyErosionRate = emergencyFund.monthlyContribution / KwartaKoConstants.daysInMonth;
    final daysDelayed = overspend / dailyErosionRate;
    final message = createMessage(daysDelayed, emergencyFund);

    return EmergencyFundErosionRateResult(
      overSpend: overspend,
      dailyErosionBuildRate: dailyErosionRate,
      daysDelayed: daysDelayed,
      message: message,
    );
  }

  void _validateInputs(double expenseAmount, double remainingFreeCash, EmergencyFundContext emergencyFund) {
    if (expenseAmount < 0) {
      throw ArgumentError('Expense amount cannot be negative');
    }
  }

  String createMessage(double daysDelayed, EmergencyFundContext emergencyFund) {
    if (emergencyFund.currentBalance <= 0) {
      if (daysDelayed > 0) {
        return "You have no Emergency Fund active yet. This expense will delay building your Emergency Fund target by ${daysDelayed.toStringAsFixed(1)} days.";
      }
      return "You have no Emergency Fund active yet. Start allocating to complete your target of ₱${emergencyFund.target.toStringAsFixed(2)}.";
    }

    if (daysDelayed <= 0) {
      return "No impact on your emergency fund.";
    } else if (daysDelayed < 7) {
      return "Your emergency fund will be delayed by ${daysDelayed.toStringAsFixed(1)} days.";
    } else {
      return "Your emergency fund will be significantly delayed by ${daysDelayed.toStringAsFixed(1)} days. Consider adjusting your budget.";
    }
  } 
}