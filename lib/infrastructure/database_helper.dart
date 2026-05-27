import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database/tables/user_profile_table.dart';
import 'database/tables/wallets_table.dart';
import 'database/tables/categories_table.dart';
import 'database/tables/transactions_table.dart';
import 'database/tables/installments_table.dart';
import 'database/tables/savings_goals_table.dart';
import 'database/tables/budget_periods_table.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kwartoka.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // To perform a migration, you simply increase the version number
    // e.g., if you release an app update and change your schema, change version to 2.
    return await openDatabase(
      path,
      version: 1, 
      onCreate: _createDB,
      onUpgrade: _upgradeDB, // Handles schema changes on updates
    );
  }

  // ---------------------------------------------------------------------------
  // INITIALIZATION
  // ---------------------------------------------------------------------------
  // onCreate is called exactly ONCE when the app is installed and the database
  // doesn't exist on the device yet.
  Future _createDB(Database db, int version) async {
    // We execute the table creation queries defined in our separated design files
    await db.execute(createUserProfileTable);
    await db.execute(createWalletsTable);
    await db.execute(createCategoriesTable);
    await db.execute(createTransactionsTable);
    await db.execute(createInstallmentsTable);
    await db.execute(createSavingsGoalsTable);
    await db.execute(createBudgetPeriodsTable);
  }

  // ---------------------------------------------------------------------------
  // MIGRATIONS
  // ---------------------------------------------------------------------------
  // onUpgrade is called when you increase the version number in openDatabase().
  // It gives you the oldVersion (what's on the user's phone) and newVersion
  // (the code they just downloaded from the App Store).
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Example migration:
    // if (oldVersion < 2) {
    //   // Scenario: On v2 update, we want to add an 'icon' column to wallets
    //   await db.execute('ALTER TABLE wallets ADD COLUMN icon TEXT');
    // }
    // if (oldVersion < 3) {
    //   // Add another table later...
    // }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  Future<void> resetDatabase() async {
    final db = await database;
    final tables = [
      'user_profile',
      'wallets',
      'categories',
      'transactions',
      'installments',
      'savings_goals',
      'budget_periods',
    ];
    for (final table in tables) {
      await db.delete(table);
    }
  }
}
