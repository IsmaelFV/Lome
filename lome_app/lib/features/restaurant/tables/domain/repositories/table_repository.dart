import '../../domain/entities/table_entity.dart';

/// Contrato del repositorio de mesas.
abstract class TableRepository {
  // ---------------------------------------------------------------------------
  // Mesas
  // ---------------------------------------------------------------------------

  Future<List<TableEntity>> getTables(String tenantId);

  Future<void> updateTableStatus(String tableId, String status);

  Future<void> updateTablePosition(String tableId, double x, double y);

  Future<void> createTable(String tenantId, Map<String, dynamic> data);

  Future<void> updateTable(String tableId, Map<String, dynamic> data);

  Future<void> deactivateTable(String tableId);

  // ---------------------------------------------------------------------------
  // Asignaciones
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getAssignments(String tenantId);

  Future<void> assignTable({
    required String tenantId,
    required String tableId,
    required String waiterId,
  });

  Future<void> unassignTable(String tableId);

  Future<List<Map<String, dynamic>>> getAvailableWaiters(String tenantId);

  // ---------------------------------------------------------------------------
  // Estadísticas e historial
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getTableOccupancyStats(
    String tenantId,
    String startDate,
    String endDate,
  );

  Future<List<Map<String, dynamic>>> getTableHistory(
    String tenantId,
    String tableId, {
    int limit = 50,
    int offset = 0,
  });
}
