import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/cashbook/cashbook_providers.dart';
import '../../features/wallet/wallet_providers.dart';
import '../../infrastructure/models/db_models.dart';
import '../../core/formulas/spending_pressure_index.dart';
import '../../core/formulas/budget_bucket_cascade.dart';
import '../../core/formulas/emergency_fund_erosion_rate.dart';
import '../../core/formulas/allocation_engine.dart';
import '../../core/models/Budget/budget_ratios.dart';
import '../../core/models/Budget/budget_category.dart';
import '../../core/models/Bucket/bucket_state.dart';
import '../../core/models/EmergencyFundErosionRate/emergency_fund_context.dart';
import '../../core/models/EmergencyFundErosionRate/emergency_fund_erosion_rate_result.dart';
import '../../core/models/User/cascade_mode.dart';
import '../../core/models/Bucket/cascade_result.dart';
import 'widgets/transaction_impact_card.dart';
import 'widgets/allocation_breakdown_card.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  bool _isIncome = false;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedWalletId;
  String? _selectedCategoryId;
  bool _showImpact = false;
  bool _isSaving = false;

  bool _allocateToEmergency = false;
  final _emergencyAmountController = TextEditingController();
  String? _selectedEmergencyWalletId;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    final totalAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final profile = ref.read(userProfileProvider).value;
    if (profile != null) {
      final defaultAlloc = totalAmount * profile.emergencyRatio;
      if (defaultAlloc > 0) {
        _emergencyAmountController.text = defaultAlloc.toStringAsFixed(2);
      } else {
        _emergencyAmountController.text = '';
      }
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _noteController.dispose();
    _emergencyAmountController.dispose();
    super.dispose();
  }

  BudgetCategory _bucketFromCategory(DbCategory? cat) {
    if (cat == null) return BudgetCategory.needs;
    switch (cat.defaultBucket) {
      case 'wants':
        return BudgetCategory.wants;
      case 'flex':
        return BudgetCategory.flex;
      case 'emergency':
        return BudgetCategory.emergency;
      default:
        return BudgetCategory.needs;
    }
  }

  Future<void> _handleSubmit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a wallet')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a category')),
      );
      return;
    }

    if (_isIncome) {
      if (_allocateToEmergency) {
        final allocAmount = double.tryParse(_emergencyAmountController.text.trim()) ?? 0.0;
        if (allocAmount <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter a valid emergency allocation amount')),
          );
          return;
        }
        if (allocAmount >= amount) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Emergency allocation cannot exceed or equal total income amount')),
          );
          return;
        }
        if (_selectedEmergencyWalletId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select a destination emergency wallet')),
          );
          return;
        }
      }
      // For income: show allocation breakdown, then save
      await _saveIncome(amount);
    } else {
      // For expense: show impact analysis first
      if (!_showImpact) {
        setState(() => _showImpact = true);
      }
    }
  }

  Future<void> _saveIncome(double amount) async {
    setState(() => _isSaving = true);

    final service = ref.read(cashbookServiceProvider);
    final categories = ref.read(incomeCategoriesProvider).value ?? [];
    final cat = categories.where((c) => c.id == _selectedCategoryId).firstOrNull;

    if (_allocateToEmergency) {
      final allocAmount = double.tryParse(_emergencyAmountController.text.trim()) ?? 0.0;
      final mainAmount = amount - allocAmount;

      // 1. Log main income portion
      await service.logIncome(
        amount: mainAmount,
        walletId: _selectedWalletId!,
        categoryId: _selectedCategoryId!,
        bucket: cat?.defaultBucket ?? 'needs',
        note: _noteController.text.trim(),
      );

      // 2. Log emergency allocation portion to the destination wallet under the emergency category
      await service.logIncome(
        amount: allocAmount,
        walletId: _selectedEmergencyWalletId!,
        categoryId: 'cat-interest',
        bucket: 'emergency',
        note: _noteController.text.trim().isNotEmpty
            ? '${_noteController.text.trim()} (EF Allocation)'
            : 'Emergency Fund Allocation',
      );
    } else {
      await service.logIncome(
        amount: amount,
        walletId: _selectedWalletId!,
        categoryId: _selectedCategoryId!,
        bucket: cat?.defaultBucket ?? 'needs',
        note: _noteController.text.trim(),
      );
    }

    // Show allocation breakdown
    final profile = await service.getUserProfile();
    if (profile != null) {
      final totalDebt = await service.getTotalActiveDebtPayments();
      final engine = AllocationEngine(
        ratios: BudgetRatios(
          emergency: profile.emergencyRatio,
          needs: profile.needsRatio,
          wants: profile.wantsRatio,
          flex: profile.flexRatio,
        ),
      );
      final result = engine.calculate(
        incomeAmount: amount,
        activeInstallments: totalDebt > 0 ? [totalDebt] : [],
      );

      invalidateCashbookProviders(ref);
      invalidateWalletProviders(ref);

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        // Show allocation breakdown as dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            child: AllocationBreakdownCard(
              result: result,
              onDismiss: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      }
    } else {
      invalidateCashbookProviders(ref);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _saveExpense(double amount) async {
    setState(() => _isSaving = true);

    final service = ref.read(cashbookServiceProvider);
    final categories = ref.read(expenseCategoriesProvider).value ?? [];
    final cat = categories.where((c) => c.id == _selectedCategoryId).firstOrNull;

    await service.logExpense(
      amount: amount,
      walletId: _selectedWalletId!,
      categoryId: _selectedCategoryId!,
      bucket: cat?.defaultBucket ?? 'needs',
      note: _noteController.text.trim(),
    );

    invalidateCashbookProviders(ref);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletsProvider).value ?? [];
    final incomeCategories = ref.watch(incomeCategoriesProvider).value ?? [];
    final expenseCategories = ref.watch(expenseCategoriesProvider).value ?? [];
    final categories = _isIncome ? incomeCategories : expenseCategories;
    final profile = ref.watch(userProfileProvider).value;
    final bucketSummary = ref.watch(monthlyBucketSummaryProvider).value;

    // Auto-select first wallet if not selected
    if (_selectedWalletId == null && wallets.isNotEmpty) {
      _selectedWalletId = wallets.first.id;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    // Build impact analysis for expenses
    if (_showImpact && !_isIncome && amount > 0 && profile != null) {
      final netWorth = ref.watch(netWorthProvider).value ?? 0.0;
      final totalDebt = ref.watch(totalDebtPaymentsProvider).value ?? 0.0;
      final fixedExpenses = bucketSummary?.totalSpent ?? 0.0;

      // SPI
      final spiEngine = SpiEngine();
      final spiResult = spiEngine.calculate(
        expenseAmount: amount,
        monthlyIncome: profile.monthlyIncome,
        totalFixedExpenses: fixedExpenses,
        totalActiveDebts: totalDebt,
        currentNetWorth: netWorth,
      );

      // BBC
      final selectedCat = categories.where((c) => c.id == _selectedCategoryId).firstOrNull;
      final targetBucket = _bucketFromCategory(selectedCat);
      final bbcEngine = BbcEngine(
        mode: profile.cascadeMode == 'strict'
            ? CascadeMode.strict
            : CascadeMode.soft,
      );

      CascadeResult? cascadeResult;
      if (bucketSummary != null) {
        try {
          cascadeResult = bbcEngine.calculate(
            expenseAmount: amount,
            targetBucket: targetBucket,
            bucketState: BucketState(
              needsRemaining: bucketSummary.needsRemaining,
              wantsRemaining: bucketSummary.wantsRemaining,
              flexRemaining: bucketSummary.flexRemaining,
              emergencyRemaining: bucketSummary.emergencyRemaining,
            ),
          );
        } catch (_) {
          // BucketState validation may fail if all zeros
        }
      }

      // EFER
      final eferEngine = EmergencyFundErosionRate();
      EmergencyFundErosionRateResult? eferResult;
      try {
        eferResult = eferEngine.calculate(
          expenseAmount: amount,
          remainingFreeCash: spiResult.remainingCash,
          emergencyFund: EmergencyFundContext(
            monthlyContribution: profile.monthlyIncome * profile.emergencyRatio,
            currentBalance: 0, // Would need EF tracking
            target: profile.efundTarget,
          ),
        );
      } catch (_) {}

      final walletName = wallets.where((w) => w.id == _selectedWalletId).firstOrNull?.name ?? '';
      final catName = selectedCat?.name ?? 'Expense';

      return TransactionImpactCard(
        categoryName: catName,
        amount: amount,
        walletName: walletName,
        spiResult: spiResult,
        cascadeResult: cascadeResult,
        eferResult: eferResult,
        onConfirm: () => _saveExpense(amount),
        onCancel: () => setState(() => _showImpact = false),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A2940),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Handle bar
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

            // Income / Expense toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withOpacity(0.06),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isIncome = false;
                        _selectedCategoryId = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: !_isIncome ? Colors.red.shade400.withOpacity(0.2) : Colors.transparent,
                        ),
                        child: Center(
                          child: Text(
                            'Expense',
                            style: TextStyle(
                              color: !_isIncome ? Colors.red.shade300 : Colors.white.withOpacity(0.4),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isIncome = true;
                        _selectedCategoryId = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: _isIncome ? Colors.green.shade400.withOpacity(0.2) : Colors.transparent,
                        ),
                        child: Center(
                          child: Text(
                            'Income',
                            style: TextStyle(
                              color: _isIncome ? Colors.green.shade300 : Colors.white.withOpacity(0.4),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Amount field
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                prefixText: '₱ ',
                prefixStyle: TextStyle(
                  color: _isIncome ? Colors.green.shade400 : Colors.red.shade400,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
                hintText: '0.00',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.15),
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
                border: InputBorder.none,
              ),
              textAlign: TextAlign.center,
              autofocus: true,
            ),

            const SizedBox(height: 16),

            // Wallet selector
            Text(
              'WALLET',
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: wallets.length,
                itemBuilder: (context, index) {
                  final w = wallets[index];
                  final selected = w.id == _selectedWalletId;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedWalletId = w.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: selected
                            ? Colors.green.shade400.withOpacity(0.2)
                            : Colors.white.withOpacity(0.06),
                        border: Border.all(
                          color: selected
                              ? Colors.green.shade400.withOpacity(0.4)
                              : Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Text(
                        w.name,
                        style: TextStyle(
                          color: selected ? Colors.green.shade300 : Colors.white.withOpacity(0.5),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Category selector
            Text(
              'CATEGORY',
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final selected = cat.id == _selectedCategoryId;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryId = cat.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: selected
                          ? (_isIncome
                              ? Colors.green.shade400.withOpacity(0.2)
                              : Colors.red.shade400.withOpacity(0.2))
                          : Colors.white.withOpacity(0.06),
                      border: Border.all(
                        color: selected
                            ? (_isIncome
                                ? Colors.green.shade400.withOpacity(0.4)
                                : Colors.red.shade400.withOpacity(0.4))
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Text(
                      cat.name,
                      style: TextStyle(
                        color: selected
                            ? (_isIncome ? Colors.green.shade300 : Colors.red.shade300)
                            : Colors.white.withOpacity(0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            if (_isIncome) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.04),
                  border: Border.all(
                    color: _allocateToEmergency
                        ? Colors.green.shade400.withOpacity(0.3)
                        : Colors.white.withOpacity(0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shield_rounded,
                              color: _allocateToEmergency
                                  ? Colors.green.shade400
                                  : Colors.white.withOpacity(0.3),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Allocate to Emergency Fund',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: _allocateToEmergency,
                          activeColor: Colors.green.shade400,
                          onChanged: (val) {
                            setState(() {
                              _allocateToEmergency = val;
                              if (val) {
                                // Default select an emergency wallet if available
                                if (_selectedEmergencyWalletId == null && wallets.isNotEmpty) {
                                  final emergencyWallet = wallets.firstWhere(
                                    (w) => w.name.toLowerCase().contains('emergency'),
                                    orElse: () => wallets.first,
                                  );
                                  _selectedEmergencyWalletId = emergencyWallet.id;
                                }
                                _onAmountChanged();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    if (_allocateToEmergency) ...[
                      const SizedBox(height: 16),
                      Divider(color: Colors.white.withOpacity(0.06), height: 1),
                      const SizedBox(height: 16),
                      
                      // Allocation Amount field
                      Text(
                        'ALLOCATION AMOUNT',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emergencyAmountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          prefixText: '₱ ',
                          prefixStyle: TextStyle(color: Colors.green.shade400, fontWeight: FontWeight.w600),
                          hintText: '0.00',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.15)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.03),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.green.shade400.withOpacity(0.4)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Emergency Wallet selector
                      Text(
                        'DESTINATION EMERGENCY WALLET',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 42,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: wallets.length,
                          itemBuilder: (context, idx) {
                            final w = wallets[idx];
                            final selected = w.id == _selectedEmergencyWalletId;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedEmergencyWalletId = w.id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: selected
                                      ? Colors.green.shade400.withOpacity(0.2)
                                      : Colors.white.withOpacity(0.06),
                                  border: Border.all(
                                    color: selected
                                        ? Colors.green.shade400.withOpacity(0.4)
                                        : Colors.white.withOpacity(0.08),
                                  ),
                                ),
                                child: Text(
                                  w.name,
                                  style: TextStyle(
                                    color: selected ? Colors.green.shade300 : Colors.white.withOpacity(0.5),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Note field
            TextField(
              controller: _noteController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add a note (optional)',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                prefixIcon: Icon(Icons.notes_rounded, color: Colors.white.withOpacity(0.3), size: 20),
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green.shade400.withOpacity(0.5)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              ),
            ),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isIncome ? Colors.green.shade500 : Colors.red.shade500,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        _isIncome ? 'Log Income' : 'Review & Log',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}
