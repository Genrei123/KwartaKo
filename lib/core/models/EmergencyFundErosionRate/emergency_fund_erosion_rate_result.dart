class EmergencyFundErosionRateResult {
  double overSpend;
  double dailyErosionBuildRate;
  double daysDelayed;
  String message;

  EmergencyFundErosionRateResult({
    required this.overSpend,
    required this.dailyErosionBuildRate,
    required this.daysDelayed,
    required this.message,
  });
}