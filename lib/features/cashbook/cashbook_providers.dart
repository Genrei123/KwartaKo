import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/repositories/app_repository.dart';
import '../../infrastructure/models/db_models.dart';
import '../cashbook/cashbook_service.dart';

import '../dashboard/dashboard_providers.dart';

// ---------------------------------------------------------------------------
// CORE PROVIDERS
// ---------------------------------------------------------------------------

/// Navigation active tab provider
class CurrentTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

final currentTabProvider = NotifierProvider<CurrentTabNotifier, int>(CurrentTabNotifier.new);

/// Singleton repository provider
final appRepositoryProvider = Provider<AppRepository>((ref) {
  return AppRepository();
});

/// Cashbook service provider
final cashbookServiceProvider = Provider<CashbookService>((ref) {
  return CashbookService(repository: ref.watch(appRepositoryProvider));
});

// ---------------------------------------------------------------------------
// DATA PROVIDERS — auto-refresh on invalidation
// ---------------------------------------------------------------------------

/// User profile
final userProfileProvider = FutureProvider<DbUserProfile?>((ref) {
  return ref.watch(cashbookServiceProvider).getUserProfile();
});

/// All wallets
final walletsProvider = FutureProvider<List<DbWallet>>((ref) {
  return ref.watch(cashbookServiceProvider).getAllWallets();
});

/// Wallet balances (walletId → balance)
final walletBalancesProvider = FutureProvider<Map<String, double>>((ref) {
  return ref.watch(cashbookServiceProvider).getAllWalletBalances();
});

/// Net worth (sum of all wallet balances)
final netWorthProvider = FutureProvider<double>((ref) {
  return ref.watch(cashbookServiceProvider).getNetWorth();
});

/// Recent transactions
final recentTransactionsProvider = FutureProvider<List<DbTransaction>>((ref) {
  return ref.watch(cashbookServiceProvider).getRecentTransactions(limit: 30);
});

/// Monthly bucket summary for the current month
final monthlyBucketSummaryProvider = FutureProvider<BucketSummary>((ref) {
  final now = DateTime.now();
  return ref.watch(cashbookServiceProvider).getMonthlyBucketSummary(now.month, now.year);
});

/// Expense categories
final expenseCategoriesProvider = FutureProvider<List<DbCategory>>((ref) async {
  final service = ref.watch(cashbookServiceProvider);
  var list = await service.getExpenseCategories();
  if (list.isEmpty) {
    await ref.read(appRepositoryProvider).seedDefaultCategories();
    list = await service.getExpenseCategories();
  }
  return list;
});

/// Income categories
final incomeCategoriesProvider = FutureProvider<List<DbCategory>>((ref) async {
  final service = ref.watch(cashbookServiceProvider);
  var list = await service.getIncomeCategories();
  if (list.isEmpty) {
    await ref.read(appRepositoryProvider).seedDefaultCategories();
    list = await service.getIncomeCategories();
  }
  return list;
});

/// Active installments
final activeInstallmentsProvider = FutureProvider<List<DbInstallment>>((ref) {
  return ref.watch(cashbookServiceProvider).getActiveInstallments();
});

/// Total active debt payments
final totalDebtPaymentsProvider = FutureProvider<double>((ref) {
  return ref.watch(cashbookServiceProvider).getTotalActiveDebtPayments();
});

/// All recurring transaction templates
final recurringTransactionsProvider = FutureProvider<List<DbTransaction>>((ref) {
  return ref.watch(appRepositoryProvider).getRecurringTransactions();
});

/// Pending/due recurring transactions
final dueRecurringTransactionsProvider = FutureProvider<List<DbTransaction>>((ref) {
  return ref.watch(cashbookServiceProvider).getDueRecurringTransactions();
});

// ---------------------------------------------------------------------------
// INVALIDATION HELPER
// ---------------------------------------------------------------------------

/// Call this after any transaction to refresh all dependent providers
void invalidateCashbookProviders(WidgetRef ref) {
  ref.invalidate(userProfileProvider);
  ref.invalidate(recentTransactionsProvider);
  ref.invalidate(walletBalancesProvider);
  ref.invalidate(netWorthProvider);
  ref.invalidate(monthlyBucketSummaryProvider);
  ref.invalidate(dueRecurringTransactionsProvider);
  invalidateDashboardProviders(ref);
}

