import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../features/cashbook/cashbook_providers.dart';

class NetWorthBreakdownSheet extends ConsumerWidget {
  const NetWorthBreakdownSheet({super.key});

  Color _parseColor(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return Colors.green.shade400;
    }
  }

  IconData _walletIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('gcash') || lower.contains('maya')) return Icons.phone_android_rounded;
    if (lower.contains('bdo') || lower.contains('bpi') || lower.contains('east') || lower.contains('bank')) {
      return Icons.account_balance_rounded;
    }
    if (lower.contains('cash')) return Icons.payments_rounded;
    return Icons.wallet_rounded;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);
    final balancesAsync = ref.watch(walletBalancesProvider);
    final netWorthAsync = ref.watch(netWorthProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final debtsAsync = ref.watch(totalDebtPaymentsProvider);
    final installmentsAsync = ref.watch(activeInstallmentsProvider);
    final recurringAsync = ref.watch(recurringTransactionsProvider);

    final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1B2D),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade400.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.green.shade400,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Net Worth Breakdown',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Asset Balances & Next Month Forecast',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Wallet Breakdown
                  const Text(
                    'CURRENT WALLET BALANCES',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  walletsAsync.when(
                    data: (wallets) => balancesAsync.when(
                      data: (balances) {
                        if (wallets.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: const Center(
                              child: Text(
                                'No wallets found.',
                                style: TextStyle(color: Colors.white38, fontSize: 13),
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: wallets.map((wallet) {
                            final balance = balances[wallet.id] ?? 0.0;
                            final color = _parseColor(wallet.color);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: color.withOpacity(0.15)),
                              ),
                              child: Row(
                                children: [
                                  Icon(_walletIcon(wallet.name), color: color, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      wallet.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    formatter.format(balance),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Text('Error loading balances', style: TextStyle(color: Colors.red)),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Text('Error loading wallets', style: TextStyle(color: Colors.red)),
                  ),

                  const SizedBox(height: 24),

                  // Section 2: Projections
                  const Text(
                    'NEXT MONTH NET WORTH PROJECTION',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  profileAsync.when(
                    data: (profile) => netWorthAsync.when(
                      data: (netWorth) => debtsAsync.when(
                        data: (debts) => installmentsAsync.when(
                          data: (installments) => recurringAsync.when(
                            data: (recurring) {
                              final monthlyIncome = profile?.monthlyIncome ?? 0.0;
                              final totalDebts = debts;
                              final totalInstallments = installments.fold<double>(0.0, (sum, i) => sum + i.monthlyPayment);
                              final totalRecurringBills = recurring
                                  .where((t) => t.type == 'expense')
                                  .fold<double>(0.0, (sum, t) => sum + t.amount);

                              final projectedNetWorth = netWorth + monthlyIncome - (totalDebts + totalInstallments + totalRecurringBills);

                              return Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.shade900.withOpacity(0.2),
                                      const Color(0xFF16253B),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.green.shade500.withOpacity(0.15)),
                                ),
                                child: Column(
                                  children: [
                                    _buildProjectionRow(
                                      label: 'Current Net Worth',
                                      value: netWorth,
                                      color: Colors.white,
                                      formatter: formatter,
                                    ),
                                    const Divider(color: Colors.white12, height: 20),
                                    _buildProjectionRow(
                                      label: '(+) Projected Income',
                                      value: monthlyIncome,
                                      color: Colors.green.shade400,
                                      formatter: formatter,
                                    ),
                                    const SizedBox(height: 10),
                                    _buildProjectionRow(
                                      label: '(-) Active Debt Payments',
                                      value: -totalDebts,
                                      color: Colors.red.shade400,
                                      formatter: formatter,
                                    ),
                                    const SizedBox(height: 10),
                                    _buildProjectionRow(
                                      label: '(-) Active Installments',
                                      value: -totalInstallments,
                                      color: Colors.red.shade400,
                                      formatter: formatter,
                                    ),
                                    const SizedBox(height: 10),
                                    _buildProjectionRow(
                                      label: '(-) Recurring Bills',
                                      value: -totalRecurringBills,
                                      color: Colors.red.shade400,
                                      formatter: formatter,
                                    ),
                                    const Divider(color: Colors.white12, height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Projected Net Worth',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          formatter.format(projectedNetWorth),
                                          style: TextStyle(
                                            color: projectedNetWorth >= netWorth
                                                ? Colors.green.shade400
                                                : Colors.red.shade400,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (_, __) => const Text('Error loading recurring items'),
                          ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const Text('Error loading installments'),
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const Text('Error loading debts'),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Text('Error loading net worth'),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Text('Error loading profile'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectionRow({
    required String label,
    required double value,
    required Color color,
    required NumberFormat formatter,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          formatter.format(value),
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
