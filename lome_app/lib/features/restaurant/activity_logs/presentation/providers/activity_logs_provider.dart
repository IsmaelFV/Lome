import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/providers/supabase_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';

// =============================================================================
// Modelo
// =============================================================================

class ActivityLog {
  final String id;
  final String tenantId;
  final String? userId;
  final String? userName;
  final String action;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic> details;
  final DateTime createdAt;

  const ActivityLog({
    required this.id,
    required this.tenantId,
    this.userId,
    this.userName,
    required this.action,
    required this.entityType,
    this.entityId,
    this.details = const {},
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return ActivityLog(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      userId: json['user_id'] as String?,
      userName: profile?['full_name'] as String?,
      action: json['action'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String?,
      details: (json['details'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Etiqueta legible para la acción.
  String get actionLabel {
    return switch (action) {
      'order.created' => 'Pedido creado',
      'order.cancelled' => 'Pedido cancelado',
      'order.updated' => 'Pedido actualizado',
      'order.completed' => 'Pedido completado',
      'menu.created' => 'Plato creado',
      'menu.updated' => 'Plato actualizado',
      'menu.deleted' => 'Plato eliminado',
      'inventory.adjusted' => 'Stock ajustado',
      'inventory.purchase' => 'Compra registrada',
      'inventory.waste' => 'Merma registrada',
      'table.opened' => 'Mesa abierta',
      'table.closed' => 'Mesa cerrada',
      'employee.invited' => 'Empleado invitado',
      'employee.removed' => 'Empleado removido',
      'role.created' => 'Rol creado',
      'role.updated' => 'Rol actualizado',
      'settings.updated' => 'Configuración actualizada',
      'hours.updated' => 'Horario actualizado',
      _ => action,
    };
  }

  String get entityLabel {
    return switch (entityType) {
      'order' => 'Pedido',
      'menu_item' => 'Plato',
      'inventory' => 'Inventario',
      'table' => 'Mesa',
      'employee' => 'Empleado',
      'role' => 'Rol',
      'settings' => 'Configuración',
      'hours' => 'Horario',
      _ => entityType,
    };
  }
}

// =============================================================================
// State
// =============================================================================

class ActivityLogsState {
  final List<ActivityLog> logs;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final String? filterEntity;

  const ActivityLogsState({
    this.logs = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
    this.filterEntity,
  });

  ActivityLogsState copyWith({
    List<ActivityLog>? logs,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    String? filterEntity,
    bool clearError = false,
    bool clearFilter = false,
  }) {
    return ActivityLogsState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      filterEntity: clearFilter ? null : (filterEntity ?? this.filterEntity),
    );
  }
}

// =============================================================================
// Provider
// =============================================================================

final activityLogsProvider =
    StateNotifierProvider<ActivityLogsNotifier, ActivityLogsState>((ref) {
      return ActivityLogsNotifier(ref);
    });

class ActivityLogsNotifier extends StateNotifier<ActivityLogsState> {
  final Ref _ref;
  static const _pageSize = 30;

  ActivityLogsNotifier(this._ref) : super(const ActivityLogsState()) {
    loadLogs();
  }

  SupabaseClient get _client => _ref.read(supabaseClientProvider);
  String? get _tenantId => _ref.read(activeTenantIdProvider);

  Future<void> loadLogs() async {
    final tenantId = _tenantId;
    if (tenantId == null) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      logs: [],
      hasMore: true,
    );

    try {
      var query = _client
          .from('activity_logs')
          .select('*, profiles(full_name)')
          .eq('tenant_id', tenantId);

      if (state.filterEntity != null) {
        query = query.eq('entity_type', state.filterEntity!);
      }

      final rows = await query
          .order('created_at', ascending: false)
          .limit(_pageSize);

      final logs = (rows as List).map((r) => ActivityLog.fromJson(r)).toList();

      state = state.copyWith(
        logs: logs,
        isLoading: false,
        hasMore: logs.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar logs: $e',
      );
    }
  }

  Future<void> loadMore() async {
    final tenantId = _tenantId;
    if (tenantId == null || !state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final lastDate = state.logs.last.createdAt.toIso8601String();

      var query = _client
          .from('activity_logs')
          .select('*, profiles(full_name)')
          .eq('tenant_id', tenantId)
          .lt('created_at', lastDate);

      if (state.filterEntity != null) {
        query = query.eq('entity_type', state.filterEntity!);
      }

      final rows = await query
          .order('created_at', ascending: false)
          .limit(_pageSize);

      final newLogs = (rows as List)
          .map((r) => ActivityLog.fromJson(r))
          .toList();

      state = state.copyWith(
        logs: [...state.logs, ...newLogs],
        isLoadingMore: false,
        hasMore: newLogs.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void setFilter(String? entityType) {
    if (entityType == state.filterEntity) return;
    state = state.copyWith(
      filterEntity: entityType,
      clearFilter: entityType == null,
    );
    loadLogs();
  }

  /// Inserta un log de actividad desde el frontend.
  Future<void> log({
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? details,
  }) async {
    final tenantId = _tenantId;
    if (tenantId == null) return;

    try {
      await _client.from('activity_logs').insert({
        'tenant_id': tenantId,
        'user_id': _ref.read(supabaseClientProvider).auth.currentUser?.id,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'details': details ?? {},
      });
    } catch (_) {
      // Los logs no deben bloquear flujos principales
    }
  }
}
