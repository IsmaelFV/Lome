import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/admin_repository_impl.dart';
import '../../../domain/entities/admin_entities.dart';

// ---------------------------------------------------------------------------
// Filters
// ---------------------------------------------------------------------------

final auditEntityTypeFilterProvider =
    StateProvider<String?>((_) => null);

final auditActionFilterProvider =
    StateProvider<String?>((_) => null);

final auditPeriodHoursProvider =
    StateProvider<int>((_) => 24);

// ---------------------------------------------------------------------------
// Audit summary (RPC get_audit_summary)
// ---------------------------------------------------------------------------

final auditSummaryProvider = FutureProvider<AuditSummary>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  final hours = ref.watch(auditPeriodHoursProvider);

  final response = await repo.getAuditSummary(hours: hours);

  return AuditSummary.fromJson(response);
});

// ---------------------------------------------------------------------------
// Audit logs (RPC get_audit_logs)
// ---------------------------------------------------------------------------

final auditLogsPageProvider = StateProvider<int>((_) => 0);

final auditLogsProvider =
    FutureProvider<List<AuditLogEntry>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  final entityType = ref.watch(auditEntityTypeFilterProvider);
  final action = ref.watch(auditActionFilterProvider);
  final page = ref.watch(auditLogsPageProvider);

  const limit = 50;
  final response = await repo.getAuditLogs(
    entityType: entityType,
    action: action,
    limit: limit,
    offset: page * limit,
  );

  return response
      .map((r) => AuditLogEntry.fromJson(r))
      .toList();
});
