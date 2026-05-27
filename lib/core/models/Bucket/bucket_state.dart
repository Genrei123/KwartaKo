import 'package:kwartako/core/models/Budget/budget_category.dart';

class BucketState {
  final double needsRemaining;
  final double wantsRemaining;
  final double flexRemaining;
  final double emergencyRemaining;

  const BucketState({
    required this.needsRemaining,
    required this.wantsRemaining,
    required this.flexRemaining,
    required this.emergencyRemaining,
  });

  double remainingFor(BudgetCategory bucket) => switch (bucket) {
    BudgetCategory.needs     => needsRemaining,
    BudgetCategory.wants     => wantsRemaining,
    BudgetCategory.flex      => flexRemaining,
    BudgetCategory.emergency => emergencyRemaining,
  };

  void validate() {
    final buckets = [needsRemaining, wantsRemaining, flexRemaining, emergencyRemaining];
    if (buckets.any((b) => b < 0)) {
      throw ArgumentError('Bucket balances cannot be negative.');
    }
  }
}