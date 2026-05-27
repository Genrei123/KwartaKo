abstract final class KwartaKoConstants {
  static const int daysInMonth = 30;
  static const int monthsInYear = 12;

  static const double floatingPointTolerance = 0.001;

  // ── Financial Health score ──────────────────────────────────
  static const int    healthComponentCount  = 4;
  static const double healthMaxScore        = 100;
  static const double healthMaxPerComponent = healthMaxScore / healthComponentCount;

  static const int    healthEfTargetMonths    = 6; 
  static const double healthSavingsTargetRate = 0.20; 

  static const double healthEfMultiplier      = healthMaxPerComponent / healthEfTargetMonths;
  static const double healthSavingsMultiplier = healthMaxPerComponent / healthSavingsTargetRate; 

  
}