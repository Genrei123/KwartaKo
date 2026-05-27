import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../features/dashboard/dashboard_providers.dart';
import '../../features/cashbook/cashbook_providers.dart';
import '../../core/formulas/debt_priority_engine.dart';
import '../../core/formulas/rule_of_72.dart';
import '../../core/models/Debt/debt.dart';
import '../../core/models/Debt/debt_payoff_result.dart';
import '../../infrastructure/models/db_models.dart';

class ProjectionsScreen extends ConsumerStatefulWidget {
  const ProjectionsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProjectionsScreen> createState() => _ProjectionsScreenState();
}

class _ProjectionsScreenState extends ConsumerState<ProjectionsScreen> {
  bool _initialized = false;

  // Debt payoff states
  final List<Debt> _tempDebts = [];
  final Set<String> _deselectedDebts = {}; // track checkboxes
  final Map<String, double> _customRates = {}; // override interest rates for db debts
  final _debtBudgetCtrl = TextEditingController(text: '3000.00');

  // New temporary debt sheet inputs
  final _tempNameCtrl = TextEditingController();
  final _tempBalCtrl = TextEditingController();
  final _tempRateCtrl = TextEditingController();
  final _tempMinCtrl = TextEditingController();

  DebtPriorityComparison? _comparisonResult;
  bool _showAvalancheSchedule = true;

  // Savings growth states
  final _savingsPrincipalCtrl = TextEditingController(text: '10000.00');
  final _savingsMonthlyCtrl = TextEditingController(text: '1000.00');
  final _savingsRateCtrl = TextEditingController(text: '7.00');
  int _savingsYears = 10;

  @override
  void dispose() {
    _debtBudgetCtrl.dispose();
    _tempNameCtrl.dispose();
    _tempBalCtrl.dispose();
    _tempRateCtrl.dispose();
    _tempMinCtrl.dispose();
    _savingsPrincipalCtrl.dispose();
    _savingsMonthlyCtrl.dispose();
    _savingsRateCtrl.dispose();
    super.dispose();
  }

  // Merges SQLite active installments and in-memory temp debts into simulated debts
  List<Debt> _getMergedDebts(List<DbInstallment> dbInstallments) {
    final List<Debt> list = [];

    // Map DB installments
    for (final inst in dbInstallments) {
      final balance = inst.monthlyPayment * inst.monthsRemaining;
      if (balance > 0) {
        list.add(Debt(
          name: inst.name,
          balance: balance,
          interestRate: _customRates[inst.name] ?? 0.0, // default to 0% unless customized
          minimumPayment: inst.monthlyPayment,
        ));
      }
    }

    // Add in-memory temp debts
    list.addAll(_tempDebts);
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final activeDebtsAsync = ref.watch(dashboardActiveDebtsProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final netWorthAsync = ref.watch(netWorthProvider);
    final fmt = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    if (!_initialized && userProfileAsync.hasValue && netWorthAsync.hasValue) {
      _initialized = true;
      final profile = userProfileAsync.value;
      final netWorth = netWorthAsync.value ?? 0.0;

      final monthlyIncome = profile?.monthlyIncome ?? 30000.0;
      final emergencyRatio = profile?.emergencyRatio ?? 0.10;

      final defaultPayoffBudget = monthlyIncome * 0.10;
      final defaultSavingsMonthly = monthlyIncome * emergencyRatio;
      final defaultPrincipal = netWorth > 0 ? netWorth : 10000.0;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _debtBudgetCtrl.text = defaultPayoffBudget.toStringAsFixed(2);
          _savingsPrincipalCtrl.text = defaultPrincipal.toStringAsFixed(2);
          _savingsMonthlyCtrl.text = defaultSavingsMonthly.toStringAsFixed(2);
          setState(() {});
        }
      });
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1B2D),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F1B2D),
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Projections & Simulators',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          bottom: TabBar(
            dividerColor: Colors.white.withOpacity(0.05),
            indicatorColor: Colors.green.shade400,
            labelColor: Colors.green.shade400,
            unselectedLabelColor: Colors.white.withOpacity(0.4),
            indicatorWeight: 3,
            tabs: const [
              Tab(
                icon: Icon(Icons.compare_arrows_rounded, size: 20),
                text: 'Debt Payoff',
              ),
              Tab(
                icon: Icon(Icons.trending_up_rounded, size: 20),
                text: 'Savings Growth',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Debt Payoff Simulator
            activeDebtsAsync.when(
              data: (dbInstallments) {
                final allDebts = _getMergedDebts(dbInstallments);
                return _buildDebtSimulatorTab(allDebts, fmt);
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.green)),
              error: (err, _) => Center(
                child: Text(
                  'Error loading debts: $err',
                  style: TextStyle(color: Colors.red.shade300),
                ),
              ),
            ),

            // Tab 2: Savings Growth Tab
            _buildSavingsGrowthTab(fmt),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Debt Payoff Simulator ───────────────────────────────────────────

  Widget _buildDebtSimulatorTab(List<Debt> allDebts, NumberFormat fmt) {
    final selectedDebts = allDebts.where((d) => !_deselectedDebts.contains(d.name)).toList();
    final double totalMinimums = selectedDebts.fold(0.0, (sum, d) => sum + d.minimumPayment);
    final double budgetInput = double.tryParse(_debtBudgetCtrl.text.trim()) ?? 0.0;
    final isBudgetValid = budgetInput >= totalMinimums && selectedDebts.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.04),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.green.shade400, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Simulate Snowball vs. Avalanche strategies using active installments and custom debts.',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Debts Manager Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MANAGE DEBTS (${allDebts.length})',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              GestureDetector(
                onTap: _showAddTempDebtSheet,
                child: Text(
                  '+ ADD TEMP DEBT',
                  style: TextStyle(
                    color: Colors.green.shade400,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Debts list
          if (allDebts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No debts found. Add a temporary debt above to simulate!',
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allDebts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final d = allDebts[idx];
                final isSelected = !_deselectedDebts.contains(d.name);
                final isTemp = _tempDebts.any((td) => td.name == d.name);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isSelected ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.02),
                    border: Border.all(
                      color: isSelected
                          ? Colors.green.shade400.withOpacity(0.2)
                          : Colors.white.withOpacity(0.04),
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        activeColor: Colors.green.shade500,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _deselectedDebts.remove(d.name);
                            } else {
                              _deselectedDebts.add(d.name);
                            }
                            _comparisonResult = null; // Reset comparison on change
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  d.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (isTemp) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.blue.shade500.withOpacity(0.2),
                                    ),
                                    child: Text(
                                      'TEMP',
                                      style: TextStyle(
                                        color: Colors.blue.shade300,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  'Bal: ${fmt.format(d.balance)}',
                                  style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Min: ${fmt.format(d.minimumPayment)}/mo',
                                  style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Interest Rate modifier or display
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () => _editInterestRate(d),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(d.interestRate * 100).toStringAsFixed(1)}% APR',
                                  style: TextStyle(
                                    color: Colors.green.shade300,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.edit_rounded, color: Colors.green.shade400.withOpacity(0.6), size: 12),
                              ],
                            ),
                          ),
                          if (isTemp)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 18),
                              onPressed: () {
                                setState(() {
                                  _tempDebts.removeWhere((td) => td.name == d.name);
                                  _comparisonResult = null;
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 24),

          // Simulation Config Panel
          Text(
            'SIMULATOR PARAMETERS',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MONTHLY PAYOFF BUDGET',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Min Required: ${fmt.format(totalMinimums)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _debtBudgetCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  onChanged: (v) {
                    setState(() {
                      _comparisonResult = null;
                    });
                  },
                  decoration: InputDecoration(
                    prefixText: '₱ ',
                    prefixStyle: TextStyle(color: Colors.green.shade400, fontSize: 16),
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
                      borderSide: BorderSide(color: Colors.green.shade400, width: 1.5),
                    ),
                  ),
                ),
                if (selectedDebts.isNotEmpty && budgetInput < totalMinimums) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade400.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red.shade300, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Budget is too low. Must cover the total minimum payments of all selected debts.',
                            style: TextStyle(color: Colors.red.shade300, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade900.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade400.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.help_outline_rounded, color: Colors.amber.shade300, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Struggling to cover the minimum payments?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'If your income or net worth (e.g. ₱300) is temporarily too low to cover your monthly debt installments, try these practical steps:',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildRestructureBullet('Prioritize Needs first: Fall back to Cashbook\'s "Soft Cascade" mode which guarantees that food and shelter are paid before installments.'),
                        _buildRestructureBullet('Freeze Wants & Flex: Scale Wants and Flex budgets to ₱0 to redirect every possible peso toward covering minimums.'),
                        _buildRestructureBullet('Contact your lenders: Request a temporary payment holiday or negotiate an extended repayment term to lower your monthly minimum payment.'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Run Simulation Trigger Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isBudgetValid
                  ? () {
                      final engine = const DebtPriorityEngine();
                      try {
                        final res = engine.compare(
                          debts: selectedDebts,
                          monthlyPayoffBudget: budgetInput,
                        );
                        setState(() {
                          _comparisonResult = res;
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Simulation error: $e')),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade500,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white.withOpacity(0.04),
                disabledForegroundColor: Colors.white.withOpacity(0.15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'Run Payoff Simulation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Render Comparison Dashboard if ready
          if (_comparisonResult != null) _buildComparisonResults(fmt),
        ],
      ),
    );
  }

  Widget _buildComparisonResults(NumberFormat fmt) {
    final comp = _comparisonResult!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SIMULATION RESULTS',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),

        // Recommendation Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade800.withOpacity(0.4),
                Colors.green.shade900.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade400.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.green.shade400, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Optimal Strategy: ${comp.recommendedStrategyLabel}',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (comp.interestSaved > 0.01 || comp.monthsSaved > 0) ...[
                const SizedBox(height: 10),
                Text(
                  'Choosing Avalanche over Snowball saves you ${fmt.format(comp.interestSaved)} in interest and pays off your debt ${comp.monthsSaved} months sooner.',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.4),
                ),
              ] else ...[
                const SizedBox(height: 10),
                Text(
                  'Both strategies yield similar payoff timelines. Snowball is recommended for quick early wins to boost repayment motivation!',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.4),
                ),
              ],
            ],
          ),
        ),
        if (comp.interestSaved <= 0.01 && comp.monthsSaved == 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade900.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade400.withOpacity(0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: Colors.blue.shade300, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Why are the strategy results identical?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Snowball (paying small balances first) and Avalanche (paying high interest first) only differ when you have multiple debts with varying interest rates. '
                        'Since you only have one debt selected or all selected debts are 0% APR flat installments, the repayment timeline is identical.\n\n'
                        '💡 Pro-tip: Try simulating multiple debts by adding temporary high-interest mock debts (like a 24% APR Credit Card or a 12% APR Personal Loan) with "+ ADD TEMP DEBT" above!',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Side-by-Side metrics
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'AVALANCHE',
                value: '${comp.avalanche.monthsToPayoff} months',
                subValue: 'Interest: ${fmt.format(comp.avalanche.totalInterestPaid)}',
                color: Colors.green.shade400,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'SNOWBALL',
                value: '${comp.snowball.monthsToPayoff} months',
                subValue: 'Interest: ${fmt.format(comp.snowball.totalInterestPaid)}',
                color: Colors.blue.shade400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Schedule visualizer header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PAYOFF SCHEDULE TIMELINE',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _showAvalancheSchedule = true),
                  child: Text(
                    'AVALANCHE',
                    style: TextStyle(
                      color: _showAvalancheSchedule ? Colors.green.shade400 : Colors.white.withOpacity(0.3),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _showAvalancheSchedule = false),
                  child: Text(
                    'SNOWBALL',
                    style: TextStyle(
                      color: !_showAvalancheSchedule ? Colors.blue.shade400 : Colors.white.withOpacity(0.3),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Timeline Schedule list
        _buildScheduleTimeline(_showAvalancheSchedule ? comp.avalanche : comp.snowball, fmt),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subValue,
    required Color color,
  }) {
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
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subValue,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestructureBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.amber.shade300, fontSize: 12, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTimeline(DebtPayoffResult result, NumberFormat fmt) {
    if (result.schedule.isEmpty) return const SizedBox();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: math.min(12, result.schedule.length), // limit to first 12 months for layout neatness
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withOpacity(0.04)),
        itemBuilder: (context, index) {
          final snapshot = result.schedule[index];
          final totalPaid = snapshot.totalPaidThisMonth;
          final intAccrued = snapshot.interestPaidThisMonth;

          // Compute total remaining balance at this month
          final double rem = snapshot.remainingBalances.values.fold(0.0, (sum, val) => sum + val);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.green.shade400.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${snapshot.month}',
                        style: TextStyle(color: Colors.green.shade300, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Month ${snapshot.month}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Paid: ${fmt.format(totalPaid)} (Interest: ${fmt.format(intAccrued)})',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  rem > 0 ? fmt.format(rem) : 'DEBT FREE!',
                  style: TextStyle(
                    color: rem > 0 ? Colors.white : Colors.green.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Tab 2: Savings Growth Tab ──────────────────────────────────────────────

  Widget _buildSavingsGrowthTab(NumberFormat fmt) {
    final p = double.tryParse(_savingsPrincipalCtrl.text.trim()) ?? 0.0;
    final m = double.tryParse(_savingsMonthlyCtrl.text.trim()) ?? 0.0;
    final r = double.tryParse(_savingsRateCtrl.text.trim()) ?? 0.0;

    // Year-by-year calculation logic
    final List<_YearGrowth> growthData = [];
    double currentVal = p;
    double totalPrincipal = p;

    for (int y = 1; y <= _savingsYears; y++) {
      double yearCont = m * 12;

      for (int month = 0; month < 12; month++) {
        currentVal += m;
        final interest = currentVal * ((r / 100.0) / 12.0);
        currentVal += interest;
      }

      totalPrincipal += yearCont;
      growthData.add(_YearGrowth(
        year: y,
        futureValue: currentVal,
        totalContributions: totalPrincipal,
        totalInterestEarned: currentVal - totalPrincipal,
      ));
    }

    final finalVal = growthData.isNotEmpty ? growthData.last.futureValue : p;
    final finalInterest = growthData.isNotEmpty ? growthData.last.totalInterestEarned : 0.0;

    // Rule of 72 metrics
    final rule = const RuleOf72();
    final double yearsToDouble = rule.calculateYearsToDouble(r);
    final double exactYearsToDouble = rule.calculateExactYearsToDouble(r);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header description
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.04),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up_rounded, color: Colors.green.shade400, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Analyze how your cash grows using standard compound interest, along with the Rule of 72.',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Inputs Card
          Text(
            'SAVINGS & horizon PARAMETERS',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Principal
                _lbl('INITIAL PRINCIPAL DEPOSIT'),
                const SizedBox(height: 8),
                _numericField(_savingsPrincipalCtrl),
                const SizedBox(height: 16),

                // Monthly contributions
                _lbl('MONTHLY CONTRIBUTION AMOUNT'),
                const SizedBox(height: 8),
                _numericField(_savingsMonthlyCtrl),
                const SizedBox(height: 16),

                // Annual Interest Rate
                _lbl('EXPECTED ANNUAL INTEREST RATE (%)'),
                const SizedBox(height: 8),
                _numericField(_savingsRateCtrl, suffix: '%'),
                const SizedBox(height: 16),

                // Horizon Dropdown
                _lbl('PROJECTION HORIZON (YEARS)'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _savingsYears,
                      dropdownColor: const Color(0xFF1A2940),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      isExpanded: true,
                      items: [5, 10, 15, 20, 25, 30].map((int val) {
                        return DropdownMenuItem<int>(
                          value: val,
                          child: Text('$val Years'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _savingsYears = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Dashboard Growth Stats
          Text(
            'SAVINGS PROJECTION RESULTS',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'TOTAL VALUE',
                  value: fmt.format(finalVal),
                  subValue: 'In $_savingsYears Years',
                  color: Colors.green.shade400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'INTEREST EARNED',
                  value: fmt.format(finalInterest),
                  subValue: 'APR: ${r.toStringAsFixed(1)}%',
                  color: Colors.blue.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Rule of 72 Insight Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade900.withOpacity(0.35),
                  const Color(0xFF1A0933).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.shade400.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.offline_bolt_rounded, color: Colors.purple.shade300, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Rule of 72 Investment Analytics',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  r > 0
                      ? 'At this interest rate, your starting investment will double in approximately ${yearsToDouble.toStringAsFixed(1)} years.\n(Exact formula: ${exactYearsToDouble.toStringAsFixed(2)} years).'
                      : 'Provide a positive annual interest rate to run Rule of 72 projections.',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Growth Table
          Text(
            'YEARLY PROJECTION DETAILS',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: growthData.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withOpacity(0.04)),
              itemBuilder: (context, index) {
                final row = growthData[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Year ${row.year}',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Contributions: ${fmt.format(row.totalContributions)}',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            fmt.format(row.futureValue),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '+${fmt.format(row.totalInterestEarned)} interest',
                            style: TextStyle(color: Colors.green.shade400, fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _lbl(String t) => Text(
        t,
        style: TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );

  Widget _numericField(TextEditingController ctrl, {String? suffix}) => TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
        style: const TextStyle(color: Colors.white, fontSize: 15),
        onChanged: (_) {
          setState(() {});
        },
        decoration: InputDecoration(
          prefixText: suffix == null ? '₱ ' : null,
          prefixStyle: TextStyle(color: Colors.green.shade400, fontSize: 15),
          suffixText: suffix,
          suffixStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 15),
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
            borderSide: BorderSide(color: Colors.green.shade400, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      );

  // ── Bottom Sheet: Add Temp Debt ────────────────────────────────────────────

  void _showAddTempDebtSheet() {
    _tempNameCtrl.clear();
    _tempBalCtrl.clear();
    _tempMinCtrl.clear();
    _tempRateCtrl.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
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
                        'Add Simulation-Only Debt',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This debt will exist only in memory for this simulation session.',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                      ),
                      const SizedBox(height: 24),

                      _lbl('DEBT NAME'),
                      const SizedBox(height: 8),
                      _sheetField(_tempNameCtrl, 'e.g. Credit Card A, Loan X', Icons.tag_rounded),
                      const SizedBox(height: 16),

                      _lbl('OUTSTANDING BALANCE'),
                      const SizedBox(height: 8),
                      _sheetNumericField(_tempBalCtrl, '0.00'),
                      const SizedBox(height: 16),

                      _lbl('MINIMUM MONTHLY PAYMENT'),
                      const SizedBox(height: 8),
                      _sheetNumericField(_tempMinCtrl, '0.00'),
                      const SizedBox(height: 16),

                      _lbl('ANNUAL INTEREST RATE (APR %)'),
                      const SizedBox(height: 8),
                      _sheetNumericField(_tempRateCtrl, '0.00', suffix: '%'),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            final name = _tempNameCtrl.text.trim();
                            final bal = double.tryParse(_tempBalCtrl.text.trim()) ?? 0.0;
                            final min = double.tryParse(_tempMinCtrl.text.trim()) ?? 0.0;
                            final ratePercent = double.tryParse(_tempRateCtrl.text.trim()) ?? 0.0;

                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Enter a valid debt name')),
                              );
                              return;
                            }
                            if (bal <= 0 || min <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Balance and Minimum Payment must be positive numbers')),
                              );
                              return;
                            }

                            final newDebt = Debt(
                              name: name,
                              balance: bal,
                              interestRate: ratePercent / 100.0,
                              minimumPayment: min,
                            );

                            setState(() {
                              _tempDebts.add(newDebt);
                              _comparisonResult = null;
                            });

                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade500,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Add to Simulation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Modal Interest Rate Editor ─────────────────────────────────────────────

  void _editInterestRate(Debt debt) {
    final ctrl = TextEditingController(text: (debt.interestRate * 100).toStringAsFixed(1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1A2940),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                      'Edit APR: ${debt.name}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Modify the interest rate for the payoff simulation.',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: ctrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        suffixText: '%',
                        suffixStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16),
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
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          final pct = double.tryParse(ctrl.text.trim()) ?? 0.0;
                          setState(() {
                            final isTemp = _tempDebts.any((td) => td.name == debt.name);
                            if (isTemp) {
                              final idx = _tempDebts.indexWhere((td) => td.name == debt.name);
                              if (idx != -1) {
                                _tempDebts[idx] = _tempDebts[idx].copyWith(interestRate: pct / 100.0);
                              }
                            } else {
                              _customRates[debt.name] = pct / 100.0;
                            }
                            _comparisonResult = null;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade500,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Update Rate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetField(TextEditingController c, String hint, IconData icon) => TextField(
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

  Widget _sheetNumericField(TextEditingController c, String hint, {String? suffix}) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          prefixText: suffix == null ? '₱ ' : null,
          prefixStyle: TextStyle(color: Colors.green.shade400, fontSize: 16),
          suffixText: suffix,
          suffixStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16),
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

// ── Year Growth Helper Model ────────────────────────────────────────────────

class _YearGrowth {
  final int year;
  final double futureValue;
  final double totalContributions;
  final double totalInterestEarned;

  _YearGrowth({
    required this.year,
    required this.futureValue,
    required this.totalContributions,
    required this.totalInterestEarned,
  });
}
