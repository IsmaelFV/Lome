import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/providers/supabase_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';

// =============================================================================
// Permisos canónicos del sistema de roles personalizados
// =============================================================================

/// Lista de permisos disponibles para asignar a roles personalizados.
/// Coinciden con los strings almacenados en la columna JSONB `permissions`.
class CustomPermission {
  final String key;
  final String label;
  final String group;

  const CustomPermission(this.key, this.label, this.group);
}

const List<CustomPermission> availablePermissions = [
  CustomPermission('create_orders', 'Crear pedidos', 'Pedidos'),
  CustomPermission('edit_orders', 'Editar pedidos', 'Pedidos'),
  CustomPermission('cancel_orders', 'Cancelar pedidos', 'Pedidos'),
  CustomPermission('manage_menu', 'Gestionar menú', 'Menú'),
  CustomPermission('view_analytics', 'Ver analíticas', 'Analíticas'),
  CustomPermission('manage_inventory', 'Gestionar inventario', 'Inventario'),
  CustomPermission('view_kitchen', 'Ver cocina', 'Cocina'),
  CustomPermission('manage_tables', 'Gestionar mesas', 'Mesas'),
  CustomPermission('manage_employees', 'Gestionar empleados', 'Equipo'),
  CustomPermission('manage_settings', 'Configuración', 'Sistema'),
  CustomPermission('view_billing', 'Ver facturación', 'Facturación'),
  CustomPermission('manage_billing', 'Gestionar facturación', 'Facturación'),
  CustomPermission('view_activity_logs', 'Ver logs', 'Sistema'),
  CustomPermission('manage_hours', 'Gestionar horarios', 'Sistema'),
  CustomPermission('manage_roles', 'Gestionar roles', 'Sistema'),
];

// =============================================================================
// Modelo
// =============================================================================

class CustomRole {
  final String id;
  final String tenantId;
  final String name;
  final String? description;
  final List<String> permissions;
  final String? color;
  final bool isActive;
  final DateTime createdAt;

  const CustomRole({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    this.permissions = const [],
    this.color,
    this.isActive = true,
    required this.createdAt,
  });

  factory CustomRole.fromJson(Map<String, dynamic> json) {
    final perms = json['permissions'];
    return CustomRole(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      permissions: perms is List ? perms.cast<String>() : <String>[],
      color: json['color'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() => {
    'tenant_id': tenantId,
    'name': name,
    'description': description,
    'permissions': permissions,
    'color': color,
    'is_active': isActive,
  };
}

// =============================================================================
// State
// =============================================================================

class CustomRolesState {
  final List<CustomRole> roles;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const CustomRolesState({
    this.roles = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  CustomRolesState copyWith({
    List<CustomRole>? roles,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return CustomRolesState(
      roles: roles ?? this.roles,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

// =============================================================================
// Provider
// =============================================================================

final customRolesProvider =
    StateNotifierProvider<CustomRolesNotifier, CustomRolesState>((ref) {
      return CustomRolesNotifier(ref);
    });

class CustomRolesNotifier extends StateNotifier<CustomRolesState> {
  final Ref _ref;

  CustomRolesNotifier(this._ref) : super(const CustomRolesState()) {
    loadRoles();
  }

  SupabaseClient get _client => _ref.read(supabaseClientProvider);
  String? get _tenantId => _ref.read(activeTenantIdProvider);

  Future<void> loadRoles() async {
    final tenantId = _tenantId;
    if (tenantId == null) return;

    state = state.copyWith(isLoading: true, clearMessages: true);

    try {
      final rows = await _client
          .from('custom_roles')
          .select()
          .eq('tenant_id', tenantId)
          .order('name');

      final roles = (rows as List).map((r) => CustomRole.fromJson(r)).toList();

      state = state.copyWith(roles: roles, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar roles: $e',
      );
    }
  }

  Future<void> createRole({
    required String name,
    String? description,
    required List<String> permissions,
    String? color,
  }) async {
    final tenantId = _tenantId;
    if (tenantId == null) return;

    state = state.copyWith(isSaving: true, clearMessages: true);

    try {
      await _client.from('custom_roles').insert({
        'tenant_id': tenantId,
        'name': name,
        'description': description,
        'permissions': permissions,
        'color': color,
      });

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Rol "$name" creado correctamente',
      );
      await loadRoles();
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error al crear rol: $e',
      );
    }
  }

  Future<void> updateRole({
    required String roleId,
    required String name,
    String? description,
    required List<String> permissions,
    String? color,
    bool? isActive,
  }) async {
    state = state.copyWith(isSaving: true, clearMessages: true);

    try {
      await _client
          .from('custom_roles')
          .update({
            'name': name,
            'description': description,
            'permissions': permissions,
            'color': color,
            if (isActive != null) 'is_active': isActive,
          })
          .eq('id', roleId);

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Rol actualizado correctamente',
      );
      await loadRoles();
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error al actualizar rol: $e',
      );
    }
  }

  Future<void> deleteRole(String roleId) async {
    state = state.copyWith(isSaving: true, clearMessages: true);

    try {
      await _client.from('custom_roles').delete().eq('id', roleId);

      state = state.copyWith(isSaving: false, successMessage: 'Rol eliminado');
      await loadRoles();
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error al eliminar rol: $e',
      );
    }
  }
}
