/// Contrato del repositorio de configuración del restaurante.
///
/// Agrupa: settings, status, hours y roles.
abstract class RestaurantConfigRepository {
  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getRestaurantData(String tenantId);

  Future<void> updateRestaurantData(
      String tenantId, Map<String, dynamic> data);

  Future<void> updateLogoUrl(String tenantId, String url);

  // ---------------------------------------------------------------------------
  // Status operativo
  // ---------------------------------------------------------------------------

  Future<String> getOperationalStatus(String tenantId);

  Future<void> setOperationalStatus(String tenantId, String status);

  // ---------------------------------------------------------------------------
  // Horarios
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getHours(String tenantId);

  Future<void> upsertHour(String id, Map<String, dynamic> data);

  Future<void> insertHour(Map<String, dynamic> data);

  Future<void> deleteHour(String id);

  // ---------------------------------------------------------------------------
  // Roles personalizados
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getRoles(String tenantId);

  Future<Map<String, dynamic>> createRole(Map<String, dynamic> data);

  Future<void> updateRole(String id, Map<String, dynamic> data);

  Future<void> deleteRole(String id);
}
