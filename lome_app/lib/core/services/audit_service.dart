import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/providers/supabase_provider.dart';

// ─── Servicio de Auditoría ───────────────────────────────────────────────────

/// Servicio que registra acciones críticas del usuario en audit_logs.
///
/// Puede usarse directamente o a través de [auditServiceProvider].
///
/// Acciones registradas automáticamente en DB vía triggers:
/// - CRUD de pedidos, pagos, menú, inventario, suscripciones, etc.
///
/// Acciones registradas manualmente desde Flutter:
/// - Login / logout
/// - Navegación a secciones sensibles (admin panel)
/// - Exportación de datos
/// - Cambios de configuración del restaurante
/// - Acciones de moderación (aprobar/rechazar reseñas)
class AuditService {
  final SupabaseClient _client;

  AuditService(this._client);

  /// Registra una acción de auditoría usando la RPC de Supabase.
  Future<void> log({
    required String action,
    required String entityType,
    String? entityId,
    String? tenantId,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _client.rpc('insert_audit_log', params: {
        'p_action': action,
        'p_entity_type': entityType,
        'p_entity_id': entityId,
        'p_tenant_id': tenantId,
        'p_old_data': oldData,
        'p_new_data': newData,
        'p_metadata': metadata ?? {},
      });
    } catch (_) {
      // Silenciar errores de auditoría para no interrumpir el flujo del usuario
    }
  }

  /// Atajos para acciones comunes

  Future<void> logLogin() => log(
        action: 'login',
        entityType: 'auth',
        metadata: {'timestamp': DateTime.now().toIso8601String()},
      );

  Future<void> logLogout() => log(
        action: 'logout',
        entityType: 'auth',
        metadata: {'timestamp': DateTime.now().toIso8601String()},
      );

  Future<void> logAdminAccess(String section) => log(
        action: 'admin_access',
        entityType: 'admin',
        metadata: {'section': section},
      );

  Future<void> logSettingsChange({
    required String tenantId,
    required String setting,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
  }) =>
      log(
        action: 'settings_change',
        entityType: 'tenant_settings',
        tenantId: tenantId,
        oldData: oldValue,
        newData: newValue,
        metadata: {'setting': setting},
      );

  Future<void> logModeration({
    required String action,
    required String entityId,
    String? reason,
  }) =>
      log(
        action: 'moderation_$action',
        entityType: 'review',
        entityId: entityId,
        metadata: {'reason': reason},
      );

  Future<void> logDataExport({
    required String exportType,
    String? tenantId,
  }) =>
      log(
        action: 'data_export',
        entityType: exportType,
        tenantId: tenantId,
      );
}

// ─── Provider ────────────────────────────────────────────────────────────────

final auditServiceProvider = Provider<AuditService>((ref) {
  return AuditService(ref.read(supabaseClientProvider));
});
