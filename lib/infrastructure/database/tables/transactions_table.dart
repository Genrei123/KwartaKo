const String createTransactionsTable = '''
  CREATE TABLE transactions (
    id TEXT PRIMARY KEY,
    date TEXT NOT NULL,
    type TEXT NOT NULL,
    amount REAL NOT NULL,
    walletId TEXT NOT NULL,
    categoryId TEXT NOT NULL,
    bucket TEXT NOT NULL,
    note TEXT,
    isRecurring INTEGER NOT NULL DEFAULT 0,
    recurringDay INTEGER,
    transferToWallet TEXT,
    createdAt INTEGER NOT NULL,
    FOREIGN KEY (walletId) REFERENCES wallets (id) ON DELETE CASCADE,
    FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE RESTRICT
  )
''';
