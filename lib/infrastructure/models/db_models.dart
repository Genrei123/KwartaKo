// This file contains the strongly typed Dart models that map directly to our SQLite tables.
// Each class includes toMap() and fromMap() functions for easy CRUD operations.

class DbWallet {
  final String id;
  final String name;
  final double startingBalance;
  final String color;
  final int isArchived; // 0 or 1
  final int createdAt;

  DbWallet({
    required this.id,
    required this.name,
    required this.startingBalance,
    required this.color,
    this.isArchived = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'startingBalance': startingBalance,
        'color': color,
        'isArchived': isArchived,
        'createdAt': createdAt,
      };

  factory DbWallet.fromMap(Map<String, dynamic> map) => DbWallet(
        id: map['id'],
        name: map['name'],
        startingBalance: (map['startingBalance'] as num).toDouble(),
        color: map['color'],
        isArchived: map['isArchived'],
        createdAt: map['createdAt'],
      );
}

class DbTransaction {
  final String id;
  final String date; // ISO 8601 string
  final String type; // 'income' | 'expense' | 'transfer'
  final double amount;
  final String walletId;
  final String categoryId;
  final String bucket;
  final String? note;
  final int isRecurring; // 0 or 1
  final int? recurringDay;
  final String? transferToWallet;
  final int createdAt;

  DbTransaction({
    required this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.walletId,
    required this.categoryId,
    required this.bucket,
    this.note,
    this.isRecurring = 0,
    this.recurringDay,
    this.transferToWallet,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'type': type,
        'amount': amount,
        'walletId': walletId,
        'categoryId': categoryId,
        'bucket': bucket,
        'note': note,
        'isRecurring': isRecurring,
        'recurringDay': recurringDay,
        'transferToWallet': transferToWallet,
        'createdAt': createdAt,
      };

  factory DbTransaction.fromMap(Map<String, dynamic> map) => DbTransaction(
        id: map['id'],
        date: map['date'],
        type: map['type'],
        amount: (map['amount'] as num).toDouble(),
        walletId: map['walletId'],
        categoryId: map['categoryId'],
        bucket: map['bucket'],
        note: map['note'],
        isRecurring: map['isRecurring'],
        recurringDay: map['recurringDay'],
        transferToWallet: map['transferToWallet'],
        createdAt: map['createdAt'],
      );
}

class DbCategory {
  final String id;
  final String name;
  final String type; // 'income' | 'expense'
  final String defaultBucket;
  final int isCustom; // 0 or 1

  DbCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.defaultBucket,
    this.isCustom = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'defaultBucket': defaultBucket,
        'isCustom': isCustom,
      };

  factory DbCategory.fromMap(Map<String, dynamic> map) => DbCategory(
        id: map['id'],
        name: map['name'],
        type: map['type'],
        defaultBucket: map['defaultBucket'],
        isCustom: map['isCustom'],
      );
}

class DbUserProfile {
  final String id;
  final String displayName;
  final double monthlyIncome;
  final double needsRatio;
  final double wantsRatio;
  final double flexRatio;
  final double emergencyRatio;
  final double efundTarget;
  final String cascadeMode;
  final int pinEnabled;
  final String? pinHash;
  final int biometricEnabled;

  DbUserProfile({
    required this.id,
    required this.displayName,
    required this.monthlyIncome,
    this.needsRatio = 0.60,
    this.wantsRatio = 0.20,
    this.flexRatio = 0.10,
    this.emergencyRatio = 0.10,
    this.efundTarget = 15000.0,
    this.cascadeMode = 'soft',
    this.pinEnabled = 0,
    this.pinHash,
    this.biometricEnabled = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'displayName': displayName,
        'monthlyIncome': monthlyIncome,
        'needsRatio': needsRatio,
        'wantsRatio': wantsRatio,
        'flexRatio': flexRatio,
        'emergencyRatio': emergencyRatio,
        'efundTarget': efundTarget,
        'cascadeMode': cascadeMode,
        'pinEnabled': pinEnabled,
        'pinHash': pinHash,
        'biometricEnabled': biometricEnabled,
      };

  factory DbUserProfile.fromMap(Map<String, dynamic> map) => DbUserProfile(
        id: map['id'],
        displayName: map['displayName'],
        monthlyIncome: (map['monthlyIncome'] as num).toDouble(),
        needsRatio: (map['needsRatio'] as num).toDouble(),
        wantsRatio: (map['wantsRatio'] as num).toDouble(),
        flexRatio: (map['flexRatio'] as num).toDouble(),
        emergencyRatio: (map['emergencyRatio'] as num).toDouble(),
        efundTarget: (map['efundTarget'] as num).toDouble(),
        cascadeMode: map['cascadeMode'],
        pinEnabled: map['pinEnabled'],
        pinHash: map['pinHash'],
        biometricEnabled: map['biometricEnabled'],
      );
}

class DbInstallment {
  final String id;
  final String name;
  final double totalAmount;
  final double monthlyPayment;
  final int monthsTotal;
  final int monthsRemaining;
  final int startDate;
  final String walletId;
  final int isActive; // 0 or 1
  final String paidMonths; // Comma-separated list of paid month numbers (e.g., "1,2,4,5")

  DbInstallment({
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.monthlyPayment,
    required this.monthsTotal,
    required this.monthsRemaining,
    required this.startDate,
    required this.walletId,
    this.isActive = 1,
    this.paidMonths = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'totalAmount': totalAmount,
        'monthlyPayment': monthlyPayment,
        'monthsTotal': monthsTotal,
        'monthsRemaining': monthsRemaining,
        'startDate': startDate,
        'walletId': walletId,
        'isActive': isActive,
        'paidMonths': paidMonths,
      };

  factory DbInstallment.fromMap(Map<String, dynamic> map) => DbInstallment(
        id: map['id'],
        name: map['name'],
        totalAmount: (map['totalAmount'] as num).toDouble(),
        monthlyPayment: (map['monthlyPayment'] as num).toDouble(),
        monthsTotal: map['monthsTotal'],
        monthsRemaining: map['monthsRemaining'],
        startDate: map['startDate'],
        walletId: map['walletId'],
        isActive: map['isActive'],
        paidMonths: map['paidMonths'] ?? '',
      );
}

class DbSavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final double monthlyRate;
  final int? deadline; // Unix timestamp, nullable
  final int isComplete; // 0 or 1
  final int createdAt;

  DbSavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.monthlyRate,
    this.deadline,
    this.isComplete = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'monthlyRate': monthlyRate,
        'deadline': deadline,
        'isComplete': isComplete,
        'createdAt': createdAt,
      };

  factory DbSavingsGoal.fromMap(Map<String, dynamic> map) => DbSavingsGoal(
        id: map['id'],
        name: map['name'],
        targetAmount: (map['targetAmount'] as num).toDouble(),
        currentAmount: (map['currentAmount'] as num).toDouble(),
        monthlyRate: (map['monthlyRate'] as num).toDouble(),
        deadline: map['deadline'],
        isComplete: map['isComplete'],
        createdAt: map['createdAt'],
      );
}

class DbBudgetPeriod {
  final String id;
  final int month;
  final int year;
  final double totalIncome;
  final double needsAllocated;
  final double wantsAllocated;
  final double emergencyAllocated;
  final double flexAllocated;
  final double totalDebtPayments;
  final double needsSpent;
  final double wantsSpent;
  final int healthScore;
  final int savedAt;

  DbBudgetPeriod({
    required this.id,
    required this.month,
    required this.year,
    this.totalIncome = 0.0,
    this.needsAllocated = 0.0,
    this.wantsAllocated = 0.0,
    this.emergencyAllocated = 0.0,
    this.flexAllocated = 0.0,
    this.totalDebtPayments = 0.0,
    this.needsSpent = 0.0,
    this.wantsSpent = 0.0,
    this.healthScore = 0,
    required this.savedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'month': month,
        'year': year,
        'totalIncome': totalIncome,
        'needsAllocated': needsAllocated,
        'wantsAllocated': wantsAllocated,
        'emergencyAllocated': emergencyAllocated,
        'flexAllocated': flexAllocated,
        'totalDebtPayments': totalDebtPayments,
        'needsSpent': needsSpent,
        'wantsSpent': wantsSpent,
        'healthScore': healthScore,
        'savedAt': savedAt,
      };

  factory DbBudgetPeriod.fromMap(Map<String, dynamic> map) => DbBudgetPeriod(
        id: map['id'],
        month: map['month'],
        year: map['year'],
        totalIncome: (map['totalIncome'] as num).toDouble(),
        needsAllocated: (map['needsAllocated'] as num).toDouble(),
        wantsAllocated: (map['wantsAllocated'] as num).toDouble(),
        emergencyAllocated: (map['emergencyAllocated'] as num).toDouble(),
        flexAllocated: (map['flexAllocated'] as num).toDouble(),
        totalDebtPayments: (map['totalDebtPayments'] as num).toDouble(),
        needsSpent: (map['needsSpent'] as num).toDouble(),
        wantsSpent: (map['wantsSpent'] as num).toDouble(),
        healthScore: map['healthScore'],
        savedAt: map['savedAt'],
      );
}
