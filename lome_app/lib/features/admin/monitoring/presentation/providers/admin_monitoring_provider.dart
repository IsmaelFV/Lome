import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/admin_repository_impl.dart';
import '../../../domain/entities/admin_entities.dart';

// ---------------------------------------------------------------------------
// Filters
// ---------------------------------------------------------------------------

final monitoringPeriodHoursProvider =
    StateProvider<int>((_) => 24);

final errorSeverityFilterProvider =
    StateProvider<String?>((_) => null);

final errorSourceFilterProvider =
    StateProvider<String?>((_) => null);

// ---------------------------------------------------------------------------
// Monitoring dashboard (RPC get_monitoring_dashboard)
// ---------------------------------------------------------------------------

final monitoringDashboardProvider =
    FutureProvider<MonitoringDashboard>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  final hours = ref.watch(monitoringPeriodHoursProvider);

  final response = await repo.getMonitoringDashboard(hours: hours);

  return MonitoringDashboard.fromJson(response);
});

// ---------------------------------------------------------------------------
// Error logs (RPC get_error_logs)
// ---------------------------------------------------------------------------

final errorLogsPageProvider = StateProvider<int>((_) => 0);

final errorLogsProvider =
    FutureProvider<List<ErrorLogEntry>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  final severity = ref.watch(errorSeverityFilterProvider);
  final source = ref.watch(errorSourceFilterProvider);
  final page = ref.watch(errorLogsPageProvider);

  const limit = 50;
  final response = await repo.getErrorLogs(
    severity: severity,
    source: source,
    limit: limit,
    offset: page * limit,
  );

  return response
      .map((r) => ErrorLogEntry.fromJson(r))
      .toList();
});

// ---------------------------------------------------------------------------
// Purge old logs
// ---------------------------------------------------------------------------

final purgeOldLogsProvider =
    FutureProvider.family<Map<String, int>, int>((ref, days) async {
  final repo = ref.read(adminRepositoryProvider);
  final data = await repo.purgeOldLogs(days);

  return {
    'audit_logs': (data['deleted_audit_logs'] as num?)?.toInt() ?? 0,
    'error_logs': (data['deleted_error_logs'] as num?)?.toInt() ?? 0,
    'api_usage_logs': (data['deleted_api_usage_logs'] as num?)?.toInt() ?? 0,
    'performance_metrics':
        (data['deleted_performance_metrics'] as num?)?.toInt() ?? 0,
  };
});
