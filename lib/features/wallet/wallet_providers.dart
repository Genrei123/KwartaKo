import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/models/db_models.dart';
import '../../features/cashbook/cashbook_providers.dart';
import '../wallet/wallet_service.dart';

// ---------------------------------------------------------------------------
// CORE PROVIDERS
// ---------------------------------------------------------------------------

/// Wallet service provider
final walletServiceProvider = Provider<WalletService>((ref) {
  return WalletService(repository: ref.watch(appRepositoryProvider));
});

// ---------------------------------------------------------------------------
// DATA PROVIDERS
// ---------------------------------------------------------------------------

/// All active wallets
final walletListProvider = FutureProvider<List<DbWallet>>((ref) {
  return ref.watch(walletServiceProvider).getAllWallets();
});

/// All wallet balances
final walletBalanceMapProvider = FutureProvider<Map<String, double>>((ref) {
  return ref.watch(walletServiceProvider).getAllWalletBalances();
});

/// Per-wallet detail provider (family)
final walletDetailProvider = FutureProvider.family<DbWallet?, String>((ref, walletId) {
  return ref.watch(walletServiceProvider).getWalletById(walletId);
});

/// Per-wallet balance (family)
final walletBalanceProvider = FutureProvider.family<double, String>((ref, walletId) {
  return ref.watch(walletServiceProvider).getWalletBalance(walletId);
});

/// Per-wallet transactions (family)
final walletTransactionsProvider = FutureProvider.family<List<DbTransaction>, String>((ref, walletId) {
  return ref.watch(walletServiceProvider).getWalletTransactions(walletId);
});

/// Per-wallet stats (family)
final walletStatsProvider = FutureProvider.family<WalletStats, String>((ref, walletId) {
  return ref.watch(walletServiceProvider).getWalletStats(walletId);
});

// ---------------------------------------------------------------------------
// INVALIDATION HELPER
// ---------------------------------------------------------------------------

/// Call after wallet mutations to refresh all wallet-related providers
void invalidateWalletProviders(WidgetRef ref) {
  ref.invalidate(walletListProvider);
  ref.invalidate(walletBalanceMapProvider);
  // Also invalidate cashbook providers since they share wallet data
  ref.invalidate(walletsProvider);
  ref.invalidate(walletBalancesProvider);
  ref.invalidate(netWorthProvider);
}
