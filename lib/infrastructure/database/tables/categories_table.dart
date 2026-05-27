const String createCategoriesTable = '''
  CREATE TABLE categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    defaultBucket TEXT NOT NULL,
    isCustom INTEGER NOT NULL DEFAULT 0
  )
''';
