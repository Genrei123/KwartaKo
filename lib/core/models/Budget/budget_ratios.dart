class BudgetRatios {
  final double emergency;
  final double needs;
  final double wants;
  final double flex;

  const BudgetRatios({
    required this.emergency,
    required this.needs,
    required this.wants,
    required this.flex,
  });

  const BudgetRatios.defaults()
      : emergency = 0.10,
        needs = 0.60,
        wants = 0.20,
        flex = 0.10;

  void validate() {
    final ratios = [emergency, needs, wants, flex];

    if (ratios.any((r) => r < 0)) {
      throw ArgumentError('All ratios must be non-negative.');
    }

    final sum = ratios.fold(0.0, (a, b) => a + b);
    if ((sum - 1.0).abs() > 0.001) {
      throw ArgumentError('Ratios must sum to 1.0. Got: $sum');
    }
  }
}