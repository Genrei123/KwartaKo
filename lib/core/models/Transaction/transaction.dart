import 'package:kwartako/core/enums/transaction_category.dart';
import 'package:kwartako/core/models/Transaction/transaction_recurring_config.dart';
import 'package:kwartako/core/models/wallet.dart';

enum TransactionType { income, expense }

class Transaction {
  final int id;
  final DateTime date;
  final TransactionType type;
  final List<TransactionCategory> categories;
  final double amount;
  final Wallet wallet;
  final String? note;

  /// Null means this is a one-time transaction
  final RecurringConfig? recurringConfig;

  const Transaction._({
    required this.id,
    required this.date,
    required this.type,
    required this.categories,
    required this.amount,
    required this.wallet,
    this.note,
    this.recurringConfig,
  });

  // ── Convenience getters ───────────────────────────────────────────────────

  bool get isIncome    => type == TransactionType.income;
  bool get isExpense   => type == TransactionType.expense;
  bool get isRecurring => recurringConfig != null;

  DateTime? get nextOccurrence => isRecurring
      ? recurringConfig!.nextOccurrenceAfter(date)
      : null;

  // ── Factory: one-time income ───────────────────────────────────────────────

  factory Transaction.logIncome({
    required int id,
    required List<TransactionCategory> categories,
    required double amount,
    required Wallet wallet,
    String? note,
  }) {
    _validateAmount(amount);
    return Transaction._(
      id: id,
      date: DateTime.now(),
      type: TransactionType.income,
      categories: categories,
      amount: amount,
      wallet: wallet,
      note: note,
    );
  }

  // ── Factory: recurring income (e.g. salary every 15th) ────────────────────

  factory Transaction.logRecurringIncome({
    required int id,
    required List<TransactionCategory> categories,
    required double amount,
    required Wallet wallet,
    required RecurringConfig recurringConfig,
    String? note,
  }) {
    _validateAmount(amount);
    recurringConfig.validate();
    return Transaction._(
      id: id,
      date: DateTime.now(),
      type: TransactionType.income,
      categories: categories,
      amount: amount,
      wallet: wallet,
      note: note,
      recurringConfig: recurringConfig,
    );
  }

  // ── Factory: one-time expense ──────────────────────────────────────────────

  factory Transaction.logExpense({
    required int id,
    required List<TransactionCategory> categories,
    required double amount,
    required Wallet wallet,
    String? note,
  }) {
    _validateAmount(amount);
    return Transaction._(
      id: id,
      date: DateTime.now(),
      type: TransactionType.expense,
      categories: categories,
      amount: amount,
      wallet: wallet,
      note: note,
    );
  }

  // ── Factory: recurring expense (e.g. WiFi every 1st of the month) ─────────

  factory Transaction.logRecurringExpense({
    required int id,
    required List<TransactionCategory> categories,
    required double amount,
    required Wallet wallet,
    required RecurringConfig recurringConfig,
    String? note,
  }) {
    _validateAmount(amount);
    recurringConfig.validate();
    return Transaction._(
      id: id,
      date: DateTime.now(),
      type: TransactionType.expense,
      categories: categories,
      amount: amount,
      wallet: wallet,
      note: note,
      recurringConfig: recurringConfig,
    );
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  static void _validateAmount(double amount) {
    if (amount <= 0) {
      throw ArgumentError('Transaction amount must be greater than zero.');
    }
  }

  @override
  String toString() => '''
Transaction #$id
  Type       : ${type.name}
  Amount     : ₱${amount.toStringAsFixed(2)}
  Wallet     : ${wallet.name}
  Categories : ${categories.map((c) => c.name).join(', ')}
  Recurring  : ${isRecurring ? recurringConfig.toString() : 'No'}
  Next date  : ${nextOccurrence ?? 'N/A'}
  Note       : ${note ?? '—'}
''';
}