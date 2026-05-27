import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../features/wallet/wallet_providers.dart';
import '../../features/cashbook/cashbook_providers.dart';
import 'widgets/wallet_card.dart';
import 'widgets/wallet_pie_chart.dart';
import 'add_wallet_sheet.dart';
import 'transfer_sheet.dart';
import 'wallet_detail_screen.dart';

class WalletDashboardScreen extends ConsumerWidget {
  const WalletDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletListProvider);
    final balancesAsync = ref.watch(walletBalanceMapProvider);
    final netWorthAsync = ref.watch(netWorthProvider);
    final fmt = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1B2D),
      body: RefreshIndicator(
        onRefresh: () async {
          invalidateWalletProviders(ref);
        },
        color: Colors.green.shade400,
        backgroundColor: const Color(0xFF1A2940),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              backgroundColor: const Color(0xFF0F1B2D),
              floating: true,
              snap: true,
              elevation: 0,
              toolbarHeight: 60,
              automaticallyImplyLeading: true,
              leading: Navigator.canPop(context)
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    )
                  : null,
              title: const Text(
                'My Wallets',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade500.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.swap_horiz_rounded,
                      color: Colors.blue.shade400,
                      size: 20,
                    ),
                  ),
                  tooltip: 'Transfer Money',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const TransferSheet(),
                    );
                  },
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade500.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.green.shade400,
                      size: 20,
                    ),
                  ),
                  tooltip: 'Add Wallet',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const AddWalletSheet(),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Net Worth Summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withOpacity(0.04),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL NET WORTH',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          netWorthAsync.when(
                            data: (nw) => Text(
                              fmt.format(nw),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            loading: () => const SizedBox(
                              height: 30,
                              width: 100,
                              child: Center(
                                child: LinearProgressIndicator(
                                  backgroundColor: Colors.transparent,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            error: (_, __) => Text(
                              '₱0.00',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade400.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance_rounded,
                          color: Colors.green.shade400,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Distribution Pie Chart
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 24),
                child: walletsAsync.when(
                  data: (wallets) => balancesAsync.when(
                    data: (balances) => WalletPieChart(
                      wallets: wallets,
                      balances: balances,
                    ),
                    loading: () => const SizedBox(height: 200),
                    error: (_, __) => const SizedBox(),
                  ),
                  loading: () => const SizedBox(height: 200),
                  error: (_, __) => const SizedBox(),
                ),
              ),
            ),

            // Wallets Grid Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  'INDIVIDUAL BALANCES',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            // Wallets list / grid
            walletsAsync.when(
              data: (wallets) {
                if (wallets.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.04)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 48,
                            color: Colors.white.withOpacity(0.15),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Active Wallets',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Create a wallet to start logging transactions',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const AddWalletSheet(),
                              );
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Wallet'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade500,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final wallet = wallets[index];
                        return balancesAsync.when(
                          data: (balances) {
                            final balance = balances[wallet.id] ?? 0.0;
                            return WalletCard(
                              wallet: wallet,
                              balance: balance,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WalletDetailScreen(walletId: wallet.id),
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (_, __) => Container(
                            decoration: BoxDecoration(
                              color: Colors.red.shade400.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Icon(Icons.error, color: Colors.red.shade300),
                            ),
                          ),
                        );
                      },
                      childCount: wallets.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Error: $err',
                    style: TextStyle(color: Colors.red.shade300),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 40),
            ),
          ],
        ),
      ),
    );
  }
}
