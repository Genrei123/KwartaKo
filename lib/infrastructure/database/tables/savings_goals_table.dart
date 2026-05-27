const String createSavingsGoalsTable = '''
  CREATE TABLE savings_goals (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    targetAmount REAL NOT NULL,
    currentAmount REAL NOT NULL DEFAULT 0.0,
    monthlyRate REAL NOT NULL,
    deadline INTEGER,
    isComplete INTEGER NOT NULL DEFAULT 0,
    createdAt INTEGER NOT NULL
  )
''';
