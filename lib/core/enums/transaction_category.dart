// lib/core/models/transaction/transaction_category.dart

enum TransactionCategory {
  // ── Income ─────────────────────────────────────────────────────────────
  salary    (id: 1,  name: 'Salary',       isIncome: true),
  freelance (id: 2,  name: 'Freelance',    isIncome: true),
  load      (id: 3,  name: 'GCash Load',   isIncome: true),
  interest  (id: 4,  name: 'Interest',     isIncome: true),

  // ── Expenses ────────────────────────────────────────────────────────────
  food      (id: 5,  name: 'Food',         isIncome: false),
  transport (id: 6,  name: 'Transport',    isIncome: false),
  bills     (id: 7,  name: 'Bills',        isIncome: false),
  debt      (id: 8,  name: 'Debt',         isIncome: false),
  shopping  (id: 9,  name: 'Shopping',     isIncome: false),
  leisure   (id: 10, name: 'Leisure',      isIncome: false),
  health    (id: 11, name: 'Health',       isIncome: false),
  emergency (id: 12, name: 'Emergency',    isIncome: false);

  final int id;
  final String name;
  final bool isIncome;

  const TransactionCategory({
    required this.id,
    required this.name,
    required this.isIncome,
  });

  bool get isExpense => !isIncome;

  /// Lookup by id — useful when reading from SQLite
  static TransactionCategory fromId(int id) {
    return TransactionCategory.values.firstWhere(
      (c) => c.id == id,
      orElse: () => throw ArgumentError('Unknown category id: $id'),
    );
  }
}