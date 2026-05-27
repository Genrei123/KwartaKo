const String createUserProfileTable = '''
  CREATE TABLE user_profile (
    id TEXT PRIMARY KEY,
    displayName TEXT NOT NULL,
    monthlyIncome REAL NOT NULL DEFAULT 0.0,
    needsRatio REAL NOT NULL DEFAULT 0.60,
    wantsRatio REAL NOT NULL DEFAULT 0.20,
    flexRatio REAL NOT NULL DEFAULT 0.10,
    emergencyRatio REAL NOT NULL DEFAULT 0.10,
    efundTarget REAL NOT NULL DEFAULT 15000.0,
    cascadeMode TEXT NOT NULL DEFAULT 'soft',
    pinEnabled INTEGER NOT NULL DEFAULT 0,
    pinHash TEXT,
    biometricEnabled INTEGER NOT NULL DEFAULT 0
  )
''';
