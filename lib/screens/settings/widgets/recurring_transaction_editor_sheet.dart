import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../features/cashbook/cashbook_providers.dart';
import '../../../infrastructure/models/db_models.dart';

class RecurringTransactionEditorSheet extends ConsumerStatefulWidget {
  final DbTransaction? template;
  final VoidCallback? onSaved;

  const RecurringTransactionEditorSheet({
    Key? key,
    this.template,
    this.onSaved,
  }) : super(key: key);

  @override
  ConsumerState<RecurringTransactionEditorSheet> createState() => _RecurringTransactionEditorSheetState();
}

class _RecurringTransactionEditorSheetState extends ConsumerState<RecurringTransactionEditorSheet> {
  final _noteCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _dayCtrl = TextEditingController();
  String _selectedType = 'expense';
  String? _selectedWalletId;
  String? _selectedCategoryId;
  String _selectedBucket = 'needs';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _noteCtrl.text = widget.template!.note ?? '';
      _amountCtrl.text = widget.template!.amount.toStringAsFixed(2);
      _dayCtrl.text = widget.template!.recurringDay?.toString() ?? '1';
      _selectedType = widget.template!.type;
      _selectedWalletId = widget.template!.walletId;
      _selectedCategoryId = widget.template!.categoryId;
      _selectedBucket = widget.template!.bucket;
    } else {
      _dayCtrl.text = '1';
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _amountCtrl.dispose();
    _dayCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final note = _noteCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    final day = int.tryParse(_dayCtrl.text.trim()) ?? 1;

    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a name or note for this recurring entry')),
      );
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    if (day < 1 || day > 31) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid day of the month (1-31)')),
      );
      return;
    }
    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a wallet')),
      );
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _saving = true);

    final repo = ref.read(appRepositoryProvider);
    final id = widget.template?.id ?? const Uuid().v4();
    final transaction = DbTransaction(
      id: id,
      date: DateTime.now().toIso8601String(),
      type: _selectedType,
      amount: amount,
      walletId: _selectedWalletId!,
      categoryId: _selectedCategoryId!,
      bucket: _selectedBucket,
      note: note,
      isRecurring: 1,
      recurringDay: day,
      createdAt: widget.template?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
    );

    if (widget.template != null) {
      // In SQLite delete first then insert, or update. Let's delete the old and insert the updated template to avoid conflicts.
      await repo.deleteTransaction(widget.template!.id);
    }
    await repo.insertTransaction(transaction);

    ref.invalidate(recurringTransactionsProvider);
    ref.invalidate(monthlyBucketSummaryProvider);
    if (widget.onSaved != null) widget.onSaved!();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (widget.template == null) return;
    setState(() => _saving = true);

    final repo = ref.read(appRepositoryProvider);
    await repo.deleteTransaction(widget.template!.id);

    ref.invalidate(recurringTransactionsProvider);
    ref.invalidate(monthlyBucketSummaryProvider);
    if (widget.onSaved != null) widget.onSaved!();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider);
    final expenseCategoriesAsync = ref.watch(expenseCategoriesProvider);
    final incomeCategoriesAsync = ref.watch(incomeCategoriesProvider);

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
                    widget.template != null ? 'Edit Recurring Template' : 'Add Recurring Salary / Bill',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.template != null
                        ? 'Update details of your recurring template'
                        : 'Set up auto-logged transactions such as Salary or Monthly Netflix/Rent bills',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _label('TYPE'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _typeButton('income', 'Income / Salary', Colors.green),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _typeButton('expense', 'Expense / Bill', Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _label('NAME / NOTE'),
                  const SizedBox(height: 8),
                  _field(_noteCtrl, 'e.g. Monthly Salary, House Rent, Netflix', Icons.description_rounded),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('AMOUNT'),
                            const SizedBox(height: 8),
                            _numericField(_amountCtrl, '0.00'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('DAY OF MONTH (1-31)'),
                            const SizedBox(height: 8),
                            _integerField(_dayCtrl, 'e.g. 15'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _label('WALLET'),
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
                  const SizedBox(height: 16),

                  _label('CATEGORY'),
                  const SizedBox(height: 8),
                  (_selectedType == 'expense' ? expenseCategoriesAsync : incomeCategoriesAsync).when(
                    data: (categories) {
                      if (categories.isNotEmpty) {
                        if (_selectedCategoryId == null || !categories.any((c) => c.id == _selectedCategoryId)) {
                          _selectedCategoryId = categories.first.id;
                        }
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
                            value: _selectedCategoryId,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
                            items: categories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat.id,
                                child: Text(
                                  cat.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 15),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedCategoryId = val),
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Text('Failed to load categories'),
                  ),
                  const SizedBox(height: 16),

                  _label('BUDGET BUCKET'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: const Color(0xFF162235),
                        value: _selectedBucket,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: 'needs', child: Text('Needs (60% standard)', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'wants', child: Text('Wants (20% standard)', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'flex', child: Text('Flex (10% standard)', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'emergency', child: Text('Emergency (10% standard)', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'unallocated', child: Text('Unallocated / Off-budget', style: TextStyle(color: Colors.white))),
                        ],
                        onChanged: (val) => setState(() => _selectedBucket = val ?? 'needs'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      if (widget.template != null) ...[
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
                              child: const Text('Delete'),
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
                                    widget.template != null ? 'Update Template' : 'Create Template',
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

  Widget _typeButton(String type, String label, MaterialColor activeColor) {
    final active = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedType = type;
        _selectedCategoryId = null; // Reset category selection to match the new type
      }),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: active ? activeColor.shade500.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: active ? activeColor.shade400 : Colors.white.withOpacity(0.08),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? activeColor.shade300 : Colors.white.withOpacity(0.4),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
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
