import 'package:uuid/uuid.dart';
import '../../infrastructure/repositories/app_repository.dart';
import '../../infrastructure/models/db_models.dart';

/// Service layer for the Wallet feature.
/// Handles wallet creation, editing, archiving, transfers, and per-wallet queries.
class WalletService {
  final AppRepository _repository;

  WalletService({required AppRepository repository}) : _repository = repository;

  // ---------------------------------------------------------------------------
  // WALLET CRUD
  // ---------------------------------------------------------------------------

  Future<List<DbWallet>> getAllWallets() => _repository.getAllWallets();

  Future<DbWallet?> getWalletById(String id) => _repository.getWalletById(id);

  Future<void> createWallet({
    required String name,
    required double startingBalance,
    required String color,
  }) async {
    final wallet = DbWallet(
      id: const Uuid().v4(),
      name: name,
      startingBalance: startingBalance,
      color: color,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _repository.insertWallet(wallet);
  }

  Future<void> updateWallet({
    required String id,
    required String name,
    required String color,
    required double startingBalance,
    required int isArchived,
    required int createdAt,
  }) async {
    await _repository.updateWallet(DbWallet(
      id: id,
      name: name,
      startingBalance: startingBalance,
      color: color,
      isArchived: isArchived,
      createdAt: createdAt,
    ));
  }

  Future<void> archiveWallet(String walletId) => _repository.archiveWallet(walletId);

  // ---------------------------------------------------------------------------
  // BALANCES
  // ---------------------------------------------------------------------------

  Future<double> getWalletBalance(String walletId) => _repository.getWalletBalance(walletId);
  Future<Map<String, double>> getAllWalletBalances() => _repository.getAllWalletBalances();

  /// Get net worth (sum of all wallet balances)
  Future<double> getNetWorth() async {
    final balances = await _repository.getAllWalletBalances();
    double total = 0.0;
    for (final b in balances.values) {
      total += b;
    }
    return total;
  }

  // ---------------------------------------------------------------------------
  // TRANSFERS
  // ---------------------------------------------------------------------------

  /// Transfer money between wallets (creates a transfer transaction)
  Future<void> transfer({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    String? note,
  }) async {
    final transaction = DbTransaction(
      id: const Uuid().v4(),
      date: DateTime.now().toIso8601String(),
      type: 'transfer',
      amount: amount,
      walletId: fromWalletId,
      categoryId: 'transfer',
      bucket: 'unallocated',
      note: note ?? 'Wallet transfer',
      transferToWallet: toWalletId,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _repository.insertTransaction(transaction);
  }

  // ---------------------------------------------------------------------------
  // PER-WALLET TRANSACTIONS
  // ---------------------------------------------------------------------------

  Future<List<DbTransaction>> getWalletTransactions(String walletId, {int limit = 100}) {
    return _repository.getTransactionsForWallet(walletId, limit: limit);
  }

  // ---------------------------------------------------------------------------
  // WALLET STATS
  // ---------------------------------------------------------------------------

  /// Get income vs expense breakdown for a wallet
  Future<WalletStats> getWalletStats(String walletId) async {
    final transactions = await _repository.getTransactionsForWallet(walletId);
    double totalIncome = 0.0;
    double totalExpense = 0.0;
    int transactionCount = 0;

    for (final t in transactions) {
      if (t.walletId == walletId) {
        if (t.type == 'income') {
          totalIncome += t.amount;
        } else if (t.type == 'expense') {
          totalExpense += t.amount;
        }
        transactionCount++;
      }
    }

    return WalletStats(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      transactionCount: transactionCount,
    );
  }
}

/// Stats summary for a single wallet
class WalletStats {
  final double totalIncome;
  final double totalExpense;
  final int transactionCount;

  const WalletStats({
    required this.totalIncome,
    required this.totalExpense,
    required this.transactionCount,
  });

  double get netFlow => totalIncome - totalExpense;
}
