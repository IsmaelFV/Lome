/// Contrato del repositorio de administración.
///
/// Agrupa: dashboard, restaurantes, incidentes, moderación, suscripciones,
/// analytics, auditoría y monitoreo.
abstract class AdminRepository {
  // ---------------------------------------------------------------------------
  // Dashboard y analytics
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getPlatformMetrics();

  Future<List<Map<String, dynamic>>> getRecentRestaurants({int limit = 5});

  Future<List<Map<String, dynamic>>> getTopRestaurantsByRevenue({
    int limit = 10,
  });

  // ---------------------------------------------------------------------------
  // Restaurantes
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getRestaurants({String? status});

  Future<Map<String, dynamic>?> getRestaurantDetail(String id);

  Future<Map<String, dynamic>> getRestaurantStats(String tenantId);

  Future<void> toggleRestaurantStatus(String id, String newStatus);

  // ---------------------------------------------------------------------------
  // Incidentes
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getIncidents({String? status});

  Future<int> getOpenIncidentCount();

  Future<Map<String, dynamic>?> getIncidentDetail(String id);

  Future<void> updateIncidentStatus(
    String id,
    String newStatus, {
    String? resolvedBy,
  });

  Future<void> createIncident(Map<String, dynamic> data);

  Future<void> resolveIncident(
    String id,
    String resolution, {
    required String resolvedBy,
  });

  // ---------------------------------------------------------------------------
  // Moderación
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getFlaggedReviews();

  Future<void> approveReview(String id, {required String moderatedBy});

  Future<void> rejectReview(String id, {required String moderatedBy});

  // ---------------------------------------------------------------------------
  // Suscripciones
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getSubscriptionStats();

  Future<List<Map<String, dynamic>>> getSubscriptions({String? status});

  Future<List<Map<String, dynamic>>> getInvoices({String? status});

  Future<void> updateSubscription(String id, Map<String, dynamic> data);

  Future<void> markInvoicePaid(String id);

  // ---------------------------------------------------------------------------
  // Auditoría
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getAuditSummary({required int hours});

  Future<List<Map<String, dynamic>>> getAuditLogs({
    String? entityType,
    String? action,
    int limit = 50,
    int offset = 0,
  });

  // ---------------------------------------------------------------------------
  // Monitoreo
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getMonitoringDashboard({required int hours});

  Future<List<Map<String, dynamic>>> getErrorLogs({
    String? severity,
    String? source,
    int limit = 50,
    int offset = 0,
  });

  Future<Map<String, dynamic>> purgeOldLogs(int days);
}
