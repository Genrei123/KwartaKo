class DebtPayoffResult {
  final int monthsToPayoff;
  final double totalPaid;
  final double totalInterestPaid;
  final List<DebtMonthlySnapshot> schedule;

  const DebtPayoffResult({
    required this.monthsToPayoff,
    required this.totalPaid,
    required this.totalInterestPaid,
    required this.schedule,
  });
}

class DebtMonthlySnapshot {
  final int month;
  final Map<String, double> remainingBalances; // debt name -> balance
  final double totalPaidThisMonth;
  final double interestPaidThisMonth;

  const DebtMonthlySnapshot({
    required this.month,
    required this.remainingBalances,
    required this.totalPaidThisMonth,
    required this.interestPaidThisMonth,
  });
}
