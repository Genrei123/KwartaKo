import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../infrastructure/models/db_models.dart';
import '../../../features/cashbook/cashbook_providers.dart';
import '../../../features/wallet/wallet_providers.dart';

class TransactionList extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
                        Dismissible(
                          key: Key(t.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: index == 0 && dayTransactions.length == 1
                                  ? BorderRadius.circular(16)
                                  : index == 0
                                      ? const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))
                                      : index == dayTransactions.length - 1
                                          ? const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))
                                          : BorderRadius.zero,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF0F1B2D),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.white.withOpacity(0.08)),
                                ),
                                title: const Text(
                                  'Delete Transaction?',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                content: const Text(
                                  'Are you sure you want to delete this transaction? This will automatically revert the balance in the affected wallet(s).',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade500,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) async {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            try {
                              await ref.read(cashbookServiceProvider).deleteTransaction(t.id);
                              invalidateCashbookProviders(ref);
                              invalidateWalletProviders(ref);
                              
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: const Text('Transaction deleted and wallet balance reverted.'),
                                  backgroundColor: Colors.red.shade600,
                                ),
                              );
                            } catch (e) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Error deleting transaction: $e'),
                                  backgroundColor: Colors.red.shade600,
                                ),
                              );
                            }
                          },
                          child: ListTile(
                            onTap: () => _showDetailsSheet(context, t, ref),
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

  void _showDetailsSheet(BuildContext context, DbTransaction t, WidgetRef ref) {
    final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final isIncome = t.type == 'income';
    final isTransfer = t.type == 'transfer';
    final color = _typeColor(t.type);
    final txTime = DateTime.tryParse(t.date);
    
    final dateStr = txTime != null ? DateFormat('MMMM d, yyyy').format(txTime) : t.date;
    final timeStr = txTime != null ? DateFormat('h:mm a').format(txTime) : '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F1B2D),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: EdgeInsets.only(
          top: 20,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isTransfer ? 'Transfer Details' : isIncome ? 'Income Details' : 'Expense Details',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t.type.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Amount representation
            Center(
              child: Column(
                children: [
                  Text(
                    '${isIncome ? '+' : isTransfer ? '' : '−'}${formatter.format(t.amount)}',
                    style: TextStyle(
                      color: color,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.note?.isNotEmpty == true ? '"${t.note}"' : 'No description',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                      fontStyle: t.note?.isNotEmpty == true ? FontStyle.italic : FontStyle.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Detail items
            _detailRow('Date', dateStr, Icons.calendar_today_rounded),
            if (timeStr.isNotEmpty) _detailRow('Time', timeStr, Icons.access_time_rounded),
            
            if (isTransfer) ...[
              _detailRow('From Wallet', _walletName(t.walletId), Icons.account_balance_wallet_rounded),
              _detailRow('To Wallet', _walletName(t.transferToWallet ?? ''), Icons.account_balance_wallet_rounded),
            ] else ...[
              _detailRow('Wallet', _walletName(t.walletId), Icons.account_balance_wallet_rounded),
              _detailRow('Category', _categoryName(t.categoryId), _categoryIcon(t.categoryId)),
              _detailRow(
                'Budget Bucket',
                t.bucket.toUpperCase(),
                t.bucket == 'emergency' ? Icons.shield_rounded : Icons.pie_chart_rounded,
              ),
            ],
            const SizedBox(height: 32),
            // Delete Action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF0F1B2D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.white.withOpacity(0.08)),
                      ),
                      title: const Text(
                        'Delete Transaction?',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      content: const Text(
                        'Are you sure you want to delete this transaction? This will automatically revert the balance in the affected wallet(s).',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white.withOpacity(0.5)),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade500,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    if (context.mounted) {
                      Navigator.pop(context); // Close details sheet
                    }
                    try {
                      await ref.read(cashbookServiceProvider).deleteTransaction(t.id);
                      invalidateCashbookProviders(ref);
                      invalidateWalletProviders(ref);
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Transaction deleted and wallet balance reverted.'),
                            backgroundColor: Colors.red.shade600,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error deleting transaction: $e'),
                            backgroundColor: Colors.red.shade600,
                          ),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600.withOpacity(0.15),
                  foregroundColor: Colors.red.shade400,
                  elevation: 0,
                  side: BorderSide(color: Colors.red.shade600.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text(
                  'Delete Transaction',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white.withOpacity(0.6),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
