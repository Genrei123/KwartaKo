const String createInstallmentsTable = '''
  CREATE TABLE installments (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    totalAmount REAL NOT NULL,
    monthlyPayment REAL NOT NULL,
    monthsTotal INTEGER NOT NULL,
    monthsRemaining INTEGER NOT NULL,
    startDate INTEGER NOT NULL,
    walletId TEXT NOT NULL,
    isActive INTEGER NOT NULL DEFAULT 1,
    FOREIGN KEY (walletId) REFERENCES wallets (id) ON DELETE CASCADE
  )
''';
