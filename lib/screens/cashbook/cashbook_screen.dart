import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/cashbook/cashbook_providers.dart';
import '../wallet/wallet_dashboard_screen.dart';
import 'widgets/net_worth_header.dart';
import 'widgets/wallet_chips.dart';
import 'widgets/bucket_summary_card.dart';
import 'widgets/transaction_list.dart';
import 'widgets/net_worth_breakdown_sheet.dart';
import 'widgets/budget_breakdown_sheet.dart';
import 'widgets/recurring_confirmation_sheet.dart';


class CashbookScreen extends ConsumerWidget {
  const CashbookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netWorth = ref.watch(netWorthProvider);
    final wallets = ref.watch(walletsProvider);
    final balances = ref.watch(walletBalancesProvider);
    final bucketSummary = ref.watch(monthlyBucketSummaryProvider);
    final transactions = ref.watch(recentTransactionsProvider);
    final allCategories = ref.watch(expenseCategoriesProvider);
    final incomeCategories = ref.watch(incomeCategoriesProvider);
    final dueRecurring = ref.watch(dueRecurringTransactionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1B2D),
      body: RefreshIndicator(
        onRefresh: () async {
          invalidateCashbookProviders(ref);
        },
        color: Colors.green.shade400,
        backgroundColor: const Color(0xFF1A2940),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // App bar
            SliverAppBar(
              backgroundColor: const Color(0xFF0F1B2D),
              floating: true,
              snap: true,
              elevation: 0,
              toolbarHeight: 60,
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade400,
                          Colors.green.shade700,
                        ],
                      ),
                    ),
                    child: const Icon(Icons.savings_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                     'KwartaKo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              actions: [
                dueRecurring.when(
                  data: (dueList) {
                    final count = dueList.length;
                    return Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.notifications_outlined,
                            color: count > 0 ? Colors.green.shade400 : Colors.white.withOpacity(0.5),
                            size: 22,
                          ),
                          onPressed: () {
                            if (count > 0) {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => RecurringConfirmationSheet(dueTransactions: dueList),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No pending notifications. You are all caught up!'),
                                  backgroundColor: Color(0xFF1E2D4A),
                                ),
                              );
                            }
                          },
                        ),
                        if (count > 0)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: Colors.white.withOpacity(0.5),
                      size: 22,
                    ),
                    onPressed: null,
                  ),
                  error: (_, __) => IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: Colors.white.withOpacity(0.5),
                      size: 22,
                    ),
                    onPressed: null,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),

            // Content
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ── Net Worth Header ──────────────────────────────────
                  netWorth.when(
                    data: (nw) => NetWorthHeader(
                      netWorth: nw,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const NetWorthBreakdownSheet(),
                        );
                      },
                    ),
                    loading: () => const _ShimmerCard(height: 140),
                    error: (_, __) => const _ErrorCard(message: 'Failed to load net worth'),
                  ),

                  const SizedBox(height: 20),

                  // ── Wallet Chips ──────────────────────────────────────
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WalletDashboardScreen(),
                        ),
                      );
                    },
                    child: _SectionTitle(
                      title: 'WALLETS',
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WalletDashboardScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'See all',
                          style: TextStyle(
                            color: Colors.green.shade400,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  wallets.when(
                    data: (w) => balances.when(
                      data: (b) => WalletChips(wallets: w, balances: b),
                      loading: () => const _ShimmerCard(height: 90),
                      error: (_, __) => WalletChips(wallets: w, balances: const {}),
                    ),
                    loading: () => const _ShimmerCard(height: 90),
                    error: (_, __) => const _ErrorCard(message: 'Failed to load wallets'),
                  ),

                  const SizedBox(height: 24),

                  // ── Budget Summary ────────────────────────────────────
                  const _SectionTitle(title: 'MONTHLY BUDGET'),
                  const SizedBox(height: 8),
                  bucketSummary.when(
                    data: (summary) => BucketSummaryCard(
                      summary: summary,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const BudgetBreakdownSheet(),
                        );
                      },
                    ),
                    loading: () => const _ShimmerCard(height: 200),
                    error: (_, __) => const _ErrorCard(message: 'Failed to load budget'),
                  ),

                  const SizedBox(height: 24),

                  // ── Transactions ──────────────────────────────────────
                  const _SectionTitle(title: 'RECENT TRANSACTIONS'),
                  const SizedBox(height: 4),
                  transactions.when(
                    data: (txns) {
                      // Merge income + expense categories
                      final expCats = allCategories.value ?? [];
                      final incCats = incomeCategories.value ?? [];
                      final allCats = [...expCats, ...incCats];

                      return TransactionList(
                        transactions: txns,
                        categories: allCats,
                        wallets: wallets.value ?? [],
                      );
                    },
                    loading: () => const _ShimmerCard(height: 200),
                    error: (_, __) => const _ErrorCard(message: 'Failed to load transactions'),
                  ),

                  const SizedBox(height: 100), // Bottom padding for FAB
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper Widgets ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionTitle({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final double height;

  const _ShimmerCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.04),
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.green.shade400.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.red.shade400.withOpacity(0.08),
        border: Border.all(color: Colors.red.shade400.withOpacity(0.15)),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.red.shade300, fontSize: 13),
        ),
      ),
    );
  }
}
