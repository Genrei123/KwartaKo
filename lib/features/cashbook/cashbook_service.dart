import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import '../../infrastructure/repositories/app_repository.dart';
import '../../infrastructure/models/db_models.dart';

/// Service layer for the Cashbook feature.
/// Wires UI actions to the AppRepository and formula engines.
class CashbookService {
  final AppRepository _repository;

  CashbookService({required AppRepository repository}) : _repository = repository;

  // ---------------------------------------------------------------------------
  // TRANSACTIONS
  // ---------------------------------------------------------------------------

  /// Log an income transaction
  Future<void> logIncome({
    required double amount,
    required String walletId,
    required String categoryId,
    required String bucket,
    String? note,
    DateTime? date,
  }) async {
    final transaction = DbTransaction(
      id: const Uuid().v4(),
      date: (date ?? DateTime.now()).toIso8601String(),
      type: 'income',
      amount: amount,
      walletId: walletId,
      categoryId: categoryId,
      bucket: bucket,
      note: note,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _repository.insertTransaction(transaction);
  }

  /// Log an expense transaction
  Future<void> logExpense({
    required double amount,
    required String walletId,
    required String categoryId,
    required String bucket,
    String? note,
    DateTime? date,
  }) async {
    final transaction = DbTransaction(
      id: const Uuid().v4(),
      date: (date ?? DateTime.now()).toIso8601String(),
      type: 'expense',
      amount: amount,
      walletId: walletId,
      categoryId: categoryId,
      bucket: bucket,
      note: note,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _repository.insertTransaction(transaction);
  }

  /// Log a wallet-to-wallet transfer (net-worth neutral)
  Future<void> logTransfer({
    required double amount,
    required String fromWalletId,
    required String toWalletId,
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

  /// Get recent transactions
  Future<List<DbTransaction>> getRecentTransactions({int limit = 50}) {
    return _repository.getRecentTransactions(limit: limit);
  }

  /// Get transactions for a specific month
  Future<List<DbTransaction>> getTransactionsForMonth(int month, int year) {
    return _repository.getTransactionsForMonth(month, year);
  }

  // ---------------------------------------------------------------------------
  // WALLETS
  // ---------------------------------------------------------------------------

  Future<List<DbWallet>> getAllWallets() => _repository.getAllWallets();
  Future<Map<String, double>> getAllWalletBalances() => _repository.getAllWalletBalances();
  Future<double> getWalletBalance(String walletId) => _repository.getWalletBalance(walletId);

  // ---------------------------------------------------------------------------
  // BUDGET SUMMARY
  // ---------------------------------------------------------------------------

  /// Get the monthly bucket summary (allocated vs spent)
  Future<BucketSummary> getMonthlyBucketSummary(int month, int year) async {
    final profile = await _repository.getUserProfile();
    if (profile == null) {
      return BucketSummary.empty();
    }

    final monthlyIncome = await _repository.getMonthlyIncome(month, year);
    final spending = await _repository.getMonthlyBucketSpending(month, year);
    final totalDebt = await _repository.getTotalActiveDebtPayments();
    final netWorth = await getNetWorth();

    // If no income logged this month, fall back to the user's declared
    // monthly income so that budget buckets are always populated.
    final rawAllocationBase = monthlyIncome > 0 ? monthlyIncome : profile.monthlyIncome;

    // Cap allocation base by actual net worth so we don't allocate money we don't have.
    // If rawAllocationBase is 0 (meaning no income logged this month and profile income is 0),
    // we fall back to the actual positive netWorth so the user can allocate their existing net worth.
    final double allocationBase;
    if (rawAllocationBase > 0) {
      allocationBase = math.min(rawAllocationBase, netWorth > 0 ? netWorth : 0.0);
    } else {
      allocationBase = netWorth > 0 ? netWorth : 0.0;
    }

    // Calculate allocations using normalized ratios so that 100% of the assignable pool is distributed
    final totalNeedsWantsFlex = profile.needsRatio + profile.wantsRatio + profile.flexRatio;
    final needsNormRatio = totalNeedsWantsFlex > 0 ? profile.needsRatio / totalNeedsWantsFlex : 0.0;
    final wantsNormRatio = totalNeedsWantsFlex > 0 ? profile.wantsRatio / totalNeedsWantsFlex : 0.0;
    final flexNormRatio = totalNeedsWantsFlex > 0 ? profile.flexRatio / totalNeedsWantsFlex : 0.0;

    final emergencyAlloc = allocationBase * profile.emergencyRatio;
    final assignable = allocationBase - emergencyAlloc - totalDebt;
    final needsAlloc = assignable > 0 ? assignable * needsNormRatio : 0.0;
    final wantsAlloc = assignable > 0 ? assignable * wantsNormRatio : 0.0;
    final flexAlloc = assignable > 0 ? assignable * flexNormRatio : 0.0;

    return BucketSummary(
      needsAllocated: needsAlloc,
      needsSpent: spending['needs'] ?? 0.0,
      wantsAllocated: wantsAlloc,
      wantsSpent: spending['wants'] ?? 0.0,
      flexAllocated: flexAlloc,
      flexSpent: spending['flex'] ?? 0.0,
      emergencyAllocated: emergencyAlloc,
      emergencySpent: spending['emergency'] ?? 0.0,
    );
  }

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
  // CATEGORIES
  // ---------------------------------------------------------------------------

  Future<List<DbCategory>> getExpenseCategories() => _repository.getCategoriesByType('expense');
  Future<List<DbCategory>> getIncomeCategories() => _repository.getCategoriesByType('income');
  Future<List<DbCategory>> getAllCategories() => _repository.getAllCategories();

  // ---------------------------------------------------------------------------
  // INSTALLMENTS
  // ---------------------------------------------------------------------------

  Future<double> getTotalActiveDebtPayments() => _repository.getTotalActiveDebtPayments();
  Future<List<DbInstallment>> getActiveInstallments() => _repository.getActiveInstallments();

  // ---------------------------------------------------------------------------
  // USER PROFILE
  // ---------------------------------------------------------------------------

  Future<DbUserProfile?> getUserProfile() => _repository.getUserProfile();
  Future<void> updateUserProfile(DbUserProfile profile) => _repository.updateUserProfile(profile);

  /// Automatically process and auto-log recurring income and bills templates if their target day is reached.
  Future<void> processRecurringTransactions() async {
    final templates = await _repository.getRecurringTransactions();
    if (templates.isEmpty) return;

    final now = DateTime.now();
    final currentDay = now.day;
    final currentMonth = now.month;
    final currentYear = now.year;

    // Fetch all normal transactions for the current month to check for duplicates
    final monthlyTxList = await _repository.getTransactionsForMonth(currentMonth, currentYear);

    for (final template in templates) {
      final targetDay = template.recurringDay ?? 1;
      if (currentDay >= targetDay) {
        // Check if a matching transaction already exists for this month/year.
        // We match by amount, type, wallet, category, and matching note pattern.
        final alreadyLogged = monthlyTxList.any((tx) {
          final isSameAmount = tx.amount == template.amount;
          final isSameType = tx.type == template.type;
          final isSameWallet = tx.walletId == template.walletId;
          final isSameCategory = tx.categoryId == template.categoryId;
          
          // Match notes case insensitively
          final cleanTxNote = (tx.note ?? '').trim().toLowerCase();
          final cleanTemplateNote = (template.note ?? '').trim().toLowerCase();
          final isSameNote = cleanTxNote.contains(cleanTemplateNote) || cleanTemplateNote.contains(cleanTxNote);

          return isSameAmount && isSameType && isSameWallet && isSameCategory && isSameNote && tx.isRecurring == 0;
        });

        if (!alreadyLogged) {
          // Auto-log the transaction!
          final targetDate = DateTime(currentYear, currentMonth, targetDay);
          final autoTx = DbTransaction(
            id: const Uuid().v4(),
            date: targetDate.toIso8601String(),
            type: template.type,
            amount: template.amount,
            walletId: template.walletId,
            categoryId: template.categoryId,
            bucket: template.bucket,
            note: '${template.note} (Auto-Logged)',
            isRecurring: 0,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          );

          await _repository.insertTransaction(autoTx);
        }
      }
    }
  }

  Future<List<DbTransaction>> getDueRecurringTransactions() async {
    final templates = await _repository.getRecurringTransactions();
    if (templates.isEmpty) return [];

    final now = DateTime.now();
    final currentDay = now.day;
    final currentMonth = now.month;
    final currentYear = now.year;

    final monthlyTxList = await _repository.getTransactionsForMonth(currentMonth, currentYear);
    final List<DbTransaction> due = [];

    for (final template in templates) {
      final targetDay = template.recurringDay ?? 1;
      if (currentDay >= targetDay) {
        final alreadyLogged = monthlyTxList.any((tx) {
          final isSameAmount = tx.amount == template.amount;
          final isSameType = tx.type == template.type;
          final isSameWallet = tx.walletId == template.walletId;
          final isSameCategory = tx.categoryId == template.categoryId;
          
          final cleanTxNote = (tx.note ?? '').trim().toLowerCase();
          final cleanTemplateNote = (template.note ?? '').trim().toLowerCase();
          final isSameNote = cleanTxNote.contains(cleanTemplateNote) || cleanTemplateNote.contains(cleanTxNote);

          return isSameAmount && isSameType && isSameWallet && isSameCategory && isSameNote && tx.isRecurring == 0;
        });

        if (!alreadyLogged) {
          due.add(template);
        }
      }
    }
    return due;
  }

  Future<void> logRecurringTransaction(DbTransaction template) async {
    final now = DateTime.now();
    final targetDate = DateTime(now.year, now.month, template.recurringDay ?? now.day);
    final tx = DbTransaction(
      id: const Uuid().v4(),
      date: targetDate.toIso8601String(),
      type: template.type,
      amount: template.amount,
      walletId: template.walletId,
      categoryId: template.categoryId,
      bucket: template.bucket,
      note: template.note,
      isRecurring: 0,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _repository.insertTransaction(tx);
  }
}

/// Represents the monthly bucket allocation vs spending summary
class BucketSummary {
  final double needsAllocated;
  final double needsSpent;
  final double wantsAllocated;
  final double wantsSpent;
  final double flexAllocated;
  final double flexSpent;
  final double emergencyAllocated;
  final double emergencySpent;

  const BucketSummary({
    required this.needsAllocated,
    required this.needsSpent,
    required this.wantsAllocated,
    required this.wantsSpent,
    required this.flexAllocated,
    required this.flexSpent,
    required this.emergencyAllocated,
    required this.emergencySpent,
  });

  factory BucketSummary.empty() => const BucketSummary(
        needsAllocated: 0, needsSpent: 0,
        wantsAllocated: 0, wantsSpent: 0,
        flexAllocated: 0, flexSpent: 0,
        emergencyAllocated: 0, emergencySpent: 0,
      );

  double get needsRemaining => (needsAllocated - needsSpent).clamp(0, double.infinity);
  double get wantsRemaining => (wantsAllocated - wantsSpent).clamp(0, double.infinity);
  double get flexRemaining => (flexAllocated - flexSpent).clamp(0, double.infinity);
  double get emergencyRemaining => (emergencyAllocated - emergencySpent).clamp(0, double.infinity);

  double get totalAllocated => needsAllocated + wantsAllocated + flexAllocated + emergencyAllocated;
  double get totalSpent => needsSpent + wantsSpent + flexSpent + emergencySpent;
}
