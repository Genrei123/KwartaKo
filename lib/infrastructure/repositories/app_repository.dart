import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/db_models.dart';

/// A centralized repository handling standard CRUD operations
/// for our main domain entities against the SQLite local database.
class AppRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ---------------------------------------------------------------------------
  // USER PROFILE
  // ---------------------------------------------------------------------------
  Future<void> saveUserProfile(DbUserProfile profile) async {
    final db = await _dbHelper.database;
    await db.insert(
      'user_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DbUserProfile?> getUserProfile() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('user_profile', limit: 1);
    
    if (maps.isNotEmpty) {
      return DbUserProfile.fromMap(maps.first);
    }
    return null; // No user profile set up yet
  }

  Future<void> updateUserProfile(DbUserProfile profile) async {
    final db = await _dbHelper.database;
    await db.update(
      'user_profile',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  // ---------------------------------------------------------------------------
  // WALLETS
  // ---------------------------------------------------------------------------
  Future<void> insertWallet(DbWallet wallet) async {
    final db = await _dbHelper.database;
    await db.insert('wallets', wallet.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<DbWallet>> getAllWallets() async {
    final db = await _dbHelper.database;
    // Only fetch non-archived wallets by default
    final List<Map<String, dynamic>> maps = await db.query(
      'wallets',
      where: 'isArchived = ?',
      whereArgs: [0],
      orderBy: 'createdAt ASC',
    );
    return List.generate(maps.length, (i) => DbWallet.fromMap(maps[i]));
  }

  Future<void> updateWallet(DbWallet wallet) async {
    final db = await _dbHelper.database;
    await db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  /// Calculate wallet balance via transaction sum (source of truth).
  /// balance = startingBalance + SUM(income) - SUM(expense) + SUM(transfer-in) - SUM(transfer-out)
  Future<double> getWalletBalance(String walletId) async {
    final db = await _dbHelper.database;

    // Get starting balance
    final walletMaps = await db.query('wallets', where: 'id = ?', whereArgs: [walletId]);
    if (walletMaps.isEmpty) return 0.0;
    final startingBalance = (walletMaps.first['startingBalance'] as num).toDouble();

    // Sum income for this wallet
    final incomeResult = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE walletId = ? AND type = 'income' AND isRecurring = 0",
      [walletId],
    );
    final totalIncome = (incomeResult.first['total'] as num).toDouble();

    // Sum expenses for this wallet
    final expenseResult = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE walletId = ? AND type = 'expense' AND isRecurring = 0",
      [walletId],
    );
    final totalExpenses = (expenseResult.first['total'] as num).toDouble();

    // Sum transfers INTO this wallet
    final transferInResult = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE transferToWallet = ? AND type = 'transfer' AND isRecurring = 0",
      [walletId],
    );
    final totalTransferIn = (transferInResult.first['total'] as num).toDouble();

    // Sum transfers OUT of this wallet
    final transferOutResult = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE walletId = ? AND type = 'transfer' AND isRecurring = 0",
      [walletId],
    );
    final totalTransferOut = (transferOutResult.first['total'] as num).toDouble();

    return startingBalance + totalIncome - totalExpenses + totalTransferIn - totalTransferOut;
  }

  /// Get all wallet balances as a map of walletId → balance
  Future<Map<String, double>> getAllWalletBalances() async {
    final wallets = await getAllWallets();
    final balances = <String, double>{};
    for (final wallet in wallets) {
      balances[wallet.id] = await getWalletBalance(wallet.id);
    }
    return balances;
  }

  /// Get a single wallet by ID
  Future<DbWallet?> getWalletById(String walletId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('wallets', where: 'id = ?', whereArgs: [walletId]);
    if (maps.isNotEmpty) return DbWallet.fromMap(maps.first);
    return null;
  }

  /// Get transactions for a specific wallet (includes transfers in/out)
  Future<List<DbTransaction>> getTransactionsForWallet(String walletId, {int limit = 100}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: '(walletId = ? OR transferToWallet = ?) AND isRecurring = 0',
      whereArgs: [walletId, walletId],
      orderBy: 'date DESC, createdAt DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => DbTransaction.fromMap(maps[i]));
  }

  /// Archive a wallet (soft delete)
  Future<void> archiveWallet(String walletId) async {
    final db = await _dbHelper.database;
    await db.update(
      'wallets',
      {'isArchived': 1},
      where: 'id = ?',
      whereArgs: [walletId],
    );
  }

  // ---------------------------------------------------------------------------
  // TRANSACTIONS
  // ---------------------------------------------------------------------------
  Future<void> insertTransaction(DbTransaction transaction) async {
    final db = await _dbHelper.database;
    await db.insert('transactions', transaction.toMap());
  }

  Future<void> deleteTransaction(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateTransaction(DbTransaction transaction) async {
    final db = await _dbHelper.database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<List<DbTransaction>> getRecurringTransactions() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'isRecurring = ?',
      whereArgs: [1],
      orderBy: 'recurringDay ASC',
    );
    return List.generate(maps.length, (i) => DbTransaction.fromMap(maps[i]));
  }

  Future<List<DbTransaction>> getRecentTransactions({int limit = 50}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'isRecurring = 0',
      orderBy: 'date DESC, createdAt DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => DbTransaction.fromMap(maps[i]));
  }

  /// Get transactions for a specific month/year
  Future<List<DbTransaction>> getTransactionsForMonth(int month, int year) async {
    final db = await _dbHelper.database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ? AND isRecurring = 0',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC, createdAt DESC',
    );
    return List.generate(maps.length, (i) => DbTransaction.fromMap(maps[i]));
  }

  /// Get monthly bucket spending summary
  Future<Map<String, double>> getMonthlyBucketSpending(int month, int year) async {
    final db = await _dbHelper.database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery('''
      SELECT bucket, COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE type = 'expense' AND date >= ? AND date <= ? AND isRecurring = 0
      GROUP BY bucket
    ''', [startDate, endDate]);

    final spending = <String, double>{
      'needs': 0.0,
      'wants': 0.0,
      'flex': 0.0,
      'emergency': 0.0,
    };

    for (final row in result) {
      final bucket = row['bucket'] as String;
      final total = (row['total'] as num).toDouble();
      spending[bucket] = total;
    }

    return spending;
  }

  /// Get monthly income total
  Future<double> getMonthlyIncome(int month, int year) async {
    final db = await _dbHelper.database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE type = 'income' AND date >= ? AND date <= ? AND isRecurring = 0
    ''', [startDate, endDate]);

    return (result.first['total'] as num).toDouble();
  }

  /// Get total fixed expenses (recurring) this month
  Future<double> getMonthlyFixedExpenses(int month, int year) async {
    final db = await _dbHelper.database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE type = 'expense' AND isRecurring = 1 AND date >= ? AND date <= ?
    ''', [startDate, endDate]);

    return (result.first['total'] as num).toDouble();
  }

  // ---------------------------------------------------------------------------
  // CATEGORIES
  // ---------------------------------------------------------------------------
  Future<void> insertCategory(DbCategory category) async {
    final db = await _dbHelper.database;
    await db.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<DbCategory>> getAllCategories() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('categories', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => DbCategory.fromMap(maps[i]));
  }

  Future<List<DbCategory>> getCategoriesByType(String type) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => DbCategory.fromMap(maps[i]));
  }

  /// Seed default categories on first launch
  Future<void> seedDefaultCategories() async {
    final db = await _dbHelper.database;
    final existing = await db.query('categories', limit: 1);
    if (existing.isNotEmpty) return; // Already seeded

    final defaults = [
      // Income categories
      DbCategory(id: 'cat-salary', name: 'Salary', type: 'income', defaultBucket: 'needs'),
      DbCategory(id: 'cat-freelance', name: 'Freelance', type: 'income', defaultBucket: 'needs'),
      DbCategory(id: 'cat-gcash-load', name: 'GCash Load', type: 'income', defaultBucket: 'flex'),
      DbCategory(id: 'cat-interest', name: 'Interest', type: 'income', defaultBucket: 'emergency'),
      // Expense categories
      DbCategory(id: 'cat-food', name: 'Food', type: 'expense', defaultBucket: 'needs'),
      DbCategory(id: 'cat-transport', name: 'Transport', type: 'expense', defaultBucket: 'needs'),
      DbCategory(id: 'cat-bills', name: 'Bills', type: 'expense', defaultBucket: 'needs'),
      DbCategory(id: 'cat-debt', name: 'Debt', type: 'expense', defaultBucket: 'needs'),
      DbCategory(id: 'cat-shopping', name: 'Shopping', type: 'expense', defaultBucket: 'wants'),
      DbCategory(id: 'cat-leisure', name: 'Leisure', type: 'expense', defaultBucket: 'wants'),
      DbCategory(id: 'cat-health', name: 'Health', type: 'expense', defaultBucket: 'needs'),
      DbCategory(id: 'cat-emergency', name: 'Emergency', type: 'expense', defaultBucket: 'emergency'),
    ];

    final batch = db.batch();
    for (final cat in defaults) {
      batch.insert('categories', cat.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  // ---------------------------------------------------------------------------
  // INSTALLMENTS
  // ---------------------------------------------------------------------------
  Future<void> insertInstallment(DbInstallment installment) async {
    final db = await _dbHelper.database;
    await db.insert('installments', installment.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<DbInstallment>> getActiveInstallments() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'installments',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'startDate ASC',
    );
    return List.generate(maps.length, (i) => DbInstallment.fromMap(maps[i]));
  }

  Future<double> getTotalActiveDebtPayments() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(monthlyPayment), 0) as total FROM installments WHERE isActive = 1",
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<void> updateInstallment(DbInstallment installment) async {
    final db = await _dbHelper.database;
    await db.update(
      'installments',
      installment.toMap(),
      where: 'id = ?',
      whereArgs: [installment.id],
    );
  }

  // ---------------------------------------------------------------------------
  // SAVINGS GOALS
  // ---------------------------------------------------------------------------
  Future<void> insertSavingsGoal(DbSavingsGoal goal) async {
    final db = await _dbHelper.database;
    await db.insert('savings_goals', goal.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<DbSavingsGoal>> getActiveSavingsGoals() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'savings_goals',
      where: 'isComplete = ?',
      whereArgs: [0],
      orderBy: 'createdAt ASC',
    );
    return List.generate(maps.length, (i) => DbSavingsGoal.fromMap(maps[i]));
  }

  Future<void> updateSavingsGoal(DbSavingsGoal goal) async {
    final db = await _dbHelper.database;
    await db.update(
      'savings_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  // ---------------------------------------------------------------------------
  // BUDGET PERIODS
  // ---------------------------------------------------------------------------
  Future<void> upsertBudgetPeriod(DbBudgetPeriod period) async {
    final db = await _dbHelper.database;
    await db.insert(
      'budget_periods',
      period.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DbBudgetPeriod?> getBudgetPeriod(int month, int year) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budget_periods',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return DbBudgetPeriod.fromMap(maps.first);
    }
    return null;
  }
}
