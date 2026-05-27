class HealthScoreContext {
  final double monthlyDebtPayments;
  final double monthlyIncome;
  final double emergencyFunds;          
  final double monthlySaved;
  final double cashFlow;          
  final double netWorth;

  const HealthScoreContext({
    required this.monthlyDebtPayments,
    required this.monthlyIncome,
    required this.emergencyFunds,
    required this.monthlySaved,
    required this.cashFlow,
    required this.netWorth,
  });

  void validate() {
    if (monthlyIncome <= 0) {
      throw ArgumentError('Monthly income must be greater than zero.');
    }
    if (monthlyDebtPayments < 0) {
      throw ArgumentError('Debt payments cannot be negative.');
    }
    if (emergencyFunds < 0) {
      throw ArgumentError('EF months cannot be negative.');
    }
    if (monthlySaved < 0) {
      throw ArgumentError('Monthly saved cannot be negative.');
    }
    if (netWorth < 0) {
      // Net worth can theoretically be negative if there is extremely high debt, 
      // but let's allow 0 as floor or handle negative net worth gracefully.
    }
  }
}