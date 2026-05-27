import 'package:kwartako/core/models/SpendingPressureIndex/spending_pressure_index_interpretation.dart';

class SpiResult {
  final double freeCash;
  final double remainingCash;
  final double spiPercent;
  final SpiInterpretation interpretation;

  // Convenience getters — caller doesn't need to dig into the enum
  String get color   => interpretation.color;
  String get message => interpretation.message(remainingCash);
  String get label   => interpretation.label;

  const SpiResult({
    required this.freeCash,
    required this.remainingCash,
    required this.spiPercent,
    required this.interpretation,
  });

  @override
  String toString() => '''
SpiResult:
  Free cash      : ₱${freeCash.toStringAsFixed(2)}
  Expense pct    : ${spiPercent.toStringAsFixed(1)}%
  Remaining      : ₱${remainingCash.toStringAsFixed(2)}
  Interpretation : ${interpretation.label}
  Color          : $color
  Message        : $message
''';
}