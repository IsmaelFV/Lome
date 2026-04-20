/// Contrato del repositorio de pedidos del cliente.
///
/// Agrupa: checkout, direcciones, seguimiento de pedidos.
abstract class CustomerOrderRepository {
  // ---------------------------------------------------------------------------
  // Checkout
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> orderData);

  Future<void> insertOrderItems(List<Map<String, dynamic>> items);

  Future<void> insertPayment(Map<String, dynamic> paymentData);

  Future<void> updateOrderPaymentStatus(String orderId, String status);

  Future<Map<String, dynamic>> getOrderById(String orderId);

  // ---------------------------------------------------------------------------
  // Direcciones
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getAddresses(String userId);

  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> data);

  Future<void> updateAddress(String id, Map<String, dynamic> data);

  Future<void> clearDefaultAddresses(String userId);

  Future<void> setDefaultAddress(String id);

  Future<void> softDeleteAddress(String id);

  // ---------------------------------------------------------------------------
  // Tracking
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> getDeliveryOrder(String orderId);

  Future<List<Map<String, dynamic>>> getCustomerOrders(String userId);

  Future<List<Map<String, dynamic>>> getActiveDeliveryOrders(String userId);

  /// Cancela un pedido (solo si está pendiente o confirmado).
  Future<void> cancelOrder(String orderId, {String? reason});
}
