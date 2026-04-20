import '../../domain/entities/order_entity.dart';

/// Contrato del repositorio de pedidos.
///
/// Define las operaciones de pedidos disponibles en la capa de dominio.
/// La implementación concreta está en la capa de datos.
abstract class OrderRepository {
  // ---------------------------------------------------------------------------
  // Consultas
  // ---------------------------------------------------------------------------

  /// Pedidos activos (no completados ni cancelados) del tenant.
  Future<List<OrderEntity>> getActiveOrders(String tenantId);

  /// Pedido activo vinculado a la sesión abierta de una mesa.
  Future<OrderEntity?> getActiveOrderForTable(String tenantId, String tableId);

  /// Ítems del menú disponibles para el picker.
  Future<List<Map<String, dynamic>>> getMenuItemsForPicker(String tenantId);

  // ---------------------------------------------------------------------------
  // Apertura de mesa / sesión
  // ---------------------------------------------------------------------------

  /// Crea una table_session y devuelve su id.
  Future<String> createTableSession({
    required String tenantId,
    required String tableId,
    required String? userId,
    int guestCount = 1,
  });

  /// Crea un pedido dine-in vinculado a una sesión y devuelve su id.
  Future<String> createDineInOrder({
    required String tenantId,
    required String sessionId,
    required String? waiterId,
  });

  /// Marca una reserva como atendida.
  Future<void> fulfillReservation(String reservationId);

  // ---------------------------------------------------------------------------
  // Flujo de estados del pedido
  // ---------------------------------------------------------------------------

  Future<void> updateOrderStatus(String orderId, String status);

  Future<void> updateOrderPayment(
    String orderId, {
    required String paymentStatus,
    String? paymentMethod,
    String? status,
  });

  Future<void> cancelOrder(String orderId, {String? reason});

  /// Procesa un reembolso: actualiza payment_status → refunded
  /// y registra el motivo.
  Future<void> refundOrder(String orderId, {String? reason});

  // ---------------------------------------------------------------------------
  // Items del pedido
  // ---------------------------------------------------------------------------

  Future<void> addOrderItem({
    required String orderId,
    required String tenantId,
    required String menuItemId,
    required String name,
    required double unitPrice,
    int quantity = 1,
    String? notes,
  });

  Future<void> removeOrderItem(String orderItemId);

  Future<double> getItemUnitPrice(String orderItemId);

  Future<void> updateOrderItem(
    String orderItemId, {
    required Map<String, dynamic> data,
  });

  Future<void> updateOrderItemStatus(String orderItemId, String status);

  Future<void> updateItemsStatus(
    String orderId, {
    required String newStatus,
    String? currentStatus,
  });

  Future<void> markAllItemsReady(String orderId);

  // ---------------------------------------------------------------------------
  // Recalculación
  // ---------------------------------------------------------------------------

  Future<double> calculateOrderSubtotal(String orderId);

  Future<void> updateOrderTotals(
    String orderId, {
    required double subtotal,
    required double total,
  });

  // ---------------------------------------------------------------------------
  // Historial y métricas
  // ---------------------------------------------------------------------------

  Future<List<OrderEntity>> getOrderHistory(
    String tenantId, {
    List<String>? statuses,
    String? waiterId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int limit = 50,
    int offset = 0,
  });

  Future<List<Map<String, dynamic>>> getWaiterList(String tenantId);

  Future<Map<String, dynamic>> getOrderMetrics(
    String tenantId,
    String startDate,
    String endDate,
  );

  Future<List<Map<String, dynamic>>> getTopDishes(
    String tenantId,
    String startDate,
    String endDate,
  );

  Future<List<Map<String, dynamic>>> getOrdersByHour(
    String tenantId,
    String startDate,
    String endDate,
  );
}
