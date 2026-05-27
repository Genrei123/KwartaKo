class FreeCashCalculator {
  final double monthlyIncome;
  final double totalFixedExpenses;
  final double totalActiveDebts;

  FreeCashCalculator({
    required this.monthlyIncome,
    required this.totalFixedExpenses,
    required this.totalActiveDebts,
  });

  double calculate() {
    return monthlyIncome - totalFixedExpenses - totalActiveDebts;
  }
}