import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../features/cashbook/cashbook_providers.dart';
import '../../../features/wallet/wallet_providers.dart';
import '../../../infrastructure/models/db_models.dart';

class BudgetBreakdownSheet extends ConsumerStatefulWidget {
  const BudgetBreakdownSheet({super.key});

  @override
  ConsumerState<BudgetBreakdownSheet> createState() => _BudgetBreakdownSheetState();
}

class _BudgetBreakdownSheetState extends ConsumerState<BudgetBreakdownSheet> {
  double _needsRatio = 0.50;
  double _wantsRatio = 0.30;
  double _flexRatio = 0.10;
  double _emergencyRatio = 0.10;
  late TextEditingController _efundTargetController;
  bool _initialized = false;
  bool _isEditing = false;
  bool _isSaving = false;

  void _initializeValues(DbUserProfile profile) {
    if (_initialized) return;
    _needsRatio = profile.needsRatio;
    _wantsRatio = profile.wantsRatio;
    _flexRatio = profile.flexRatio;
    _emergencyRatio = profile.emergencyRatio;
    _efundTargetController = TextEditingController(text: profile.efundTarget.toStringAsFixed(0));
    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      _efundTargetController.dispose();
    }
    super.dispose();
  }

  Future<void> _saveSettings(DbUserProfile profile) async {
    final double? efundTarget = double.tryParse(_efundTargetController.text.trim());
    if (efundTarget == null || efundTarget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid Emergency Fund target amount.'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    final total = (_needsRatio + _wantsRatio + _flexRatio + _emergencyRatio) * 100;
    if (total.round() != 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bucket percentages must sum to exactly 100%.'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updated = DbUserProfile(
        id: profile.id,
        displayName: profile.displayName,
        monthlyIncome: profile.monthlyIncome,
        needsRatio: _needsRatio,
        wantsRatio: _wantsRatio,
        flexRatio: _flexRatio,
        emergencyRatio: _emergencyRatio,
        efundTarget: efundTarget,
        cascadeMode: profile.cascadeMode,
        pinEnabled: profile.pinEnabled,
        pinHash: profile.pinHash,
        biometricEnabled: profile.biometricEnabled,
      );

      await ref.read(cashbookServiceProvider).updateUserProfile(updated);
      invalidateCashbookProviders(ref);

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget allocations updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  void _showSecureEmergencyDialog(BuildContext context, double remaining) {
    final wallets = ref.read(walletsProvider).value ?? [];
    if (wallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a wallet first.')),
      );
      return;
    }

    String? sourceWalletId;
    String? destWalletId;

    // Default select
    sourceWalletId = wallets.first.id;
    final emergencyWallet = wallets.firstWhere(
      (w) => w.name.toLowerCase().contains('emergency'),
      orElse: () => wallets.first,
    );
    destWalletId = emergencyWallet.id;

    final amountController = TextEditingController(text: remaining.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F1B2D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              title: const Row(
                children: [
                  Icon(Icons.lock_person_rounded, color: Colors.redAccent, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Secure Funds',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lock money into your dedicated Emergency Wallet to protect it from general spending.',
                      style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    
                    // Amount Field
                    Text(
                      'AMOUNT TO SECURE',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        prefixText: '₱ ',
                        prefixStyle: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w600),
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
                          borderSide: BorderSide(color: Colors.red.shade400.withOpacity(0.4)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // Source Wallet Dropdown
                    Text(
                      'SOURCE WALLET (WITHDRAW FROM)',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: sourceWalletId,
                          dropdownColor: const Color(0xFF0F1B2D),
                          icon: Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.5)),
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                          items: wallets.map((w) {
                            return DropdownMenuItem<String>(
                              value: w.id,
                              child: Text(w.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setDialogState(() {
                              sourceWalletId = val;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Destination Wallet Dropdown
                    Text(
                      'DESTINATION EMERGENCY WALLET',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: destWalletId,
                          dropdownColor: const Color(0xFF0F1B2D),
                          icon: Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.5)),
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                          items: wallets.map((w) {
                            return DropdownMenuItem<String>(
                              value: w.id,
                              child: Text(w.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setDialogState(() {
                              destWalletId = val;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
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
                  onPressed: () async {
                    final secureAmount = double.tryParse(amountController.text.trim()) ?? 0.0;
                    if (secureAmount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a valid amount')),
                      );
                      return;
                    }
                    if (secureAmount > remaining) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cannot secure more than remaining emergency budget')),
                      );
                      return;
                    }
                    if (sourceWalletId == null || destWalletId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Select source and destination wallets')),
                      );
                      return;
                    }
                    if (sourceWalletId == destWalletId) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Source and destination wallets must be different')),
                      );
                      return;
                    }

                    final service = ref.read(cashbookServiceProvider);
                    
                    try {
                      // 1. Log withdrawal expense from source wallet
                      await service.logExpense(
                        amount: secureAmount,
                        walletId: sourceWalletId!,
                        categoryId: 'cat-emergency',
                        bucket: 'needs',
                        note: 'Secured to Emergency Wallet',
                      );

                      // 2. Log deposit income to emergency wallet
                      await service.logIncome(
                        amount: secureAmount,
                        walletId: destWalletId!,
                        categoryId: 'cat-interest',
                        bucket: 'emergency',
                        note: 'Secured from General Spending',
                      );

                      invalidateCashbookProviders(ref);
                      invalidateWalletProviders(ref);

                      if (context.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('₱${secureAmount.toStringAsFixed(2)} secured successfully!'),
                            backgroundColor: Colors.green.shade600,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error securing funds: $e'),
                            backgroundColor: Colors.red.shade600,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade500,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Lock & Secure',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bucketSummaryAsync = ref.watch(monthlyBucketSummaryProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    ref.watch(walletsProvider); // Watch so changes refresh the screen
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
                  _isEditing ? Icons.tune_rounded : Icons.pie_chart_rounded,
                  color: Colors.green.shade400,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Customize Allocations' : 'Budget Breakdown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isEditing ? 'Set targets & ratio percentages' : 'Current Month Allocation & Spend',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isEditing)
                userProfileAsync.maybeWhen(
                  data: (profile) => profile != null
                      ? IconButton(
                          onPressed: () {
                            _initializeValues(profile);
                            setState(() => _isEditing = true);
                          },
                          icon: Icon(Icons.edit_note_rounded, color: Colors.green.shade400, size: 28),
                          tooltip: 'Edit allocations',
                        )
                      : const SizedBox(),
                  orElse: () => const SizedBox(),
                ),
            ],
          ),
          const SizedBox(height: 20),
          bucketSummaryAsync.when(
            data: (summary) => userProfileAsync.when(
              data: (profile) {
                if (profile == null) {
                  return const Center(child: Text('No active profile setup.'));
                }
                
                if (_isEditing) {
                  _initializeValues(profile);
                  final total = (_needsRatio + _wantsRatio + _flexRatio + _emergencyRatio) * 100;
                  final totalRounded = total.round();
                  final isValid = totalRounded == 100;

                  return Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EMERGENCY FUND TARGET',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: TextField(
                              controller: _efundTargetController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                prefixText: '₱ ',
                                prefixStyle: TextStyle(color: Colors.green.shade400, fontWeight: FontWeight.bold, fontSize: 16),
                                hintText: '0.00',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'PERCENTAGE RATIOS',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isValid ? Colors.green.shade400.withOpacity(0.15) : Colors.red.shade400.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Total: $totalRounded%',
                                  style: TextStyle(
                                    color: isValid ? Colors.green.shade300 : Colors.red.shade300,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          _buildSliderRow(
                            label: 'Needs (Standard 50%)',
                            value: _needsRatio,
                            color: Colors.blue.shade400,
                            onChanged: (val) {
                              setState(() => _needsRatio = val);
                            },
                          ),
                          _buildSliderRow(
                            label: 'Wants (Standard 30%)',
                            value: _wantsRatio,
                            color: Colors.purple.shade400,
                            onChanged: (val) {
                              setState(() => _wantsRatio = val);
                            },
                          ),
                          _buildSliderRow(
                            label: 'Flex (Standard 10%)',
                            value: _flexRatio,
                            color: Colors.orange.shade400,
                            onChanged: (val) {
                              setState(() => _flexRatio = val);
                            },
                          ),
                          _buildSliderRow(
                            label: 'Emergency (Standard 10%)',
                            value: _emergencyRatio,
                            color: Colors.red.shade400,
                            onChanged: (val) {
                              setState(() => _emergencyRatio = val);
                            },
                          ),

                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _initialized = false;
                                      _isEditing = false;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.white.withOpacity(0.15)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: const Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: (!isValid || _isSaving) ? null : () => _saveSettings(profile),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade500,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    disabledBackgroundColor: Colors.white.withOpacity(0.08),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildBucketCard(
                          context: context,
                          title: 'Needs',
                          percent: profile.needsRatio * 100,
                          allocated: summary.needsAllocated,
                          spent: summary.needsSpent,
                          color: Colors.blue.shade400,
                          icon: Icons.home_rounded,
                          formatter: formatter,
                        ),
                        const SizedBox(height: 16),
                        _buildBucketCard(
                          context: context,
                          title: 'Wants',
                          percent: profile.wantsRatio * 100,
                          allocated: summary.wantsAllocated,
                          spent: summary.wantsSpent,
                          color: Colors.purple.shade400,
                          icon: Icons.shopping_bag_rounded,
                          formatter: formatter,
                        ),
                        const SizedBox(height: 16),
                        _buildBucketCard(
                          context: context,
                          title: 'Flex',
                          percent: profile.flexRatio * 100,
                          allocated: summary.flexAllocated,
                          spent: summary.flexSpent,
                          color: Colors.orange.shade400,
                          icon: Icons.bolt_rounded,
                          formatter: formatter,
                        ),
                        const SizedBox(height: 16),
                        _buildBucketCard(
                          context: context,
                          title: 'Emergency',
                          percent: profile.emergencyRatio * 100,
                          allocated: summary.emergencyAllocated,
                          spent: summary.emergencySpent,
                          color: Colors.red.shade400,
                          icon: Icons.shield_rounded,
                          formatter: formatter,
                        ),
                        const SizedBox(height: 24),
                        // Direct Edit Trigger Button at the bottom
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _initializeValues(profile);
                              setState(() => _isEditing = true);
                            },
                            icon: Icon(Icons.tune_rounded, color: Colors.green.shade400, size: 20),
                            label: const Text(
                              'Customize Target & Ratios',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.green.shade400.withOpacity(0.35)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Failed to load profile.')),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Failed to load budget summary.')),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    final percentVal = (value * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$percentVal%',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: Colors.white.withOpacity(0.06),
            thumbColor: color,
            overlayColor: color.withOpacity(0.12),
            valueIndicatorColor: color,
            trackHeight: 4.0,
          ),
          child: Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            divisions: 20, // 5% increments
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildBucketCard({
    required BuildContext context,
    required String title,
    required double percent,
    required double allocated,
    required double spent,
    required Color color,
    required IconData icon,
    required NumberFormat formatter,
  }) {
    final progress = allocated > 0 ? (spent / allocated).clamp(0.0, 1.5) : 0.0;
    final isOver = spent > allocated && allocated > 0;
    final remaining = allocated - spent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Target Ratio: ${percent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOver
                      ? Colors.red.shade400.withOpacity(0.15)
                      : Colors.green.shade400.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOver ? 'Over budget' : 'On Track',
                  style: TextStyle(
                    color: isOver ? Colors.red.shade300 : Colors.green.shade300,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ALLOCATED',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatter.format(allocated),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SPENT',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatter.format(spent),
                    style: TextStyle(
                      color: isOver ? Colors.red.shade300 : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOver ? 'DEFICIT' : 'REMAINING',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatter.format(remaining.abs()),
                    style: TextStyle(
                      color: isOver ? Colors.red.shade400 : Colors.green.shade400,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isOver
                              ? [Colors.red.shade400, Colors.red.shade600]
                              : [color, color.withOpacity(0.65)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (title == 'Emergency' && remaining > 0) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                onPressed: () => _showSecureEmergencyDialog(context, remaining),
                icon: const Icon(Icons.lock_person_rounded, size: 16, color: Colors.white),
                label: const Text(
                  'Secure Emergency Funds',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
