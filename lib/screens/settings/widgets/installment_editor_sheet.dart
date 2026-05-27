import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../features/cashbook/cashbook_providers.dart';
import '../../../infrastructure/models/db_models.dart';

class InstallmentEditorSheet extends ConsumerStatefulWidget {
  final DbInstallment? installment;
  final VoidCallback? onSaved;

  const InstallmentEditorSheet({
    Key? key,
    this.installment,
    this.onSaved,
  }) : super(key: key);

  @override
  ConsumerState<InstallmentEditorSheet> createState() => _InstallmentEditorSheetState();
}

class _InstallmentEditorSheetState extends ConsumerState<InstallmentEditorSheet> {
  final _nameCtrl = TextEditingController();
  final _totalAmountCtrl = TextEditingController();
  final _monthlyPaymentCtrl = TextEditingController();
  final _monthsTotalCtrl = TextEditingController();
  final _monthsRemainingCtrl = TextEditingController();
  String? _selectedWalletId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.installment != null) {
      _nameCtrl.text = widget.installment!.name;
      _totalAmountCtrl.text = widget.installment!.totalAmount.toStringAsFixed(2);
      _monthlyPaymentCtrl.text = widget.installment!.monthlyPayment.toStringAsFixed(2);
      _monthsTotalCtrl.text = widget.installment!.monthsTotal.toString();
      _monthsRemainingCtrl.text = widget.installment!.monthsRemaining.toString();
      _selectedWalletId = widget.installment!.walletId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _totalAmountCtrl.dispose();
    _monthlyPaymentCtrl.dispose();
    _monthsTotalCtrl.dispose();
    _monthsRemainingCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final totalAmount = double.tryParse(_totalAmountCtrl.text.trim()) ?? 0.0;
    final monthlyPayment = double.tryParse(_monthlyPaymentCtrl.text.trim()) ?? 0.0;
    final monthsTotal = int.tryParse(_monthsTotalCtrl.text.trim()) ?? 0;
    final monthsRemaining = int.tryParse(_monthsRemainingCtrl.text.trim()) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a name for the installment')),
      );
      return;
    }
    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid total amount')),
      );
      return;
    }
    if (monthlyPayment <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid monthly payment')),
      );
      return;
    }
    if (monthsTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid total months')),
      );
      return;
    }
    if (monthsRemaining < 0 || monthsRemaining > monthsTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remaining months must be between 0 and total months')),
      );
      return;
    }
    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment wallet')),
      );
      return;
    }

    setState(() => _saving = true);

    final repo = ref.read(appRepositoryProvider);
    final id = widget.installment?.id ?? const Uuid().v4();
    final installment = DbInstallment(
      id: id,
      name: name,
      totalAmount: totalAmount,
      monthlyPayment: monthlyPayment,
      monthsTotal: monthsTotal,
      monthsRemaining: monthsRemaining,
      startDate: widget.installment?.startDate ?? DateTime.now().millisecondsSinceEpoch,
      walletId: _selectedWalletId!,
      isActive: monthsRemaining > 0 ? 1 : 0,
    );

    if (widget.installment != null) {
      await repo.updateInstallment(installment);
    } else {
      await repo.insertInstallment(installment);
    }

    ref.invalidate(activeInstallmentsProvider);
    ref.invalidate(totalDebtPaymentsProvider);
    ref.invalidate(monthlyBucketSummaryProvider);
    if (widget.onSaved != null) widget.onSaved!();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (widget.installment == null) return;
    setState(() => _saving = true);

    final repo = ref.read(appRepositoryProvider);
    final installment = DbInstallment(
      id: widget.installment!.id,
      name: widget.installment!.name,
      totalAmount: widget.installment!.totalAmount,
      monthlyPayment: widget.installment!.monthlyPayment,
      monthsTotal: widget.installment!.monthsTotal,
      monthsRemaining: widget.installment!.monthsRemaining,
      startDate: widget.installment!.startDate,
      walletId: widget.installment!.walletId,
      isActive: 0, // Soft delete/archive
    );

    await repo.updateInstallment(installment);
    ref.invalidate(activeInstallmentsProvider);
    ref.invalidate(totalDebtPaymentsProvider);
    ref.invalidate(monthlyBucketSummaryProvider);
    if (widget.onSaved != null) widget.onSaved!();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF162235),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
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
                  Text(
                    widget.installment != null ? 'Edit Installment' : 'Add Installment Debt',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.installment != null
                        ? 'Update this active installment contract details'
                        : 'Simulate or log a current active installment plan',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _label('INSTALLMENT NAME / CONVERTER'),
                  const SizedBox(height: 8),
                  _field(_nameCtrl, 'e.g. Home Credit iPhone, Car Loan', Icons.payment_rounded),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('TOTAL AMOUNT'),
                            const SizedBox(height: 8),
                            _numericField(_totalAmountCtrl, '0.00'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('MONTHLY PAYMENT'),
                            const SizedBox(height: 8),
                            _numericField(_monthlyPaymentCtrl, '0.00'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('TOTAL MONTHS'),
                            const SizedBox(height: 8),
                            _integerField(_monthsTotalCtrl, 'e.g. 12'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('MONTHS REMAINING'),
                            const SizedBox(height: 8),
                            _integerField(_monthsRemainingCtrl, 'e.g. 8'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _label('PAYMENT WALLET'),
                  const SizedBox(height: 8),
                  walletsAsync.when(
                    data: (wallets) {
                      if (_selectedWalletId == null && wallets.isNotEmpty) {
                        _selectedWalletId = wallets.first.id;
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: const Color(0xFF162235),
                            value: _selectedWalletId,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
                            items: wallets.map((wallet) {
                              return DropdownMenuItem<String>(
                                value: wallet.id,
                                child: Text(
                                  wallet.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 15),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedWalletId = val),
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Text('Failed to load wallets'),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      if (widget.installment != null) ...[
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _saving ? null : _delete,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.red.shade400.withOpacity(0.5)),
                                foregroundColor: Colors.red.shade400,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Delete / Clear'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade500,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Text(
                                    widget.installment != null ? 'Update Plan' : 'Create Plan',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

  Widget _numericField(TextEditingController c, String hint) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          prefixText: '₱ ',
          prefixStyle: TextStyle(color: Colors.green.shade400, fontSize: 16),
          hintText: hint,
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
      );

  Widget _integerField(TextEditingController c, String hint) => TextField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
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
      );
}
