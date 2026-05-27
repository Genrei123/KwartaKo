class RuleOf72 {
  const RuleOf72();

  /// Estimates the number of years required to double the invested capital
  /// at a given annual interest rate percentage (e.g., 6.0 for 6%).
  double calculateYearsToDouble(double annualRatePercentage) {
    if (annualRatePercentage <= 0) {
      return double.infinity;
    }
    return 72.0 / annualRatePercentage;
  }

  /// Calculates the exact years to double using standard compound interest formula:
  /// A = P * (1 + r)^t => 2 = (1 + r)^t => t = ln(2) / ln(1 + r)
  double calculateExactYearsToDouble(double annualRatePercentage) {
    if (annualRatePercentage <= 0) {
      return double.infinity;
    }
    final r = annualRatePercentage / 100.0;
    return 0.693147 / (r - (r * r) / 2.0); // Taylor series or math.log approximation
  }
}
