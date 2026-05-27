enum SpendingPressureIndexInterpretation {
  low('Low', 'Green'),
  moderate('Moderate', 'Yellow'),
  high('High', 'Red');

  final String label;
  final String color;

  const SpendingPressureIndexInterpretation(this.label, this.color);
}

enum SpendingPressureIndexColor {
  green('Green'),
  yellow('Yellow'),
  red('Red');

  final String name;

  const SpendingPressureIndexColor(this.name);
}