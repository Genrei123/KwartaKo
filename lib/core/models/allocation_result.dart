class AllocationResult {
  final double emergencyContribution;
  final double debtDeduction;
  final double assignableCash;
  final double needsAllocation;
  final double wantsAllocation;
  final double flexAllocation;

  /// How far off from zero the sum is — should be ~0.0
  /// Anything above 0.001 means a rounding issue
  final double zeroDrift;
  bool get isBalanced => zeroDrift.abs() < 0.001;

  const AllocationResult({
    required this.emergencyContribution,
    required this.debtDeduction,
    required this.assignableCash,
    required this.needsAllocation,
    required this.wantsAllocation,
    required this.flexAllocation,
    required this.zeroDrift,
  });

  @override
  String toString() => '''
AllocationResult:
  Emergency contribution : ₱${emergencyContribution.toStringAsFixed(2)}
  Debt deduction         : ₱${debtDeduction.toStringAsFixed(2)}
  Assignable cash        : ₱${assignableCash.toStringAsFixed(2)}
  Needs                  : ₱${needsAllocation.toStringAsFixed(2)}
  Wants                  : ₱${wantsAllocation.toStringAsFixed(2)}
  Flex                   : ₱${flexAllocation.toStringAsFixed(2)}
  Zero-sum drift         : ₱${zeroDrift.toStringAsFixed(4)}
  Balanced               : $isBalanced
''';
}