enum SpiInterpretation {
  low(
    label: 'Low',
    color: 'Green',
    range: '0–25%',
  ),
  moderate(
    label: 'Moderate',
    color: 'Blue',
    range: '26–50%',
  ),
  high(
    label: 'High',
    color: 'Yellow',
    range: '51–75%',
  ),
  veryHigh(
    label: 'Very High',
    color: 'Orange',
    range: '76–99%',
  ),
  critical(
    label: 'Critical',
    color: 'Red',
    range: '100%+',
  ),
  noFreeCash(
    label: 'No Free Cash',
    color: 'Red',
    range: 'N/A',
  );

  final String label;
  final String color;
  final String range;

  const SpiInterpretation({
    required this.label,
    required this.color,
    required this.range,
  });

  /// Maps an SPI percentage to the correct interpretation
  static SpiInterpretation fromPercent(double spiPercent) {
    if (spiPercent <= 25) return low;
    if (spiPercent <= 50) return moderate;
    if (spiPercent <= 75) return high;
    if (spiPercent < 100) return veryHigh;
    return critical;
  }

  /// Human-readable message with remaining cash injected
  String message(double remainingCash) => switch (this) {
    low      => 'Comfortably within your free cash. ₱${remainingCash.toStringAsFixed(2)} remaining.',
    moderate => 'Moderate spend. ₱${remainingCash.toStringAsFixed(2)} remaining.',
    high     => 'This uses over half your free cash. ₱${remainingCash.toStringAsFixed(2)} remaining.',
    veryHigh => 'Nearly all your free cash. Proceed carefully. ₱${remainingCash.toStringAsFixed(2)} remaining.',
    critical => 'This exceeds your free cash. Review before confirming.',
    noFreeCash => 'You have no free cash this month. This expense cannot be absorbed.',
  };
}