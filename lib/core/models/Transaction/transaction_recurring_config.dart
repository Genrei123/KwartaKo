// lib/core/models/transaction/transaction_recurring_config.dart

import 'package:kwartako/core/enums/recurring_interval.dart';

class RecurringConfig {
  /// When this recurrence begins
  final DateTime startDate;

  /// How often the transaction repeats
  final RecurringInterval interval;

  /// For monthly : 1–31 (day of month, e.g. salary on the 15th)
  /// For weekly  : 1–7  (1 = Monday, 7 = Sunday)
  /// For daily/yearly: ignored — fires relative to startDate
  final int? onDay;

  /// When recurrence stops. Null means it repeats forever.
  final DateTime? endDate;

  const RecurringConfig({
    required this.startDate,
    required this.interval,
    this.onDay,
    this.endDate,
  });

  // ── Named constructors — make intent clear at the call site ────────────────

  /// Fires every month on a specific day (e.g. salary on the 15th)
  const RecurringConfig.monthly({
    required this.startDate,
    required int day,
    this.endDate,
  })  : interval = RecurringInterval.monthly,
        onDay = day;

  /// Fires every week on a specific day (1 = Monday, 7 = Sunday)
  const RecurringConfig.weekly({
    required this.startDate,
    required int weekday,
    this.endDate,
  })  : interval = RecurringInterval.weekly,
        onDay = weekday;

  /// Fires every day starting from startDate
  const RecurringConfig.daily({
    required this.startDate,
    this.endDate,
  })  : interval = RecurringInterval.daily,
        onDay = null;

  /// Fires once a year on the same month/day as startDate
  const RecurringConfig.yearly({
    required this.startDate,
    this.endDate,
  })  : interval = RecurringInterval.yearly,
        onDay = null;

  // ── Core logic ─────────────────────────────────────────────────────────────

  /// Computes the next occurrence strictly after [from]
  DateTime nextOccurrenceAfter(DateTime from) => switch (interval) {
    RecurringInterval.daily   => from.add(const Duration(days: 1)),
    RecurringInterval.weekly  => from.add(const Duration(days: 7)),
    RecurringInterval.monthly => DateTime(
        from.year,
        from.month + 1,
        (onDay ?? from.day).clamp(1, 28),
      ),
    RecurringInterval.yearly  => DateTime(
        from.year + 1,
        from.month,
        from.day,
      ),
  };

  /// Whether this recurrence is still active on a given date
  bool isActiveOn(DateTime date) {
    if (date.isBefore(startDate)) return false;
    if (endDate == null) return true;
    return !date.isAfter(endDate!);
  }

  /// All dates this recurrence fires between [from] and [to] inclusive
  /// Useful for: "which recurring transactions fire this month?"
  List<DateTime> allOccurrencesBetween(DateTime from, DateTime to) {
    final occurrences = <DateTime>[];

    // Start iterating from startDate or from, whichever is later
    var current = startDate.isBefore(from) ? _firstOccurrenceOnOrAfter(from) : startDate;

    while (!current.isAfter(to)) {
      if (isActiveOn(current)) {
        occurrences.add(current);
      }
      current = nextOccurrenceAfter(current);
    }

    return occurrences;
  }

  /// Finds the first valid occurrence on or after a given date
  DateTime _firstOccurrenceOnOrAfter(DateTime target) {
    var current = startDate;
    while (current.isBefore(target)) {
      current = nextOccurrenceAfter(current);
    }
    return current;
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  void validate() {
    if (endDate != null && endDate!.isBefore(startDate)) {
      throw ArgumentError('endDate cannot be before startDate.');
    }
    if (interval == RecurringInterval.monthly && onDay != null) {
      if (onDay! < 1 || onDay! > 31) {
        throw ArgumentError('onDay must be between 1 and 31 for monthly recurrence.');
      }
    }
    if (interval == RecurringInterval.weekly && onDay != null) {
      if (onDay! < 1 || onDay! > 7) {
        throw ArgumentError('onDay must be between 1 and 7 for weekly recurrence.');
      }
    }
  }

  @override
  String toString() {
    final dayLabel   = onDay    != null ? ' on day $onDay'              : '';
    final startLabel = 'from ${startDate.toLocal().toString().split(' ')[0]}';
    final endLabel   = endDate  != null
        ? ' until ${endDate!.toLocal().toString().split(' ')[0]}'
        : ' forever';
    return 'Every ${interval.name}$dayLabel $startLabel$endLabel';
  }
}