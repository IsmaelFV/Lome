import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/config/supabase_config.dart';
import '../../../data/repositories/admin_repository_impl.dart';
import '../../../domain/entities/admin_entities.dart';

// ---------------------------------------------------------------------------
// Incident filter
// ---------------------------------------------------------------------------

final incidentStatusFilterProvider =
    StateProvider<String>((_) => 'open'); // open, in_progress, resolved, closed

// ---------------------------------------------------------------------------
// Incidents list
// ---------------------------------------------------------------------------

final adminIncidentsProvider =
    FutureProvider<List<Incident>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  final statusFilter = ref.watch(incidentStatusFilterProvider);

  final response = await repo.getIncidents(status: statusFilter);

  return response
      .map((r) => Incident.fromJson(r))
      .toList();
});

// ---------------------------------------------------------------------------
// Incident counts by priority (for current status filter)
// ---------------------------------------------------------------------------

final incidentPriorityCountsProvider =
    Provider<Map<String, int>>((ref) {
  final incidents = ref.watch(adminIncidentsProvider).valueOrNull ?? [];
  return {
    'critical': incidents.where((i) => i.priority == 'critical').length,
    'high': incidents.where((i) => i.priority == 'high').length,
    'medium': incidents.where((i) => i.priority == 'medium').length,
    'low': incidents.where((i) => i.priority == 'low').length,
  };
});

// ---------------------------------------------------------------------------
// All open+in_progress counts (for badge)
// ---------------------------------------------------------------------------

final incidentOpenCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.getOpenIncidentCount();
});

// ---------------------------------------------------------------------------
// Single incident detail
// ---------------------------------------------------------------------------

final adminIncidentDetailProvider =
    FutureProvider.family<Incident?, String>((ref, id) async {
  final repo = ref.read(adminRepositoryProvider);
  final response = await repo.getIncidentDetail(id);

  if (response == null) return null;
  return Incident.fromJson(response);
});

// ---------------------------------------------------------------------------
// Update incident status
// ---------------------------------------------------------------------------

final updateIncidentStatusProvider =
    FutureProvider.family<void, ({String id, String newStatus})>(
        (ref, params) async {
  final repo = ref.read(adminRepositoryProvider);
  final userId = SupabaseConfig.auth.currentUser!.id;

  await repo.updateIncidentStatus(
    params.id,
    params.newStatus,
    resolvedBy: userId,
  );

  ref.invalidate(adminIncidentsProvider);
  ref.invalidate(adminIncidentDetailProvider(params.id));
  ref.invalidate(incidentOpenCountProvider);
});

// ---------------------------------------------------------------------------
// Create incident
// ---------------------------------------------------------------------------

final createIncidentProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, data) async {
  final repo = ref.read(adminRepositoryProvider);
  final userId = SupabaseConfig.auth.currentUser!.id;
  await repo.createIncident({
    ...data,
    'reported_by': userId,
  });
  ref.invalidate(adminIncidentsProvider);
  ref.invalidate(incidentOpenCountProvider);
});

// ---------------------------------------------------------------------------
// Update incident resolution
// ---------------------------------------------------------------------------

final resolveIncidentProvider =
    FutureProvider.family<void, ({String id, String resolution})>(
        (ref, params) async {
  final repo = ref.read(adminRepositoryProvider);
  final userId = SupabaseConfig.auth.currentUser!.id;
  await repo.resolveIncident(
    params.id,
    params.resolution,
    resolvedBy: userId,
  );

  ref.invalidate(adminIncidentsProvider);
  ref.invalidate(adminIncidentDetailProvider(params.id));
  ref.invalidate(incidentOpenCountProvider);
});
