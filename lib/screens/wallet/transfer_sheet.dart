import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../features/wallet/wallet_providers.dart';
import '../../features/cashbook/cashbook_providers.dart';
import '../../infrastructure/models/db_models.dart';

class TransferSheet extends ConsumerStatefulWidget {
  final String? preselectedFromWalletId;
  const TransferSheet({super.key, this.preselectedFromWalletId});
  @override
  ConsumerState<TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends ConsumerState<TransferSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _fromId;
  String? _toId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fromId = widget.preselectedFromWalletId;
  }

  @override
  void dispose() { _amountCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

  Future<void> _transfer() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    if (amount <= 0 || _fromId == null || _toId == null || _fromId == _toId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select two different wallets and a valid amount')));
      return;
    }
    setState(() => _saving = true);
    await ref.read(walletServiceProvider).transfer(fromWalletId: _fromId!, toWalletId: _toId!, amount: amount, note: _noteCtrl.text.trim());
    invalidateWalletProviders(ref);
    invalidateCashbookProviders(ref);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletListProvider).value ?? [];
    final balances = ref.watch(walletBalanceMapProvider).value ?? {};
    final fmt = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A2940),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
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
                  const Text('Transfer Money', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Move funds between your wallets', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                  const SizedBox(height: 24),
                  // Amount
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      prefixText: '₱ ',
                      prefixStyle: TextStyle(color: Colors.blue.shade400, fontSize: 32, fontWeight: FontWeight.w700),
                      hintText: '0.00',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 32, fontWeight: FontWeight.w700),
                      border: InputBorder.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // From wallet
                  _lbl('FROM'),
                  const SizedBox(height: 8),
                  _walletPicker(wallets, balances, fmt, _fromId, (id) => setState(() => _fromId = id)),
                  const SizedBox(height: 4),
                  Center(child: Icon(Icons.arrow_downward_rounded, color: Colors.blue.shade400, size: 28)),
                  const SizedBox(height: 4),
                  // To wallet
                  _lbl('TO'),
                  const SizedBox(height: 8),
                  _walletPicker(wallets, balances, fmt, _toId, (id) => setState(() => _toId = id)),
                  const SizedBox(height: 16),
                  // Note
                  TextField(
                    controller: _noteCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Note (optional)',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                      prefixIcon: Icon(Icons.notes_rounded, color: Colors.white.withOpacity(0.3), size: 20),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.shade400.withOpacity(0.5))),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _transfer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade500,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Transfer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _lbl(String t) => Text(t, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2));

  Widget _walletPicker(List<DbWallet> wallets, Map<String, double> balances, NumberFormat fmt, String? selected, ValueChanged<String> onSelect) {
    return SizedBox(
      height: 54,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: wallets.length,
        itemBuilder: (_, i) {
          final w = wallets[i];
          final sel = w.id == selected;
          final bal = balances[w.id] ?? 0.0;
          return GestureDetector(
            onTap: () => onSelect(w.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: sel ? Colors.blue.shade400.withOpacity(0.2) : Colors.white.withOpacity(0.06),
                border: Border.all(color: sel ? Colors.blue.shade400.withOpacity(0.4) : Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(w.name, style: TextStyle(color: sel ? Colors.blue.shade300 : Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(fmt.format(bal), style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
