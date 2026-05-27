class Wallet {
  final int id;
  final String name;
  double _balance;

  Wallet({required this.id, required this.name, required double initialBalance})
      : _balance = initialBalance;

  double get balance => _balance;

  void deposit(double amount) {
    if (amount <= 0) throw ArgumentError('Deposit must be positive');
    _balance += amount;
  }

  void withdraw(double amount) {
    if (amount <= 0) throw ArgumentError('Withdrawal must be positive');
    if (amount > _balance) throw StateError('Insufficient funds in $name');
    _balance -= amount;
  }
}