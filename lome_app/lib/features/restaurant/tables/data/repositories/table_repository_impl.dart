import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/providers/supabase_provider.dart';
import '../../data/models/table_model.dart';
import '../../domain/entities/table_entity.dart';
import '../../domain/repositories/table_repository.dart';

const _tableSelectQuery = '''
  *,
  table_sessions!left(
    id, guests_count,
    profiles!left(full_name)
  )
''';

/// Implementación Supabase del repositorio de mesas.
class SupabaseTableRepository implements TableRepository {
  final SupabaseClient _client;

  SupabaseTableRepository(this._client);

  // ---------------------------------------------------------------------------
  // Mesas
  // ---------------------------------------------------------------------------

  @override
  Future<List<TableEntity>> getTables(String tenantId) async {
    final rows = await _client
        .from('restaurant_tables')
        .select(_tableSelectQuery)
        .eq('tenant_id', tenantId)
        .eq('is_active', true)
        .eq('table_sessions.is_active', true)
        .order('number');

    return rows.map((r) => TableModel.fromJson(r).toEntity()).toList();
  }

  @override
  Future<void> updateTableStatus(String tableId, String status) async {
    await _client
        .from('restaurant_tables')
        .update({'status': status})
        .eq('id', tableId);
  }

  @override
  Future<void> updateTablePosition(String tableId, double x, double y) async {
    await _client
        .from('restaurant_tables')
        .update({'position_x': x, 'position_y': y})
        .eq('id', tableId);
  }

  @override
  Future<void> createTable(String tenantId, Map<String, dynamic> data) async {
    await _client.from('restaurant_tables').insert({
      'tenant_id': tenantId,
      ...data,
    });
  }

  @override
  Future<void> updateTable(String tableId, Map<String, dynamic> data) async {
    await _client.from('restaurant_tables').update(data).eq('id', tableId);
  }

  @override
  Future<void> deactivateTable(String tableId) async {
    await _client
        .from('restaurant_tables')
        .update({'is_active': false})
        .eq('id', tableId);
  }

  // ---------------------------------------------------------------------------
  // Asignaciones
  // ---------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getAssignments(String tenantId) async {
    return await _client
        .from('table_assignments')
        .select('*, waiter:profiles!waiter_id(full_name)')
        .eq('tenant_id', tenantId)
        .eq('is_active', true)
        .order('created_at');
  }

  @override
  Future<void> assignTable({
    required String tenantId,
    required String tableId,
    required String waiterId,
  }) async {
    await _client.from('table_assignments').insert({
      'tenant_id': tenantId,
      'table_id': tableId,
      'waiter_id': waiterId,
    });
  }

  @override
  Future<void> unassignTable(String tableId) async {
    await _client
        .from('table_assignments')
        .update({'is_active': false})
        .eq('table_id', tableId)
        .eq('is_active', true);
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailableWaiters(
    String tenantId,
  ) async {
    return await _client
        .from('tenant_memberships')
        .select('user_id, profiles(full_name)')
        .eq('tenant_id', tenantId)
        .eq('is_active', true)
        .inFilter('role', ['waiter', 'manager', 'owner']);
  }

  // ---------------------------------------------------------------------------
  // Estadísticas e historial
  // ---------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getTableOccupancyStats(
    String tenantId,
    String startDate,
    String endDate,
  ) async {
    final response = await _client.rpc(
      'get_table_occupancy_stats',
      params: {'p_tenant_id': tenantId, 'p_from': startDate, 'p_to': endDate},
    );
    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<List<Map<String, dynamic>>> getTableHistory(
    String tenantId,
    String tableId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _client.rpc(
      'get_table_history',
      params: {
        'p_tenant_id': tenantId,
        'p_table_id': tableId,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return List<Map<String, dynamic>>.from(response as List);
  }
}

// =============================================================================
// Riverpod Provider
// =============================================================================

final tableRepositoryProvider = Provider<TableRepository>((ref) {
  return SupabaseTableRepository(ref.read(supabaseClientProvider));
});
