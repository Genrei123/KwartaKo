class BudgetAllocation {
  double _needsRatio;
  double _wantsRatio;
  double _flexRatio;
  double _emergencyRatio;

  BudgetAllocation({
    required double needs,
    required double wants,
    required double flex,
    required double emergency,
  }) : _needsRatio = needs,
       _wantsRatio = wants,
       _flexRatio = flex,
       _emergencyRatio = emergency {
    _validateRatios();
  }

  double get needsRatio => _needsRatio;
  double get wantsRatio => _wantsRatio;
  double get flexRatio => _flexRatio;
  double get emergencyRatio => _emergencyRatio;

  void updateRatios({
    double? needs,
    double? wants,
    double? flex,
    double? emergency,
  }) {
    _needsRatio = needs ?? _needsRatio;
    _wantsRatio = wants ?? _wantsRatio;
    _flexRatio = flex ?? _flexRatio;
    _emergencyRatio = emergency ?? _emergencyRatio;
    _validateRatios();
  }

  void _validateRatios() {
    final total = _needsRatio + _wantsRatio + _flexRatio + _emergencyRatio;
    if ((total - 1.0).abs() > 0.001) {
      throw ArgumentError('Budget ratios must strictly add up to 1.0 (100%)');
    }
  }
}