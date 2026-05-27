const String createBudgetPeriodsTable = '''
  CREATE TABLE budget_periods (
    id TEXT PRIMARY KEY,
    month INTEGER NOT NULL,
    year INTEGER NOT NULL,
    totalIncome REAL NOT NULL DEFAULT 0.0,
    needsAllocated REAL NOT NULL DEFAULT 0.0,
    wantsAllocated REAL NOT NULL DEFAULT 0.0,
    emergencyAllocated REAL NOT NULL DEFAULT 0.0,
    flexAllocated REAL NOT NULL DEFAULT 0.0,
    totalDebtPayments REAL NOT NULL DEFAULT 0.0,
    needsSpent REAL NOT NULL DEFAULT 0.0,
    wantsSpent REAL NOT NULL DEFAULT 0.0,
    healthScore INTEGER NOT NULL DEFAULT 0,
    savedAt INTEGER NOT NULL
  )
''';
