import 'package:kwartako/core/common/util.dart';
import 'package:kwartako/core/models/Budget/budget_category.dart';

enum CascadeWarningLevel { silent, yellow, orange, red }

class CascadeStep {
  final BudgetCategory bucket;
  final double deducted;

  const CascadeStep({
    required this.bucket,
    required this.deducted,
  });

  @override
  String toString() => '${bucket.name}: ₱${deducted.toStringAsFixed(2)}';
}

class CascadeResult {
  final List<CascadeStep> steps;
  final double totalDeducted;
  final double unresolved; // > 0 means all buckets exhausted, still short
  final bool hitsEmergency;
  final int cascadeDepth;
  final CascadeWarningLevel warningLevel;
  final String message;

  const CascadeResult({
    required this.steps,
    required this.totalDeducted,
    required this.unresolved,
    required this.hitsEmergency,
    required this.cascadeDepth,
    required this.warningLevel,
    required this.message,
  });

  bool get isFullyResolved => unresolved < KwartaKoConstants.floatingPointTolerance;

  @override
  String toString() => '''
CascadeResult:
  Steps          : ${steps.map((s) => s.toString()).join(' → ')}
  Total deducted : ₱${totalDeducted.toStringAsFixed(2)}
  Unresolved     : ₱${unresolved.toStringAsFixed(2)}
  Cascade depth  : $cascadeDepth bucket(s)
  Hits emergency : $hitsEmergency
  Warning level  : ${warningLevel.name}
  Message        : $message
''';
}