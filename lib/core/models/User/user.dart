// lib/core/models/User/user.dart

import 'package:kwartako/core/models/Budget/budget_allocation.dart';
import 'package:kwartako/core/models/Transaction/transaction.dart';
import 'package:kwartako/core/models/Transaction/transaction_recurring_config.dart';
import 'package:kwartako/core/enums/transaction_category.dart';
import 'package:kwartako/core/models/User/cascade_mode.dart';
import 'package:kwartako/core/models/wallet.dart';

class User {
  final int id;
  String displayName;
  double monthlyIncome;
  CascadeMode cascadeMode;
  String pinHash;

  final BudgetAllocation allocation;
  final List<Wallet> _wallets;
  final List<Transaction> _transactions = [];

  User({
    required this.id,
    required this.displayName,
    required this.monthlyIncome,
    required this.cascadeMode,
    required this.allocation,
    required List<Wallet> wallets,
    this.pinHash = '',
  }) : _wallets = wallets;

  // ── Read-only accessors ────────────────────────────────────────────────────

  List<Transaction> get transactions => List.unmodifiable(_transactions);
  List<Wallet> get wallets => List.unmodifiable(_wallets);

  // Derived — computed from wallet list, not stored separately
  double get netWorth => _wallets.fold(0.0, (sum, w) => sum + w.balance);

  // Convenience filters
  List<Transaction> get recurringTransactions =>
      _transactions.where((t) => t.isRecurring).toList();

  List<Transaction> get incomeTransactions =>
      _transactions.where((t) => t.isIncome).toList();

  List<Transaction> get expenseTransactions =>
      _transactions.where((t) => t.isExpense).toList();

  // ── One-time income ────────────────────────────────────────────────────────

  void receiveIncome({
    required int transactionId,
    required double amount,
    required Wallet targetWallet,
    required List<TransactionCategory> categories,
    String? note,
  }) {
    _assertWalletBelongsToUser(targetWallet);
    final transaction = Transaction.logIncome(
      id: transactionId,
      categories: categories,
      amount: amount,
      wallet: targetWallet,
      note: note,
    );
    targetWallet.deposit(amount);
    _transactions.add(transaction);
  }

  // ── Recurring income (e.g. salary every 15th) ─────────────────────────────

  void receiveRecurringIncome({
    required int transactionId,
    required double amount,
    required Wallet targetWallet,
    required List<TransactionCategory> categories,
    required RecurringConfig recurringConfig,
    String? note,
  }) {
    _assertWalletBelongsToUser(targetWallet);
    final transaction = Transaction.logRecurringIncome(
      id: transactionId,
      categories: categories,
      amount: amount,
      wallet: targetWallet,
      recurringConfig: recurringConfig,
      note: note,
    );
    targetWallet.deposit(amount);
    _transactions.add(transaction);
  }

  // ── One-time expense ───────────────────────────────────────────────────────

  void spendMoney({
    required int transactionId,
    required double amount,
    required Wallet sourceWallet,
    required List<TransactionCategory> categories,
    String? note,
  }) {
    _assertWalletBelongsToUser(sourceWallet);
    _assertSufficientBalance(sourceWallet, amount);
    final transaction = Transaction.logExpense(
      id: transactionId,
      categories: categories,
      amount: amount,
      wallet: sourceWallet,
      note: note,
    );
    sourceWallet.withdraw(amount);
    _transactions.add(transaction);
  }

  // ── Recurring expense (e.g. WiFi every 1st) ───────────────────────────────

  void spendRecurringMoney({
    required int transactionId,
    required double amount,
    required Wallet sourceWallet,
    required List<TransactionCategory> categories,
    required RecurringConfig recurringConfig,
    String? note,
  }) {
    _assertWalletBelongsToUser(sourceWallet);
    _assertSufficientBalance(sourceWallet, amount);
    final transaction = Transaction.logRecurringExpense(
      id: transactionId,
      categories: categories,
      amount: amount,
      wallet: sourceWallet,
      recurringConfig: recurringConfig,
      note: note,
    );
    sourceWallet.withdraw(amount);
    _transactions.add(transaction);
  }

  // ── Wallet management ──────────────────────────────────────────────────────

  void addWallet(Wallet wallet) {
    if (_wallets.any((w) => w.id == wallet.id)) {
      throw StateError('Wallet with id ${wallet.id} already exists.');
    }
    _wallets.add(wallet);
  }

  // ── Filtering helpers ──────────────────────────────────────────────────────

  List<Transaction> transactionsByCategory(TransactionCategory category) =>
      _transactions.where((t) => t.categories.contains(category)).toList();

  List<Transaction> recurringFiresIn(DateTime from, DateTime to) =>
      _transactions
          .where((t) => t.isRecurring)
          .where(
            (t) =>
                t.recurringConfig!.allOccurrencesBetween(from, to).isNotEmpty,
          )
          .toList();

  // ── Guards ─────────────────────────────────────────────────────────────────

  void _assertWalletBelongsToUser(Wallet wallet) {
    if (!_wallets.any((w) => w.id == wallet.id)) {
      throw ArgumentError(
        'Wallet "${wallet.name}" does not belong to user "$displayName".',
      );
    }
  }

  void _assertSufficientBalance(Wallet wallet, double amount) {
    if (wallet.balance < amount) {
      throw StateError(
        'Insufficient balance in "${wallet.name}". '
        'Available: ₱${wallet.balance.toStringAsFixed(2)}, '
        'Required: ₱${amount.toStringAsFixed(2)}.',
      );
    }
  }

  // ── Display ────────────────────────────────────────────────────────────────

  @override
  String toString() =>
      '''
User #$id — $displayName
  Monthly income : ₱${monthlyIncome.toStringAsFixed(2)}
  Net worth      : ₱${netWorth.toStringAsFixed(2)}
  Cascade mode   : ${cascadeMode.name}
  PIN            : ${pinHash.isNotEmpty ? 'Set' : 'Not set'}
  Wallets        : ${_wallets.map((w) => '${w.name} (₱${w.balance.toStringAsFixed(2)})').join(', ')}
  Transactions   : ${_transactions.length} total (${recurringTransactions.length} recurring)
''';
}
