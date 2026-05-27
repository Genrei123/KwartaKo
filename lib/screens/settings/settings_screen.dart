import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../features/auth/auth_service.dart';
import '../../features/cashbook/cashbook_providers.dart';
import '../../features/dashboard/dashboard_providers.dart';
import '../../features/wallet/wallet_providers.dart';
import '../../infrastructure/models/db_models.dart';
import '../../infrastructure/database_helper.dart';
import '../auth/create_account_screen.dart';
import 'widgets/installment_editor_sheet.dart';
import 'widgets/recurring_transaction_editor_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final AuthService authService;

  const SettingsScreen({Key? key, required this.authService}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  DbUserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await widget.authService.getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
      });
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final savingsGoalsAsync = ref.watch(dashboardSavingsGoalsProvider);
    final activeInstallmentsAsync = ref.watch(activeInstallmentsProvider);
    final recurringTransactionsAsync = ref.watch(recurringTransactionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1B2D),
      body: _userProfile == null
          ? const Center(
              child: CircularProgressIndicator(color: Colors.green),
            )
          : CustomScrollView(
              slivers: [
                // App Bar
                const SliverAppBar(
                  expandedHeight: 60,
                  pinned: true,
                  backgroundColor: Color(0xFF0F1B2D),
                  surfaceTintColor: Colors.transparent,
                  title: Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  centerTitle: false,
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 8),

                      // ── Profile Card ─────────────────────────────────
                      _buildProfileCard(),

                      const SizedBox(height: 24),

                      // ── Security Section ─────────────────────────────
                      _buildSectionHeader('Security'),
                      const SizedBox(height: 12),
                      _buildSecuritySection(),

                      const SizedBox(height: 24),

                      // ── Budget Allocation Section ────────────────────
                      _buildSectionHeader('Budget Allocation (Tap to Modify)'),
                      const SizedBox(height: 12),
                      _buildAllocationSection(),

                      const SizedBox(height: 24),

                      // ── Financial Goals Section ──────────────────────
                      _buildSectionHeader('Financial Goals & Savings Targets'),
                      const SizedBox(height: 12),
                      _buildGoalsSection(savingsGoalsAsync, fmt),

                      const SizedBox(height: 24),

                      // ── Active Installments Section ─────────────────
                      _buildSectionHeader('Active Installments (Simulations/Real)'),
                      const SizedBox(height: 12),
                      _buildInstallmentsSection(activeInstallmentsAsync, fmt),

                      const SizedBox(height: 24),

                      // ── Recurring Salary & Bills Section ───────────
                      _buildSectionHeader('Recurring Income & Bills'),
                      const SizedBox(height: 12),
                      _buildRecurringSection(recurringTransactionsAsync, fmt),

                      const SizedBox(height: 24),

                      // ── Danger Zone ─────────────────────────────────
                      _buildSectionHeader('Danger Zone'),
                      const SizedBox(height: 12),
                      _buildDangerZoneSection(),

                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Profile Card ───────────────────────────────────────────────────────────

  Widget _buildProfileCard() {
    final initials = _getInitials(_userProfile!.displayName);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.green.shade700.withOpacity(0.35),
            Colors.green.shade900.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.green.shade400.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade400,
                  Colors.green.shade700,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade400.withOpacity(0.35),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Name & Income
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userProfile!.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.monetization_on_outlined,
                      color: Colors.green.shade300,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '₱${_userProfile!.monthlyIncome.toStringAsFixed(2)} / month',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // PIN badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _userProfile!.pinEnabled == 1
                  ? Colors.green.shade400.withOpacity(0.2)
                  : Colors.red.shade400.withOpacity(0.2),
              border: Border.all(
                color: _userProfile!.pinEnabled == 1
                    ? Colors.green.shade400.withOpacity(0.4)
                    : Colors.red.shade400.withOpacity(0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _userProfile!.pinEnabled == 1
                      ? Icons.lock_rounded
                      : Icons.lock_open_rounded,
                  size: 14,
                  color: _userProfile!.pinEnabled == 1
                      ? Colors.green.shade300
                      : Colors.red.shade300,
                ),
                const SizedBox(width: 4),
                Text(
                  _userProfile!.pinEnabled == 1 ? 'PIN On' : 'PIN Off',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _userProfile!.pinEnabled == 1
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header ─────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white.withOpacity(0.4),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  // ── Security Section ───────────────────────────────────────────────────────

  Widget _buildSecuritySection() {
    return _buildCard(
      children: [
        _buildSettingsTile(
          icon: Icons.lock_outline_rounded,
          title: 'PIN Protection',
          subtitle: _userProfile!.pinEnabled == 1 ? 'Enabled' : 'Disabled',
          trailing: Switch(
            value: _userProfile!.pinEnabled == 1,
            activeColor: Colors.green.shade400,
            onChanged: (value) async {
              if (value) {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => _PinChangeScreen(
                      authService: widget.authService,
                    ),
                  ),
                );
                if (result == true) {
                  _loadProfile();
                }
              } else {
                _showDisablePinDialog();
              }
            },
          ),
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.sync_alt_rounded,
          title: 'Cascade Mode',
          subtitle: _userProfile!.cascadeMode == 'soft' ? 'Soft' : 'Strict',
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withOpacity(0.3),
          ),
          onTap: () async {
            final nextMode = _userProfile!.cascadeMode == 'soft' ? 'strict' : 'soft';
            final updated = DbUserProfile(
              id: _userProfile!.id,
              displayName: _userProfile!.displayName,
              monthlyIncome: _userProfile!.monthlyIncome,
              needsRatio: _userProfile!.needsRatio,
              wantsRatio: _userProfile!.wantsRatio,
              flexRatio: _userProfile!.flexRatio,
              emergencyRatio: _userProfile!.emergencyRatio,
              efundTarget: _userProfile!.efundTarget,
              cascadeMode: nextMode,
              pinEnabled: _userProfile!.pinEnabled,
              pinHash: _userProfile!.pinHash,
              biometricEnabled: _userProfile!.biometricEnabled,
            );
            await widget.authService.appRepository.updateUserProfile(updated);
            _loadProfile();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cascade Mode changed to ${nextMode == 'soft' ? 'Soft' : 'Strict'}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.fingerprint_rounded,
          title: 'Biometric Login',
          subtitle: _userProfile!.biometricEnabled == 1 ? 'Enabled' : 'Disabled',
          trailing: Switch(
            value: _userProfile!.biometricEnabled == 1,
            activeColor: Colors.green.shade400,
            onChanged: (value) async {
              if (value) {
                if (_userProfile!.pinEnabled == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enable PIN Protection first as a backup.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                final didAuth = await widget.authService.authenticateWithBiometrics();
                if (didAuth) {
                  final updated = DbUserProfile(
                    id: _userProfile!.id,
                    displayName: _userProfile!.displayName,
                    monthlyIncome: _userProfile!.monthlyIncome,
                    needsRatio: _userProfile!.needsRatio,
                    wantsRatio: _userProfile!.wantsRatio,
                    flexRatio: _userProfile!.flexRatio,
                    emergencyRatio: _userProfile!.emergencyRatio,
                    efundTarget: _userProfile!.efundTarget,
                    cascadeMode: _userProfile!.cascadeMode,
                    pinEnabled: _userProfile!.pinEnabled,
                    pinHash: _userProfile!.pinHash,
                    biometricEnabled: 1,
                  );
                  await widget.authService.appRepository.updateUserProfile(updated);
                  _loadProfile();
                }
              } else {
                final updated = DbUserProfile(
                  id: _userProfile!.id,
                  displayName: _userProfile!.displayName,
                  monthlyIncome: _userProfile!.monthlyIncome,
                  needsRatio: _userProfile!.needsRatio,
                  wantsRatio: _userProfile!.wantsRatio,
                  flexRatio: _userProfile!.flexRatio,
                  emergencyRatio: _userProfile!.emergencyRatio,
                  efundTarget: _userProfile!.efundTarget,
                  cascadeMode: _userProfile!.cascadeMode,
                  pinEnabled: _userProfile!.pinEnabled,
                  pinHash: _userProfile!.pinHash,
                  biometricEnabled: 0,
                );
                await widget.authService.appRepository.updateUserProfile(updated);
                _loadProfile();
              }
            },
          ),
        ),
      ],
    );
  }

  // ── Allocation Section ─────────────────────────────────────────────────────

  Widget _buildAllocationSection() {
    final ratios = [
      _AllocationItem('Needs', _userProfile!.needsRatio, Colors.blue.shade400),
      _AllocationItem('Wants', _userProfile!.wantsRatio, Colors.purple.shade400),
      _AllocationItem('Flex', _userProfile!.flexRatio, Colors.orange.shade400),
      _AllocationItem('Emergency', _userProfile!.emergencyRatio, Colors.red.shade400),
    ];

    return InkWell(
      onTap: _showAllocationEditor,
      borderRadius: BorderRadius.circular(16),
      child: _buildCard(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: ratios.map((r) {
                    final intVal = (r.ratio * 100).round();
                    return Expanded(
                      flex: intVal > 0 ? intVal : 1,
                      child: Container(color: r.color),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          ...ratios.map((r) {
            final amount = _userProfile!.monthlyIncome * r.ratio;
            return _buildSettingsTile(
              icon: Icons.circle,
              iconColor: r.color,
              iconSize: 12,
              title: r.label,
              subtitle: '₱${amount.toStringAsFixed(2)}',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(r.ratio * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withOpacity(0.3),
                    size: 20,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Goals Section ──────────────────────────────────────────────────────────

  Widget _buildGoalsSection(AsyncValue<List<DbSavingsGoal>> goalsAsync, NumberFormat fmt) {
    return _buildCard(
      children: [
        _buildSettingsTile(
          icon: Icons.shield_outlined,
          title: 'Emergency Fund Target',
          subtitle: fmt.format(_userProfile!.efundTarget),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withOpacity(0.3),
          ),
          onTap: _showEFundTargetEditor,
        ),
        _buildDivider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIVE SAVINGS GOALS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              GestureDetector(
                onTap: () => _showSavingsGoalEditor(),
                child: Text(
                  '+ ADD GOAL',
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
        ),
        goalsAsync.when(
          data: (goals) {
            if (goals.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Center(
                  child: Text(
                    'No active savings goals yet. Add one above to start planning!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: goals.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: Colors.white.withOpacity(0.06),
              ),
              itemBuilder: (context, index) {
                final goal = goals[index];
                final progress = goal.targetAmount > 0
                    ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
                    : 0.0;
                final remaining = (goal.targetAmount - goal.currentAmount).clamp(0.0, double.infinity);
                final monthsToTarget = goal.monthlyRate > 0 ? (remaining / goal.monthlyRate).ceil() : 0;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          goal.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.green.shade400,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withOpacity(0.06),
                          color: Colors.green.shade400,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${fmt.format(goal.currentAmount)} of ${fmt.format(goal.targetAmount)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            monthsToTarget > 0
                                ? 'Est: $monthsToTarget mo @ ${fmt.format(goal.monthlyRate)}/mo'
                                : 'Rate: ${fmt.format(goal.monthlyRate)}/mo',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => _showSavingsGoalEditor(goal: goal),
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
            ),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Text(
              'Error loading goals: $err',
              style: TextStyle(color: Colors.red.shade300, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  // ── Allocation Editor Sheet ────────────────────────────────────────────────

  void _showAllocationEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AllocationEditorSheet(
        profile: _userProfile!,
        authService: widget.authService,
        onSaved: () {
          _loadProfile();
          invalidateDashboardProviders(ref);
        },
      ),
    );
  }

  // ── Emergency Fund Target Editor Sheet ──────────────────────────────────────

  void _showEFundTargetEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EFundTargetEditorSheet(
        profile: _userProfile!,
        authService: widget.authService,
        onSaved: () {
          _loadProfile();
          invalidateDashboardProviders(ref);
        },
      ),
    );
  }

  // ── Savings Goal Editor Sheet ──────────────────────────────────────────────

  void _showSavingsGoalEditor({DbSavingsGoal? goal}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SavingsGoalEditorSheet(
        goal: goal,
        onSaved: () {
          invalidateDashboardProviders(ref);
        },
      ),
    );
  }

  void _showInstallmentEditor({DbInstallment? installment}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InstallmentEditorSheet(
        installment: installment,
        onSaved: () {
          ref.invalidate(activeInstallmentsProvider);
          ref.invalidate(totalDebtPaymentsProvider);
          ref.invalidate(monthlyBucketSummaryProvider);
        },
      ),
    );
  }

  void _showRecurringEditor({DbTransaction? template}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecurringTransactionEditorSheet(
        template: template,
        onSaved: () {
          ref.invalidate(recurringTransactionsProvider);
          ref.invalidate(monthlyBucketSummaryProvider);
        },
      ),
    );
  }

  void _showResetApplicationDialog() {
    showDialog(
      context: context,
      builder: (ctx1) => AlertDialog(
        backgroundColor: const Color(0xFF162235),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Application?', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will permanently wipe all local offline SQLite transactions, wallets, goals, and setup data. This cannot be undone.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx1),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx1);
              _confirmResetSecondStep();
            },
            child: Text('Reset', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }

  void _confirmResetSecondStep() {
    showDialog(
      context: context,
      builder: (ctx2) => AlertDialog(
        backgroundColor: const Color(0xFF162235),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('CONFIRM RESET', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you absolutely certain? This will wipe your account and you will have to create a new profile.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx2),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx2);
              // WIPE ALL DATABASE TABLES
              await DatabaseHelper.instance.resetDatabase();
              
              // RE-SEED DEFAULT CATEGORIES SO THEY ARE NOT EMPTY AFTER RESET
              await ref.read(appRepositoryProvider).seedDefaultCategories();
              
              // INVALIDATE ALL RIVERPOD STATES
              // Cashbook
              ref.invalidate(userProfileProvider);
              ref.invalidate(recentTransactionsProvider);
              ref.invalidate(walletBalancesProvider);
              ref.invalidate(netWorthProvider);
              ref.invalidate(monthlyBucketSummaryProvider);
              ref.invalidate(dueRecurringTransactionsProvider);
              ref.invalidate(recurringTransactionsProvider);
              ref.invalidate(expenseCategoriesProvider);
              ref.invalidate(incomeCategoriesProvider);
              ref.invalidate(walletsProvider);

              // Wallet
              ref.invalidate(walletListProvider);
              ref.invalidate(walletBalanceMapProvider);

              // Dashboard
              ref.invalidate(financialHealthScoreProvider);
              ref.invalidate(emergencyFundProgressProvider);
              ref.invalidate(monthlyMetricsHistoryProvider);
              ref.invalidate(dashboardActiveDebtsProvider);
              ref.invalidate(dashboardSavingsGoalsProvider);

              // Debt Payoff & Savings
              ref.invalidate(activeInstallmentsProvider);
              ref.invalidate(totalDebtPaymentsProvider);
              
              // REDIRECT TO ONBOARDING SCREEN
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => CreateAccountScreen(authService: widget.authService),
                  ),
                  (route) => false,
                );
              }
            },
            child: const Text('CONFIRM WIPE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Disable PIN Dialog ─────────────────────────────────────────────────────

  void _showDisablePinDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2940),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Disable PIN?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Your financial data will no longer be protected by a PIN on app launch.',
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.authService.disablePin();
              _loadProfile();
            },
            child: Text(
              'Disable',
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildInstallmentsSection(AsyncValue<List<DbInstallment>> installmentsAsync, NumberFormat fmt) {
    return _buildCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIVE INSTALLMENTS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              GestureDetector(
                onTap: () => _showInstallmentEditor(),
                child: Text(
                  '+ ADD INSTALLMENT',
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
        ),
        installmentsAsync.when(
          data: (installments) {
            if (installments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Center(
                  child: Text(
                    'No active installments. Add one to simulate debts!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: installments.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: Colors.white.withOpacity(0.06),
              ),
              itemBuilder: (context, index) {
                final installment = installments[index];
                final progress = installment.monthsTotal > 0
                    ? ((installment.monthsTotal - installment.monthsRemaining) / installment.monthsTotal).clamp(0.0, 1.0)
                    : 0.0;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          installment.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${installment.monthsTotal - installment.monthsRemaining}/${installment.monthsTotal} mo',
                        style: TextStyle(
                          color: Colors.green.shade400,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withOpacity(0.06),
                          color: Colors.green.shade400,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Monthly: ${fmt.format(installment.monthlyPayment)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'Left: ${fmt.format((installment.monthlyPayment * installment.monthsRemaining).clamp(0.0, double.infinity))}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => _showInstallmentEditor(installment: installment),
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
            ),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Text(
              'Error loading installments: $err',
              style: TextStyle(color: Colors.red.shade300, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecurringSection(AsyncValue<List<DbTransaction>> recurringAsync, NumberFormat fmt) {
    return _buildCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECURRING SALARY & BILLS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              GestureDetector(
                onTap: () => _showRecurringEditor(),
                child: Text(
                  '+ ADD RECURRING',
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
        ),
        recurringAsync.when(
          data: (templates) {
            if (templates.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Center(
                  child: Text(
                    'No recurring transactions configured yet. Add salary or bills above!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: templates.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: Colors.white.withOpacity(0.06),
              ),
              itemBuilder: (context, index) {
                final template = templates[index];
                final isIncome = template.type == 'income';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isIncome ? Colors.green.shade500.withOpacity(0.15) : Colors.red.shade500.withOpacity(0.15),
                    child: Icon(
                      isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      color: isIncome ? Colors.green.shade400 : Colors.red.shade400,
                    ),
                  ),
                  title: Text(
                    template.note ?? 'Recurring Entry',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Day ${template.recurringDay} of the month • Bucket: ${template.bucket.toUpperCase()}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                  trailing: Text(
                    '${isIncome ? "+" : "-"}${fmt.format(template.amount)}',
                    style: TextStyle(
                      color: isIncome ? Colors.green.shade400 : Colors.red.shade400,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () => _showRecurringEditor(template: template),
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
            ),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Text(
              'Error loading recurring templates: $err',
              style: TextStyle(color: Colors.red.shade300, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZoneSection() {
    return _buildCard(
      children: [
        _buildSettingsTile(
          icon: Icons.delete_forever_rounded,
          title: 'Reset Application',
          subtitle: 'Permanently wipe all offline SQLite records',
          iconColor: Colors.red.shade400,
          titleColor: Colors.red.shade300,
          onTap: _showResetApplicationDialog,
        ),
      ],
    );
  }

  // ── Shared Widgets ─────────────────────────────────────────────────────────

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 52,
      color: Colors.white.withOpacity(0.06),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? iconColor,
    Color? titleColor,
    double iconSize = 20,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Colors.green.shade400,
        size: iconSize,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withOpacity(0.45),
          fontSize: 12,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

// ── Helper Model ─────────────────────────────────────────────────────────────

class _AllocationItem {
  final String label;
  final double ratio;
  final Color color;

  _AllocationItem(this.label, this.ratio, this.color);
}

// ── PIN Change Screen (inline, used from Settings toggle) ────────────────────

class _PinChangeScreen extends StatefulWidget {
  final AuthService authService;

  const _PinChangeScreen({required this.authService});

  @override
  State<_PinChangeScreen> createState() => _PinChangeScreenState();
}

class _PinChangeScreenState extends State<_PinChangeScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _hasError = false;
  String _errorMessage = '';

  void _onDigitPressed(String digit) {
    HapticFeedback.lightImpact();
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });

    if (_isConfirming) {
      if (_confirmPin.length < 4) {
        setState(() => _confirmPin += digit);
        if (_confirmPin.length == 4) _validate();
      }
    } else {
      if (_pin.length < 4) {
        setState(() => _pin += digit);
        if (_pin.length == 4) {
          Future.delayed(const Duration(milliseconds: 200), () {
            setState(() => _isConfirming = true);
          });
        }
      }
    }
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();
    setState(() {
      _hasError = false;
      _errorMessage = '';
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  Future<void> _validate() async {
    if (_pin != _confirmPin) {
      HapticFeedback.heavyImpact();
      setState(() {
        _hasError = true;
        _errorMessage = 'PINs do not match. Try again.';
        _confirmPin = '';
        _isConfirming = false;
        _pin = '';
      });
      return;
    }

    await widget.authService.setPin(_pin);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final currentPin = _isConfirming ? _confirmPin : _pin;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1B2D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text(
          'Set New PIN',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),

            Text(
              _isConfirming ? 'Confirm your PIN' : 'Enter a 4-digit PIN',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 32),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final filled = index < currentPin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: filled ? 18 : 16,
                  height: filled ? 18 : 16,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hasError
                        ? Colors.red.shade400
                        : filled
                            ? Colors.green.shade400
                            : Colors.transparent,
                    border: Border.all(
                      color: _hasError
                          ? Colors.red.shade400
                          : filled
                              ? Colors.green.shade400
                              : Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red.shade400, fontSize: 13),
                ),
              ),

            const Spacer(flex: 1),

            _buildNumberPad(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          _buildRow(['1', '2', '3']),
          const SizedBox(height: 16),
          _buildRow(['4', '5', '6']),
          const SizedBox(height: 16),
          _buildRow(['7', '8', '9']),
          const SizedBox(height: 16),
          _buildRow(['', '0', '⌫']),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) {
        if (d.isEmpty) return const SizedBox(width: 72, height: 72);
        if (d == '⌫') {
          return GestureDetector(
            onTap: _onBackspace,
            child: SizedBox(
              width: 72,
              height: 72,
              child: Icon(Icons.backspace_outlined,
                  color: Colors.white.withOpacity(0.7), size: 24),
            ),
          );
        }
        return GestureDetector(
          onTap: () => _onDigitPressed(d),
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.07),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Text(d,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w400)),
          ),
        );
      }).toList(),
    );
  }
}

// ── EXPANDABLE BUDGET RATIO EDITOR SHEET ─────────────────────────────────────

class _AllocationEditorSheet extends StatefulWidget {
  final DbUserProfile profile;
  final AuthService authService;
  final VoidCallback onSaved;

  const _AllocationEditorSheet({
    required this.profile,
    required this.authService,
    required this.onSaved,
  });

  @override
  State<_AllocationEditorSheet> createState() => _AllocationEditorSheetState();
}

class _AllocationEditorSheetState extends State<_AllocationEditorSheet> {
  late double _needs;
  late double _wants;
  late double _flex;
  late double _emergency;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _needs = widget.profile.needsRatio * 100;
    _wants = widget.profile.wantsRatio * 100;
    _flex = widget.profile.flexRatio * 100;
    _emergency = widget.profile.emergencyRatio * 100;
  }

  double get _total => _needs + _wants + _flex + _emergency;

  Future<void> _save() async {
    if (_total.round() != 100) return;
    setState(() => _saving = true);

    final updated = DbUserProfile(
      id: widget.profile.id,
      displayName: widget.profile.displayName,
      monthlyIncome: widget.profile.monthlyIncome,
      needsRatio: _needs / 100,
      wantsRatio: _wants / 100,
      flexRatio: _flex / 100,
      emergencyRatio: _emergency / 100,
      efundTarget: widget.profile.efundTarget,
      cascadeMode: widget.profile.cascadeMode,
      pinEnabled: widget.profile.pinEnabled,
      pinHash: widget.profile.pinHash,
      biometricEnabled: widget.profile.biometricEnabled,
    );

    await widget.authService.updateUserProfile(updated);
    widget.onSaved();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _total.round() == 100;
    final totalColor = isValid ? Colors.green.shade400 : Colors.red.shade400;

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
                    'Budget Allocations',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Adjust category percentages. Cumulative sum must equal exactly 100%.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Cumulative Sum Indicator Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: totalColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: totalColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL RATIO',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          '${_total.toStringAsFixed(0)}% / 100%',
                          style: TextStyle(
                            color: totalColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Needs Slider
                  _buildRatioController(
                    title: 'Needs Ratio',
                    value: _needs,
                    color: Colors.blue.shade400,
                    onChanged: (v) => setState(() => _needs = v.roundToDouble()),
                  ),
                  const SizedBox(height: 16),

                  // Wants Slider
                  _buildRatioController(
                    title: 'Wants Ratio',
                    value: _wants,
                    color: Colors.purple.shade400,
                    onChanged: (v) => setState(() => _wants = v.roundToDouble()),
                  ),
                  const SizedBox(height: 16),

                  // Flex Slider
                  _buildRatioController(
                    title: 'Flex Ratio',
                    value: _flex,
                    color: Colors.orange.shade400,
                    onChanged: (v) => setState(() => _flex = v.roundToDouble()),
                  ),
                  const SizedBox(height: 16),

                  // Emergency Slider
                  _buildRatioController(
                    title: 'Emergency Ratio',
                    value: _emergency,
                    color: Colors.red.shade400,
                    onChanged: (v) => setState(() => _emergency = v.roundToDouble()),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isValid && !_saving ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade500,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.white.withOpacity(0.04),
                        disabledForegroundColor: Colors.white.withOpacity(0.15),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Save Allocations',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

  Widget _buildRatioController({
    required String title,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.remove_rounded, color: Colors.white.withOpacity(0.6)),
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: color,
                  inactiveTrackColor: Colors.white.withOpacity(0.06),
                  thumbColor: color,
                  overlayColor: color.withOpacity(0.15),
                  trackHeight: 4,
                ),
                child: Slider(
                  min: 0,
                  max: 100,
                  value: value,
                  onChanged: onChanged,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_rounded, color: Colors.white.withOpacity(0.6)),
              onPressed: value < 100 ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}

// ── EMERGENCY FUND TARGET EDITOR SHEET ───────────────────────────────────────

class _EFundTargetEditorSheet extends StatefulWidget {
  final DbUserProfile profile;
  final AuthService authService;
  final VoidCallback onSaved;

  const _EFundTargetEditorSheet({
    required this.profile,
    required this.authService,
    required this.onSaved,
  });

  @override
  State<_EFundTargetEditorSheet> createState() => _EFundTargetEditorSheetState();
}

class _EFundTargetEditorSheetState extends State<_EFundTargetEditorSheet> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.profile.efundTarget.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amt = double.tryParse(_ctrl.text.trim());
    if (amt == null || amt < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid positive number')),
      );
      return;
    }

    setState(() => _saving = true);

    final updated = DbUserProfile(
      id: widget.profile.id,
      displayName: widget.profile.displayName,
      monthlyIncome: widget.profile.monthlyIncome,
      needsRatio: widget.profile.needsRatio,
      wantsRatio: widget.profile.wantsRatio,
      flexRatio: widget.profile.flexRatio,
      emergencyRatio: widget.profile.emergencyRatio,
      efundTarget: amt,
      cascadeMode: widget.profile.cascadeMode,
      pinEnabled: widget.profile.pinEnabled,
      pinHash: widget.profile.pinHash,
      biometricEnabled: widget.profile.biometricEnabled,
    );

    await widget.authService.updateUserProfile(updated);
    widget.onSaved();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
                    'Emergency Fund Target',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Set the target threshold for your emergency fund cache.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _ctrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    autofocus: true,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade500,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Save Target Amount',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
}

// ── SAVINGS GOALS CRUD EDITOR SHEET ──────────────────────────────────────────

class _SavingsGoalEditorSheet extends ConsumerStatefulWidget {
  final DbSavingsGoal? goal;
  final VoidCallback? onSaved;

  const _SavingsGoalEditorSheet({
    this.goal,
    this.onSaved,
  });

  @override
  ConsumerState<_SavingsGoalEditorSheet> createState() => _SavingsGoalEditorSheetState();
}

class _SavingsGoalEditorSheetState extends ConsumerState<_SavingsGoalEditorSheet> {
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _nameCtrl.text = widget.goal!.name;
      _targetCtrl.text = widget.goal!.targetAmount.toStringAsFixed(2);
      _currentCtrl.text = widget.goal!.currentAmount.toStringAsFixed(2);
      _rateCtrl.text = widget.goal!.monthlyRate.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _currentCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final target = double.tryParse(_targetCtrl.text.trim()) ?? 0.0;
    final current = double.tryParse(_currentCtrl.text.trim()) ?? 0.0;
    final rate = double.tryParse(_rateCtrl.text.trim()) ?? 0.0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a name')),
      );
      return;
    }
    if (target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid target amount')),
      );
      return;
    }

    setState(() => _saving = true);

    final repo = ref.read(appRepositoryProvider);
    final goalId = widget.goal?.id ?? const Uuid().v4();
    final goal = DbSavingsGoal(
      id: goalId,
      name: name,
      targetAmount: target,
      currentAmount: current,
      monthlyRate: rate,
      isComplete: current >= target ? 1 : 0,
      createdAt: widget.goal?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
    );

    if (widget.goal != null) {
      await repo.updateSavingsGoal(goal);
    } else {
      await repo.insertSavingsGoal(goal);
    }

    // Trigger local updates
    ref.invalidate(dashboardSavingsGoalsProvider);
    if (widget.onSaved != null) widget.onSaved!();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (widget.goal == null) return;
    setState(() => _saving = true);

    // To delete a savings goal, we can update it with isComplete = 1, or remove it.
    // Wait, the repository getActiveSavingsGoals filters by `isComplete = 0`.
    // So completing or marking completed is sufficient, or we can update the row as complete.
    // Let's mark it as complete (isComplete = 1) so it doesn't show up in the active goals list anymore!
    final repo = ref.read(appRepositoryProvider);
    final updatedGoal = DbSavingsGoal(
      id: widget.goal!.id,
      name: widget.goal!.name,
      targetAmount: widget.goal!.targetAmount,
      currentAmount: widget.goal!.currentAmount,
      monthlyRate: widget.goal!.monthlyRate,
      isComplete: 1, // Complete!
      createdAt: widget.goal!.createdAt,
    );

    await repo.updateSavingsGoal(updatedGoal);
    ref.invalidate(dashboardSavingsGoalsProvider);
    if (widget.onSaved != null) widget.onSaved!();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
                    widget.goal != null ? 'Edit Savings Goal' : 'Add Savings Goal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.goal != null ? 'Update your target goal' : 'Set a target savings goal for the future',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _label('GOAL NAME'),
                  const SizedBox(height: 8),
                  _field(_nameCtrl, 'e.g. Dream Laptop, Vacation', Icons.flag_rounded),
                  const SizedBox(height: 16),

                  _label('TARGET AMOUNT'),
                  const SizedBox(height: 8),
                  _numericField(_targetCtrl, '0.00'),
                  const SizedBox(height: 16),

                  _label('CURRENT BALANCE'),
                  const SizedBox(height: 8),
                  _numericField(_currentCtrl, '0.00'),
                  const SizedBox(height: 16),

                  _label('MONTHLY CONTRIBUTION RATE'),
                  const SizedBox(height: 8),
                  _numericField(_rateCtrl, '0.00'),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      if (widget.goal != null) ...[
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
                              child: const Text('Mark Complete'),
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
                                    widget.goal != null ? 'Update Goal' : 'Create Goal',
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
}
