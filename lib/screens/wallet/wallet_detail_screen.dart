import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../features/wallet/wallet_providers.dart';
import '../../features/cashbook/cashbook_providers.dart';
import '../../infrastructure/models/db_models.dart';
import '../cashbook/widgets/transaction_list.dart';

class WalletDetailScreen extends ConsumerWidget {
  final String walletId;

  const WalletDetailScreen({Key? key, required this.walletId}) : super(key: key);

  Color _parseColor(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return Colors.green.shade400;
    }
  }

  void _showEditWalletSheet(BuildContext context, WidgetRef ref, DbWallet wallet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditWalletSheet(wallet: wallet),
    );
  }

  void _confirmArchive(BuildContext context, WidgetRef ref, DbWallet wallet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2940),
        title: const Text(
          'Archive Wallet?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to archive "${wallet.name}"? Transactions associated with this wallet will remain in your records, but the wallet will no longer show in active balances.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await ref.read(walletServiceProvider).archiveWallet(wallet.id);
              invalidateWalletProviders(ref);
              invalidateCashbookProviders(ref);
              if (context.mounted) {
                Navigator.of(ctx).pop(); // Dismiss dialog
                Navigator.of(context).pop(); // Go back from detail screen
              }
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletDetailProvider(walletId));
    final balanceAsync = ref.watch(walletBalanceProvider(walletId));
    final transactionsAsync = ref.watch(walletTransactionsProvider(walletId));
    final statsAsync = ref.watch(walletStatsProvider(walletId));
    final allCategories = ref.watch(expenseCategoriesProvider).value ?? [];
    final incomeCategories = ref.watch(incomeCategoriesProvider).value ?? [];
    final allCats = [...allCategories, ...incomeCategories];
    final wallets = ref.watch(walletListProvider).value ?? [];

    final fmt = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return walletAsync.when(
      data: (wallet) {
        if (wallet == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F1B2D),
            body: Center(child: Text('Wallet not found', style: TextStyle(color: Colors.white))),
          );
        }

        final walletColor = _parseColor(wallet.color);

        return Scaffold(
          backgroundColor: const Color(0xFF0F1B2D),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(walletDetailProvider(walletId));
              ref.invalidate(walletBalanceProvider(walletId));
              ref.invalidate(walletTransactionsProvider(walletId));
              ref.invalidate(walletStatsProvider(walletId));
            },
            color: walletColor,
            backgroundColor: const Color(0xFF1A2940),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // Curved header with back button, details, and edit/archive popup
                SliverAppBar(
                  expandedHeight: 180.0,
                  backgroundColor: walletColor.withOpacity(0.1),
                  elevation: 0,
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  actions: [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                      color: const Color(0xFF1A2940),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val == 'edit') {
                          _showEditWalletSheet(context, ref, wallet);
                        } else if (val == 'archive') {
                          _confirmArchive(context, ref, wallet);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 10),
                              Text('Edit Wallet', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(Icons.archive_outlined, color: Colors.red.shade400, size: 18),
                              const SizedBox(width: 10),
                              Text('Archive', style: TextStyle(color: Colors.red.shade400)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Text(
                      wallet.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            walletColor.withOpacity(0.3),
                            const Color(0xFF0F1B2D),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            balanceAsync.when(
                              data: (bal) => Text(
                                fmt.format(bal),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              loading: () => const CircularProgressIndicator(),
                              error: (_, __) => const Text('₱0.00', style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Current Balance',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Stats / Info Cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: statsAsync.when(
                      data: (stats) => Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Total In',
                              value: fmt.format(stats.totalIncome),
                              color: Colors.green.shade400,
                              icon: Icons.arrow_upward_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Total Out',
                              value: fmt.format(stats.totalExpense),
                              color: Colors.red.shade400,
                              icon: Icons.arrow_downward_rounded,
                            ),
                          ),
                        ],
                      ),
                      loading: () => const SizedBox(height: 60),
                      error: (_, __) => const SizedBox(),
                    ),
                  ),
                ),

                // Transaction list header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      'TRANSACTION HISTORY',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),

                // Transaction list specific to this wallet
                transactionsAsync.when(
                  data: (txns) => SliverPadding(
                    padding: const EdgeInsets.only(bottom: 40),
                    sliver: SliverToBoxAdapter(
                      child: TransactionList(
                        transactions: txns,
                        categories: allCats,
                        wallets: wallets,
                      ),
                    ),
                  ),
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => SliverFillRemaining(
                    child: Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0F1B2D),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: const Color(0xFF0F1B2D),
        body: Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EditWalletSheet extends ConsumerStatefulWidget {
  final DbWallet wallet;

  const _EditWalletSheet({required this.wallet});

  @override
  ConsumerState<_EditWalletSheet> createState() => _EditWalletSheetState();
}

class _EditWalletSheetState extends ConsumerState<_EditWalletSheet> {
  final _nameCtrl = TextEditingController();
  final _balCtrl = TextEditingController();
  late String _color;
  bool _saving = false;

  static const _colors = [
    '4CAF50', '2196F3', '9C27B0', 'FF9800', 'F44336',
    '00BCD4', 'E91E63', '607D8B', 'FF5722', '3F51B5',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.wallet.name;
    _balCtrl.text = widget.wallet.startingBalance.toStringAsFixed(2);
    _color = widget.wallet.color;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balCtrl.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a name')));
      return;
    }
    setState(() => _saving = true);
    await ref.read(walletServiceProvider).updateWallet(
      id: widget.wallet.id,
      name: name,
      color: _color,
      startingBalance: double.tryParse(_balCtrl.text.trim()) ?? widget.wallet.startingBalance,
      isArchived: widget.wallet.isArchived,
      createdAt: widget.wallet.createdAt,
    );
    invalidateWalletProviders(ref);
    invalidateCashbookProviders(ref);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A2940),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Edit Wallet',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            _label('WALLET NAME'),
            const SizedBox(height: 8),
            _field(_nameCtrl, 'e.g. GCash, BDO Savings', Icons.wallet_rounded),
            const SizedBox(height: 20),
            _label('STARTING BALANCE'),
            const SizedBox(height: 8),
            TextField(
              controller: _balCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                prefixText: '₱ ',
                prefixStyle: TextStyle(color: Colors.green.shade400, fontSize: 16),
                hintText: '0.00',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.green.shade400, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
            const SizedBox(height: 20),
            _label('COLOR TAG'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colors.map((hex) {
                final c = Color(int.parse('FF$hex', radix: 16));
                final sel = _color == hex;
                return GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c,
                      border: Border.all(color: sel ? Colors.white : Colors.transparent, width: 2.5),
                      boxShadow: sel ? [BoxShadow(color: c.withOpacity(0.4), blurRadius: 12, spreadRadius: 1)] : [],
                    ),
                    child: sel ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _update,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade500,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Text(
        t,
        style: TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );

  Widget _field(TextEditingController c, String hint, IconData icon) => TextField(
        controller: c,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          prefixIcon: Icon(icon, color: Colors.green.shade400, size: 20),
          filled: true,
          fillColor: Colors.white.withOpacity(0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.green.shade400, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      );
}
