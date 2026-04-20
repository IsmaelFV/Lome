import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/providers/supabase_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/table_repository_impl.dart';
import '../../domain/entities/table_entity.dart';
import '../../domain/repositories/table_repository.dart';

// =============================================================================
// Provider principal – carga + Realtime
// =============================================================================

final tablesProvider =
    StateNotifierProvider<TablesNotifier, AsyncValue<List<TableEntity>>>((ref) {
      return TablesNotifier(ref);
    });

class TablesNotifier extends StateNotifier<AsyncValue<List<TableEntity>>> {
  final Ref _ref;
  RealtimeChannel? _channel;

  TablesNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
    // Recargar cuando el tenantId cambie (puede ser null al inicio)
    _ref.listen<String?>(activeTenantIdProvider, (prev, next) {
      if (prev != next && next != null) {
        loadTables();
        _subscribeRealtime();
      }
    });
  }

  TableRepository get _repo => _ref.read(tableRepositoryProvider);
  SupabaseClient get _client => _ref.read(supabaseClientProvider);
  String? get _tenantId => _ref.read(activeTenantIdProvider);

  Future<void> _init() async {
    await loadTables();
    _subscribeRealtime();
  }

  Future<void> loadTables() async {
    final tenantId = _tenantId;
    if (tenantId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final tables = await _repo.getTables(tenantId);
      if (mounted) state = AsyncValue.data(tables);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  void _subscribeRealtime() {
    final tenantId = _tenantId;
    if (tenantId == null) return;

    _channel = _client
        .channel('tables-$tenantId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'restaurant_tables',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tenant_id',
            value: tenantId,
          ),
          callback: (_) => loadTables(),
        )
        .subscribe();
  }

  // ---------------------------------------------------------------------------
  // Mutaciones
  // ---------------------------------------------------------------------------

  Future<void> updateTableStatus(String tableId, TableStatus newStatus) async {
    _optimisticUpdate(tableId, (t) => t.copyWith(status: newStatus));

    try {
      await _repo.updateTableStatus(tableId, newStatus.dbValue);
    } catch (_) {
      await loadTables();
    }
  }

  Future<void> updateTablePosition(String tableId, double x, double y) async {
    _optimisticUpdate(tableId, (t) => t.copyWith(positionX: x, positionY: y));

    try {
      await _repo.updateTablePosition(tableId, x, y);
    } catch (_) {
      await loadTables();
    }
  }

  Future<void> createTable({
    required int number,
    String? name,
    required int capacity,
    String? zone,
    TableShape shape = TableShape.square,
    double positionX = 0,
    double positionY = 0,
    double width = 1.0,
    double height = 1.0,
  }) async {
    final tenantId = _tenantId;
    if (tenantId == null) return;

    await _repo.createTable(tenantId, {
      'number': number,
      'label': name,
      'capacity': capacity,
      'zone': zone,
      'shape': shape.name,
      'position_x': positionX,
      'position_y': positionY,
      'width': width,
      'height': height,
    });

    await loadTables();
  }

  Future<void> updateTable({
    required String tableId,
    int? number,
    String? name,
    int? capacity,
    String? zone,
    TableShape? shape,
    double? width,
    double? height,
  }) async {
    final updates = <String, dynamic>{};
    if (number != null) updates['number'] = number;
    if (name != null) updates['label'] = name;
    if (capacity != null) updates['capacity'] = capacity;
    if (zone != null) updates['zone'] = zone;
    if (shape != null) updates['shape'] = shape.name;
    if (width != null) updates['width'] = width;
    if (height != null) updates['height'] = height;
    if (updates.isEmpty) return;

    await _repo.updateTable(tableId, updates);
    await loadTables();
  }

  Future<void> deleteTable(String tableId) async {
    await _repo.deactivateTable(tableId);
    await loadTables();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _optimisticUpdate(
    String tableId,
    TableEntity Function(TableEntity) updater,
  ) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.map((t) {
        return t.id == tableId ? updater(t) : t;
      }).toList(),
    );
  }

  Future<void> refresh() async => loadTables();

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

// =============================================================================
// Filtros
// =============================================================================

final tableZoneFilterProvider = StateProvider<String?>((ref) => null);

final filteredTablesProvider = Provider<AsyncValue<List<TableEntity>>>((ref) {
  final tables = ref.watch(tablesProvider);
  final zoneFilter = ref.watch(tableZoneFilterProvider);

  return tables.whenData((list) {
    if (zoneFilter == null) return list;
    return list.where((t) => t.zone == zoneFilter).toList();
  });
});

/// Mesa seleccionada en el mapa.
final selectedTableProvider = StateProvider<String?>((ref) => null);
