/// Contrato del repositorio de soporte del restaurante.
///
/// Agrupa: dashboard stats, notificaciones, activity logs, menú.
abstract class RestaurantSupportRepository {
  // ---------------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------------

  Future<double> fetchSalesToday(String tenantId);

  Future<int> fetchActiveOrdersCount(String tenantId);

  Future<Map<String, int>> fetchTableStats(String tenantId);

  Future<int> fetchPendingOrdersCount(String tenantId);

  Future<List<Map<String, dynamic>>> fetchTopSellingItems(String tenantId);

  Future<List<Map<String, dynamic>>> fetchLowStockItems(String tenantId);

  // ---------------------------------------------------------------------------
  // Notificaciones
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getNotifications(String tenantId);

  Future<void> markNotificationAsRead(String id);

  Future<void> markNotificationsAsRead(List<String> ids);

  // ---------------------------------------------------------------------------
  // Activity logs
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getActivityLogs(
    String tenantId, {
    int limit = 50,
    int offset = 0,
  });

  Future<void> createActivityLog(Map<String, dynamic> data);

  // ---------------------------------------------------------------------------
  // Menú — Categorías
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getMenuCategories(String tenantId);

  Future<Map<String, dynamic>> createMenuCategory(Map<String, dynamic> data);

  Future<void> updateMenuCategory(String id, Map<String, dynamic> data);

  Future<void> deleteMenuCategory(String id);

  // ---------------------------------------------------------------------------
  // Menú — Items
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getMenuItems(
    String tenantId, {
    String? categoryId,
  });

  Future<Map<String, dynamic>> createMenuItem(Map<String, dynamic> data);

  Future<void> updateMenuItem(String id, Map<String, dynamic> data);

  Future<void> deleteMenuItem(String id);

  // ---------------------------------------------------------------------------
  // Menú — Opciones de items
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getMenuItemOptions(String menuItemId);

  Future<void> upsertMenuItemOptions(List<Map<String, dynamic>> options);

  Future<void> deleteMenuItemOption(String id);

  // ---------------------------------------------------------------------------
  // Menú — Diseño de carta digital
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getOrCreateMenuDesign(String tenantId);

  Future<void> updateMenuDesign(String id, Map<String, dynamic> data);

  // ---------------------------------------------------------------------------
  // Inventory
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getInventoryItems(String tenantId);

  Future<Map<String, dynamic>> createInventoryItem(Map<String, dynamic> data);

  Future<void> updateInventoryItem(String id, Map<String, dynamic> data);

  Future<void> deleteInventoryItem(String id);
}
