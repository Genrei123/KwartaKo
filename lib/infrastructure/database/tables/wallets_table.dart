const String createWalletsTable = '''
  CREATE TABLE wallets (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    startingBalance REAL NOT NULL,
    color TEXT NOT NULL,
    isArchived INTEGER NOT NULL DEFAULT 0,
    createdAt INTEGER NOT NULL
  )
''';
