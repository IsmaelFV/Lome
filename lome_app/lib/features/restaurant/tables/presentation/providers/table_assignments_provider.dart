import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/providers/supabase_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/table_repository_impl.dart';
import '../../domain/repositories/table_repository.dart';
import '../../domain/entities/table_assignment_entity.dart';

// =============================================================================
// Provider: asignaciones activas de camareros a mesas
// =============================================================================

final tableAssignmentsProvider =
    StateNotifierProvider<
      TableAssignmentsNotifier,
      AsyncValue<List<TableAssignmentEntity>>
    >((ref) {
      return TableAssignmentsNotifier(ref);
    });

class TableAssignmentsNotifier
    extends StateNotifier<AsyncValue<List<TableAssignmentEntity>>> {
  final Ref _ref;
  RealtimeChannel? _channel;

  TableAssignmentsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  SupabaseClient get _client => _ref.read(supabaseClientProvider);
  String? get _tenantId => _ref.read(activeTenantIdProvider);
  TableRepository get _repo => _ref.read(tableRepositoryProvider);

  Future<void> _init() async {
    await loadAssignments();
    _subscribeRealtime();
  }

  Future<void> loadAssignments() async {
    final tenantId = _tenantId;
    if (tenantId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final rows = await _repo.getAssignments(tenantId);

      final assignments = rows.map<TableAssignmentEntity>((r) {
        final waiter = r['waiter'] as Map<String, dynamic>?;
        return TableAssignmentEntity(
          id: r['id'] as String,
          tenantId: r['tenant_id'] as String,
          tableId: r['table_id'] as String,
          waiterId: r['waiter_id'] as String,
          waiterName: waiter?['full_name'] as String?,
          assignedBy: r['assigned_by'] as String?,
          isActive: r['is_active'] as bool,
          createdAt: DateTime.parse(r['created_at'] as String),
        );
      }).toList();

      if (mounted) state = AsyncValue.data(assignments);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  void _subscribeRealtime() {
    final tenantId = _tenantId;
    if (tenantId == null) return;

    _channel = _client
        .channel('table-assignments-$tenantId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'table_assignments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tenant_id',
            value: tenantId,
          ),
          callback: (_) => loadAssignments(),
        )
        .subscribe();
  }

  /// Asigna un camarero a una mesa (desactiva la asignación previa si existe).
  Future<void> assignWaiter({
    required String tableId,
    required String waiterId,
  }) async {
    final tenantId = _tenantId;
    if (tenantId == null) return;

    // Desactivar asignación previa
    await _repo.unassignTable(tableId);

    // Crear nueva asignación
    await _repo.assignTable(
      tenantId: tenantId,
      tableId: tableId,
      waiterId: waiterId,
    );

    await loadAssignments();
  }

  /// Desasigna el camarero de una mesa.
  Future<void> unassignWaiter(String tableId) async {
    await _repo.unassignTable(tableId);
    await loadAssignments();
  }

  /// Obtiene la asignación activa para una mesa.
  TableAssignmentEntity? getAssignmentForTable(String tableId) {
    final list = state.valueOrNull ?? [];
    return list.where((a) => a.tableId == tableId).firstOrNull;
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

// =============================================================================
// Provider derivado: asignación activa por mesa
// =============================================================================

final assignmentForTableProvider =
    Provider.family<TableAssignmentEntity?, String>((ref, tableId) {
      final assignments = ref.watch(tableAssignmentsProvider).valueOrNull ?? [];
      return assignments.where((a) => a.tableId == tableId).firstOrNull;
    });

// =============================================================================
// Provider: camareros disponibles para asignar
// =============================================================================

final availableWaitersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.read(tableRepositoryProvider);
  final tenantId = ref.read(activeTenantIdProvider);
  if (tenantId == null) return [];

  return await repo.getAvailableWaiters(tenantId);
});
