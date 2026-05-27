import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../infrastructure/models/db_models.dart';

class TransactionList extends StatelessWidget {
  final List<DbTransaction> transactions;
  final List<DbCategory> categories;
  final List<DbWallet> wallets;

  const TransactionList({
    super.key,
    required this.transactions,
    required this.categories,
    required this.wallets,
  });

  String _categoryName(String categoryId) {
    final cat = categories.where((c) => c.id == categoryId).firstOrNull;
    return cat?.name ?? 'Other';
  }

  String _walletName(String walletId) {
    final w = wallets.where((w) => w.id == walletId).firstOrNull;
    return w?.name ?? 'Unknown';
  }

  IconData _categoryIcon(String categoryId) {
    final cat = categories.where((c) => c.id == categoryId).firstOrNull;
    final name = cat?.name.toLowerCase() ?? '';

    if (name.contains('salary') || name.contains('freelance')) return Icons.work_rounded;
    if (name.contains('food')) return Icons.restaurant_rounded;
    if (name.contains('transport')) return Icons.directions_bus_rounded;
    if (name.contains('bills')) return Icons.receipt_long_rounded;
    if (name.contains('debt')) return Icons.credit_card_rounded;
    if (name.contains('shopping')) return Icons.shopping_bag_rounded;
    if (name.contains('leisure')) return Icons.sports_esports_rounded;
    if (name.contains('health')) return Icons.favorite_rounded;
    if (name.contains('emergency')) return Icons.shield_rounded;
    if (name.contains('load')) return Icons.phone_android_rounded;
    if (name.contains('interest')) return Icons.trending_up_rounded;
    return Icons.swap_horiz_rounded;
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'income':
        return Colors.green.shade400;
      case 'expense':
        return Colors.red.shade400;
      case 'transfer':
        return Colors.blue.shade400;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final dateFormat = DateFormat('MMM d');
    final timeFormat = DateFormat('h:mm a');

    if (transactions.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.03),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              color: Colors.white.withOpacity(0.15),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No transactions yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + to log your first transaction',
              style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Group transactions by date
    final grouped = <String, List<DbTransaction>>{};
    for (final t in transactions) {
      final dateKey = t.date.substring(0, 10); // YYYY-MM-DD
      grouped.putIfAbsent(dateKey, () => []).add(t);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sortedKeys.map((dateKey) {
          final dayTransactions = grouped[dateKey]!;
          final dateObj = DateTime.tryParse(dateKey) ?? DateTime.now();
          final isToday = DateUtils.isSameDay(dateObj, DateTime.now());
          final isYesterday = DateUtils.isSameDay(
            dateObj,
            DateTime.now().subtract(const Duration(days: 1)),
          );

          final headerText = isToday
              ? 'Today'
              : isYesterday
                  ? 'Yesterday'
                  : dateFormat.format(dateObj);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  headerText,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                ),
                child: Column(
                  children: List.generate(dayTransactions.length, (index) {
                    final t = dayTransactions[index];
                    final isIncome = t.type == 'income';
                    final isTransfer = t.type == 'transfer';
                    final color = _typeColor(t.type);
                    final txTime = DateTime.tryParse(t.date);

                    return Column(
                      children: [
                        if (index > 0)
                          Divider(
                            height: 1,
                            indent: 56,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: color.withOpacity(0.12),
                            ),
                            child: Icon(
                              _categoryIcon(t.categoryId),
                              color: color,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            isTransfer
                                ? 'Transfer'
                                : _categoryName(t.categoryId),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            t.note?.isNotEmpty == true
                                ? '${_walletName(t.walletId)} · ${t.note}'
                                : _walletName(t.walletId),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isIncome ? '+' : isTransfer ? '' : '−'}${formatter.format(t.amount)}',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (txTime != null)
                                Text(
                                  timeFormat.format(txTime),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.25),
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
