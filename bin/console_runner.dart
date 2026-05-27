import 'package:kwartako/core/models/Budget/budget_allocation.dart';
import 'package:kwartako/core/enums/transaction_category.dart';
import 'package:kwartako/core/models/User/cascade_mode.dart';
import 'package:kwartako/core/models/User/user.dart';
import 'package:kwartako/core/models/wallet.dart';
import 'package:kwartako/core/models/Transaction/transaction_recurring_config.dart';
import 'package:kwartako/core/formulas/allocation_engine.dart';
import 'package:kwartako/core/models/Budget/budget_ratios.dart';

void main() {
  // ── Setup ──────────────────────────────────────────────────────────────────

  final wallet = Wallet(id: 1, name: 'BDO', initialBalance: 0.0);
  final gcash = Wallet(id: 2, name: 'GCash', initialBalance: 200.0);

  // Fixed: ratios now sum to exactly 1.0 (0.6 + 0.2 + 0.1 + 0.1 = 1.0)
  final genrey = User(
    id: 1,
    displayName: 'Genrey',
    monthlyIncome: 30000.0,
    cascadeMode: CascadeMode.soft,
    allocation: BudgetAllocation(
      needs: 0.60,
      wants: 0.20,
      flex: 0.10,
      emergency: 0.10,
    ),
    wallets: [wallet, gcash],
    pinHash: 'hashed_pin_value',
  );

  // ── Settings Dashboard ─────────────────────────────────────────────────────

  print('════════════════════════════════════════');
  print(' SETTINGS DASHBOARD');
  print('════════════════════════════════════════');
  print('Name          : ${genrey.displayName}');
  print('Monthly income: ₱${genrey.monthlyIncome.toStringAsFixed(2)}');
  print('Cascade mode  : ${genrey.cascadeMode.name}');
  print('PIN           : ${genrey.pinHash.isNotEmpty ? 'Set' : 'Not Set'}');
  print(
    'Allocation    : '
    'Needs ${genrey.allocation.needsRatio * 100}% | '
    'Wants ${genrey.allocation.wantsRatio * 100}% | '
    'Flex ${genrey.allocation.flexRatio * 100}% | '
    'Emergency ${genrey.allocation.emergencyRatio * 100}%',
  );

  // ── Wallet Dashboard ───────────────────────────────────────────────────────

  print('\n════════════════════════════════════════');
  print(' WALLET DASHBOARD');
  print('════════════════════════════════════════');
  for (final w in genrey.wallets) {
    print('${w.name.padRight(10)}: ₱${w.balance.toStringAsFixed(2)}');
  }
  final netWorthBefore = genrey.wallets.fold(0.0, (sum, w) => sum + w.balance);
  print('Net worth     : ₱${netWorthBefore.toStringAsFixed(2)}');

  // ── Cashbook — Log income ──────────────────────────────────────────────────

  print('\n════════════════════════════════════════');
  print(' CASHBOOK');
  print('════════════════════════════════════════');

  print('\n── Logging salary income ──');
  genrey.receiveIncome(
    transactionId: 1,
    amount: 30000.0,
    targetWallet: wallet,
    categories: [TransactionCategory.salary],
    note: 'May 2026 salary',
  );
  print('BDO balance: ₱${wallet.balance.toStringAsFixed(2)}');

  // Allocation engine fires after income
  final allocationEngine = AllocationEngine(
    ratios: BudgetRatios(
      emergency: genrey.allocation.emergencyRatio,
      needs: genrey.allocation.needsRatio,
      wants: genrey.allocation.wantsRatio,
      flex: genrey.allocation.flexRatio,
    ),
  );
  final allocation = allocationEngine.calculate(
    incomeAmount: 30000,
    activeInstallments: [4500], // cellphone debt
  );
  print('\nAllocation breakdown:');
  print(allocation);

  // ── Cashbook — Log one-time expense ───────────────────────────────────────

  print('── Logging one-time expense (coffee) ──');
  genrey.spendMoney(
    transactionId: 2,
    amount: 150.0,
    sourceWallet: gcash,
    categories: [TransactionCategory.food],
    note: 'Coffee at the office',
  );
  print('GCash balance: ₱${gcash.balance.toStringAsFixed(2)}');

  // ── Cashbook — Log recurring transactions ─────────────────────────────────

  print('\n── Logging recurring transactions ──');

  // Salary — recurring every 15th (already logged above as one-time,
  // this registers it as recurring for future months)
  genrey.receiveRecurringIncome(
    transactionId: 3,
    amount: 30000.0,
    targetWallet: wallet,
    categories: [TransactionCategory.salary],
    recurringConfig: RecurringConfig.monthly(
      startDate: DateTime(2026, 5, 15),
      day: 15,
    ),
    note: 'EastWest Bank salary — every 15th',
  );
  print('Registered: Salary ₱30,000 every 15th forever');

  // WiFi bill — every 1st of the month
  genrey.spendRecurringMoney(
    transactionId: 4,
    amount: 1500.0,
    sourceWallet: wallet,
    categories: [TransactionCategory.bills],
    recurringConfig: RecurringConfig.monthly(
      startDate: DateTime(2026, 6, 1),
      day: 1,
    ),
    note: 'Monthly WiFi bill',
  );
  print('Registered: WiFi ₱1,500 every 1st forever');

  // Electric bill — every 5th of the month
  genrey.spendRecurringMoney(
    transactionId: 5,
    amount: 4000.0,
    sourceWallet: wallet,
    categories: [TransactionCategory.bills],
    recurringConfig: RecurringConfig.monthly(
      startDate: DateTime(2026, 6, 5),
      day: 5,
    ),
    note: 'Monthly electric bill',
  );
  print('Registered: Electric ₱4,000 every 5th forever');

  // Cellphone debt — ends October 15, 2026 (5 months remaining)
  genrey.spendRecurringMoney(
    transactionId: 6,
    amount: 4500.0,
    sourceWallet: wallet,
    categories: [TransactionCategory.debt],
    recurringConfig: RecurringConfig.monthly(
      startDate: DateTime(2026, 5, 15),
      day: 15,
      endDate: DateTime(2026, 10, 15),
    ),
    note: 'Cellphone installment — 5 months remaining',
  );
  print('Registered: Cellphone debt ₱4,500 every 15th until Oct 2026');

  // ── Recurring — show what fires this month ─────────────────────────────────

  print('\n── Recurring transactions firing in June 2026 ──');
  final juneStart = DateTime(2026, 6, 1);
  final juneEnd = DateTime(2026, 6, 30);

  final recurringThisMonth = genrey.transactions
      .where((t) => t.isRecurring)
      .where(
        (t) => t.recurringConfig!
            .allOccurrencesBetween(juneStart, juneEnd)
            .isNotEmpty,
      )
      .toList();

  for (final t in recurringThisMonth) {
    final dates = t.recurringConfig!.allOccurrencesBetween(juneStart, juneEnd);
    final dateStr = dates.map((d) => d.toString().split(' ')[0]).join(', ');
    print(
      '  ${t.note?.padRight(40) ?? 'No note'.padRight(40)} '
      '₱${t.amount.toStringAsFixed(2).padLeft(10)} '
      'fires: $dateStr',
    );
  }

  // Total recurring expenses this month
  final totalRecurringExpenses = recurringThisMonth
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);
  print(
    '\nTotal recurring expenses in June: ₱${totalRecurringExpenses.toStringAsFixed(2)}',
  );

  // ── Cashbook — Transaction history ────────────────────────────────────────

  print('\n── Full transaction history ──');
  for (final t in genrey.transactions) {
    print(
      '  #${t.id.toString().padLeft(2)} '
      '[${t.type.name.padRight(7)}] '
      '₱${t.amount.toStringAsFixed(2).padLeft(10)} '
      '${t.wallet.name.padRight(8)} '
      '${t.categories.map((c) => c.name).join(', ').padRight(15)} '
      '${t.isRecurring ? '🔁 ${t.recurringConfig}' : '  one-time'}',
    );
  }

  // ── Cashbook — Filter by category ─────────────────────────────────────────

  print('\n── Filtered: Bills only ──');
  final bills = genrey.transactions.where(
    (t) => t.categories.contains(TransactionCategory.bills),
  );
  for (final t in bills) {
    print('  ${t.note ?? 'No note'}: ₱${t.amount.toStringAsFixed(2)}');
  }

  // ── Net worth ──────────────────────────────────────────────────────────────

  print('\n════════════════════════════════════════');
  print(' NET WORTH');
  print('════════════════════════════════════════');
  for (final w in genrey.wallets) {
    print('${w.name.padRight(10)}: ₱${w.balance.toStringAsFixed(2)}');
  }
  final netWorth = genrey.wallets.fold(0.0, (sum, w) => sum + w.balance);
  print('Total         : ₱${netWorth.toStringAsFixed(2)}');
}
