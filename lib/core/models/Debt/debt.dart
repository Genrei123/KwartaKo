class Debt {
  final String name;
  final double balance;
  final double interestRate; // Annual rate, e.g., 0.12 for 12%
  final double minimumPayment;

  const Debt({
    required this.name,
    required this.balance,
    required this.interestRate,
    required this.minimumPayment,
  });

  /// Validates the debt values
  void validate() {
    if (balance < 0) {
      throw ArgumentError('Debt balance cannot be negative.');
    }
    if (interestRate < 0) {
      throw ArgumentError('Interest rate cannot be negative.');
    }
    if (minimumPayment < 0) {
      throw ArgumentError('Minimum payment cannot be negative.');
    }
  }

  Debt copyWith({
    String? name,
    double? balance,
    double? interestRate,
    double? minimumPayment,
  }) {
    return Debt(
      name: name ?? this.name,
      balance: balance ?? this.balance,
      interestRate: interestRate ?? this.interestRate,
      minimumPayment: minimumPayment ?? this.minimumPayment,
    );
  }
}
