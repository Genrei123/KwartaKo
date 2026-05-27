class EmergencyFundContext {
  final double monthlyContribution;
  final double currentBalance;
  final double target;

  const EmergencyFundContext({
    required this.monthlyContribution,
    required this.currentBalance,
    required this.target,
  });

  double get remaining => target - currentBalance;
  bool get isFunded => monthlyContribution > 0;
  bool get isComplete => currentBalance >= target;

  void validate() {
    if (monthlyContribution < 0) {
      throw ArgumentError('Monthly contribution cannot be negative.');
    }
    if (currentBalance < 0) {
      throw ArgumentError('Current balance cannot be negative.');
    }
    if (target <= 0) {
      throw ArgumentError('Target must be greater than zero.');
    }
  }
}