import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/models/db_models.dart';
import '../../features/cashbook/cashbook_providers.dart';
import '../dashboard/dashboard_service.dart';
import '../../core/models/FinancialHealthScore/financial_health_score_result.dart';

// ---------------------------------------------------------------------------
// CORE PROVIDERS
// ---------------------------------------------------------------------------

/// Dashboard service provider
final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService(repository: ref.watch(appRepositoryProvider));
});

// ---------------------------------------------------------------------------
// DATA PROVIDERS
// ---------------------------------------------------------------------------

/// Financial Health Score (F5) provider
final financialHealthScoreProvider = FutureProvider<HealthScoreResult?>((ref) {
  return ref.watch(dashboardServiceProvider).getFinancialHealthScore();
});

/// Emergency Fund progress provider
final emergencyFundProgressProvider = FutureProvider<EmergencyFundProgress>((ref) {
  return ref.watch(dashboardServiceProvider).getEmergencyFundProgress();
});

/// Last 6 months metrics history provider (for charts)
final monthlyMetricsHistoryProvider = FutureProvider<List<MonthlyMetrics>>((ref) {
  return ref.watch(dashboardServiceProvider).getMonthlyMetricsHistory(limit: 6);
});

/// Active installments provider scoped to dashboard
final dashboardActiveDebtsProvider = FutureProvider<List<DbInstallment>>((ref) {
  return ref.watch(dashboardServiceProvider).getActiveInstallments();
});

/// Active savings goals provider scoped to dashboard
final dashboardSavingsGoalsProvider = FutureProvider<List<DbSavingsGoal>>((ref) {
  return ref.watch(dashboardServiceProvider).getActiveSavingsGoals();
});

// ---------------------------------------------------------------------------
// INVALIDATION HELPER
// ---------------------------------------------------------------------------

/// Call this after any transactions or database modifications to refresh the dashboard
void invalidateDashboardProviders(WidgetRef ref) {
  ref.invalidate(financialHealthScoreProvider);
  ref.invalidate(emergencyFundProgressProvider);
  ref.invalidate(monthlyMetricsHistoryProvider);
  ref.invalidate(dashboardActiveDebtsProvider);
  ref.invalidate(dashboardSavingsGoalsProvider);
}
