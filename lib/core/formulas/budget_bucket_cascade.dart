import 'package:kwartako/core/common/util.dart';
import 'package:kwartako/core/models/Bucket/bucket_state.dart';
import 'package:kwartako/core/models/Bucket/cascade_result.dart';
import 'package:kwartako/core/models/Budget/budget_category.dart';
import 'package:kwartako/core/models/User/cascade_mode.dart';

class BbcEngine {
  final CascadeMode mode;

  const BbcEngine({this.mode = CascadeMode.soft});

  CascadeResult calculate({
    required double expenseAmount,
    required BudgetCategory targetBucket,
    required BucketState bucketState,
  }) {
    _validate(expenseAmount);
    bucketState.validate();

    // Cascade order: target bucket first, then the rest
    // Emergency is always last — it's the protected bucket
    final cascadeOrder = mode == CascadeMode.strict
        ? [targetBucket]
        : _buildCascadeOrder(targetBucket);

    final steps = <CascadeStep>[];
    var remaining = expenseAmount;

    for (final bucket in cascadeOrder) {
      if (remaining <= KwartaKoConstants.floatingPointTolerance) break;

      final available = bucketState.remainingFor(bucket);
      if (available <= 0) continue;

      final deducted = remaining < available ? remaining : available;
      steps.add(CascadeStep(bucket: bucket, deducted: deducted));
      remaining -= deducted;
    }

    final totalDeducted = expenseAmount - remaining;
    final hitsEmergency = steps.any((s) => s.bucket == BudgetCategory.emergency);
    final cascadeDepth = steps.length;
    final warningLevel = _warningLevel(cascadeDepth, hitsEmergency);
    final message = _message(
      warningLevel: warningLevel,
      steps: steps,
      unresolved: remaining,
      targetBucket: targetBucket,
    );

    return CascadeResult(
      steps: steps,
      totalDeducted: totalDeducted,
      unresolved: remaining,
      hitsEmergency: hitsEmergency,
      cascadeDepth: cascadeDepth,
      warningLevel: warningLevel,
      message: message,
    );
  }

  // ── Cascade order ───────────────────────────────────────────────────────────
  // Target bucket is always first. Emergency is always last.
  // Remaining order: wants → needs → flex (excluding target and emergency)
  List<BudgetCategory> _buildCascadeOrder(BudgetCategory target) {
    const fullOrder = [
      BudgetCategory.wants,
      BudgetCategory.needs,
      BudgetCategory.flex,
      BudgetCategory.emergency,
    ];

    return [
      target,
      ...fullOrder.where((b) => b != target && b != BudgetCategory.emergency),
      BudgetCategory.emergency,
    ];
  }

  // ── Warning level ───────────────────────────────────────────────────────────
  CascadeWarningLevel _warningLevel(int depth, bool hitsEmergency) {
    if (hitsEmergency) return CascadeWarningLevel.red;
    if (depth >= 3)    return CascadeWarningLevel.orange;
    if (depth == 2)    return CascadeWarningLevel.yellow;
    return CascadeWarningLevel.silent;
  }

  // ── Message ─────────────────────────────────────────────────────────────────
  String _message({
    required CascadeWarningLevel warningLevel,
    required List<CascadeStep> steps,
    required double unresolved,
    required BudgetCategory targetBucket,
  }) {
    if (unresolved > KwartaKoConstants.floatingPointTolerance) {
      if (mode == CascadeMode.strict) {
        return 'Strict Mode: target ${targetBucket.name} bucket exhausted. ₱${unresolved.toStringAsFixed(2)} '
            'cannot be covered and cascade is disabled.';
      }
      return 'All buckets exhausted. ₱${unresolved.toStringAsFixed(2)} '
          'cannot be covered this month.';
    }

    return switch (warningLevel) {
      CascadeWarningLevel.silent => 'Deducted cleanly from your '
          '${targetBucket.name} bucket.',
      CascadeWarningLevel.yellow => 'Your ${targetBucket.name} bucket ran short. '
          '₱${steps.last.deducted.toStringAsFixed(2)} pulled from '
          '${steps.last.bucket.name}.',
      CascadeWarningLevel.orange => 'This expense cascades across '
          '${steps.length} buckets: '
          '${steps.map((s) => s.bucket.name).join(' → ')}.',
      CascadeWarningLevel.red   => 'This expense reaches your Emergency Fund. '
          '₱${steps.last.deducted.toStringAsFixed(2)} will be pulled '
          'from your emergency savings.',
    };
  }

  void _validate(double expenseAmount) {
    if (expenseAmount <= 0) {
      throw ArgumentError('Expense amount must be greater than zero.');
    }
  }
}