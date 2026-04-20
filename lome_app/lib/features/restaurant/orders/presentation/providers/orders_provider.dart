import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/providers/supabase_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';

// =============================================================================
// Provider principal – pedidos del restaurante
// =============================================================================

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, AsyncValue<List<OrderEntity>>>((ref) {
      return OrdersNotifier(ref);
    });

class OrdersNotifier extends StateNotifier<AsyncValue<List<OrderEntity>>> {
  final Ref _ref;
  RealtimeChannel? _channel;
  RealtimeChannel? _itemsChannel;

  OrdersNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  OrderRepository get _repo => _ref.read(orderRepositoryProvider);
  SupabaseClient get _client => _ref.read(supabaseClientProvider);
  String? get _tenantId => _ref.read(activeTenantIdProvider);
  String? get _userId => _client.auth.currentUser?.id;

  Future<void> _init() async {
    await loadOrders();
    _subscribeRealtime();
  }

  /// Carga pedidos activos (no completados ni cancelados).
  Future<void> loadOrders() async {
    final tenantId = _tenantId;
    if (tenantId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final orders = await _repo.getActiveOrders(tenantId);
      if (mounted) state = AsyncValue.data(orders);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  void _subscribeRealtime() {
    final tenantId = _tenantId;
    if (tenantId == null) return;

    _channel = _client
        .channel('orders-$tenantId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tenant_id',
            value: tenantId,
          ),
          callback: (_) => loadOrders(),
        )
        .subscribe();

    // Suscripción a cambios en items (para cocina / estados por plato)
    _itemsChannel = _client
        .channel('order-items-$tenantId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'order_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tenant_id',
            value: tenantId,
          ),
          callback: (_) => loadOrders(),
        )
        .subscribe();
  }

  // ---------------------------------------------------------------------------
  // Abrir mesa – crea sesión + pedido
  // ---------------------------------------------------------------------------

  /// Abre una mesa: crea una [table_session] y un [order] vinculados.
  /// Devuelve el id del pedido creado.
  Future<String> openTable({
    required String tableId,
    int guestCount = 1,
  }) async {
    final tenantId = _tenantId;
    final userId = _userId;
    if (tenantId == null) throw Exception('No hay tenant activo');

    final sessionId = await _repo.createTableSession(
      tenantId: tenantId,
      tableId: tableId,
      userId: userId,
      guestCount: guestCount,
    );

    final orderId = await _repo.createDineInOrder(
      tenantId: tenantId,
      sessionId: sessionId,
      waiterId: userId,
    );

    await loadOrders();
    return orderId;
  }

  /// Abre una mesa con reserva: crea sesión + pedido y marca la reserva
  /// como fulfilled.
  Future<String> openTableFromReservation({
    required String tableId,
    required String reservationId,
    required int guestCount,
  }) async {
    final orderId = await openTable(tableId: tableId, guestCount: guestCount);

    // Marcar reserva como atendida
    await _repo.fulfillReservation(reservationId);

    return orderId;
  }

  // ---------------------------------------------------------------------------
  // Buscar pedido activo para una mesa
  // ---------------------------------------------------------------------------

  /// Obtiene el pedido activo asociado a la sesión abierta de una mesa.
  Future<OrderEntity?> getActiveOrderForTable(String tableId) async {
    final tenantId = _tenantId;
    if (tenantId == null) return null;
    return _repo.getActiveOrderForTable(tenantId, tableId);
  }

  // ---------------------------------------------------------------------------
  // Flujo de estados del pedido
  // ---------------------------------------------------------------------------

  /// Enviar pedido a cocina: pending → preparing.
  /// Marca también todos los items pendientes como preparing.
  /// Trigger BD: table → waiting_food.
  Future<void> sendToKitchen(String orderId) async {
    await _repo.updateOrderStatus(orderId, 'preparing');
    await _repo.updateItemsStatus(
      orderId,
      newStatus: 'preparing',
      currentStatus: 'pending',
    );
    await loadOrders();
  }

  /// Marcar pedido como servido: ready/preparing → delivered (DB).
  /// Trigger BD: table → waiting_payment.
  Future<void> markServed(String orderId) async {
    await _repo.updateOrderStatus(orderId, 'delivered');
    await loadOrders();
  }

  /// Procesar pago: payment_status → paid, status → completed.
  /// Trigger BD: cierra sesión → table → available.
  Future<void> processPayment(String orderId, String method) async {
    await _repo.updateOrderPayment(
      orderId,
      paymentStatus: 'paid',
      paymentMethod: method,
      status: 'completed',
    );
    await loadOrders();
  }

  /// Cancelar pedido.
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    await _repo.cancelOrder(orderId, reason: reason);
    await loadOrders();
  }

  /// Reembolsar pedido: payment_status → refunded, status → cancelled.
  Future<void> refundOrder(String orderId, {String? reason}) async {
    await _repo.refundOrder(orderId, reason: reason);
    await _repo.updateOrderStatus(orderId, 'cancelled');
    await loadOrders();
  }

  // ---------------------------------------------------------------------------
  // Gestión de items
  // ---------------------------------------------------------------------------

  /// Añade un ítem al pedido desde un menu_item.
  Future<void> addItem({
    required String orderId,
    required String menuItemId,
    required String name,
    required double unitPrice,
    int quantity = 1,
    String? notes,
  }) async {
    final tenantId = _tenantId;
    if (tenantId == null) return;

    await _repo.addOrderItem(
      orderId: orderId,
      tenantId: tenantId,
      menuItemId: menuItemId,
      name: name,
      unitPrice: unitPrice,
      quantity: quantity,
      notes: notes,
    );

    await _recalculateOrderTotal(orderId);
    await loadOrders();
  }

  /// Elimina un ítem del pedido.
  Future<void> removeItem(String orderItemId, String orderId) async {
    await _repo.removeOrderItem(orderItemId);
    await _recalculateOrderTotal(orderId);
    await loadOrders();
  }

  /// Actualiza la cantidad de un ítem.
  Future<void> updateItemQuantity(
    String orderItemId,
    String orderId,
    int quantity,
  ) async {
    if (quantity <= 0) {
      await removeItem(orderItemId, orderId);
      return;
    }

    final unitPrice = await _repo.getItemUnitPrice(orderItemId);

    await _repo.updateOrderItem(
      orderItemId,
      data: {'quantity': quantity, 'total_price': unitPrice * quantity},
    );

    await _recalculateOrderTotal(orderId);
    await loadOrders();
  }

  /// Actualiza las notas de un ítem (solo si el pedido no fue enviado a cocina).
  Future<void> updateItemNotes(String orderItemId, String? notes) async {
    await _repo.updateOrderItem(orderItemId, data: {'notes': notes});
    await loadOrders();
  }

  // ---------------------------------------------------------------------------
  // Gestión de estados por plato (flujo cocina)
  // ---------------------------------------------------------------------------

  /// Cambiar el estado de un ítem individual.
  /// Flujo: pending → preparing → ready → served.
  Future<void> updateItemStatus(
    String orderItemId,
    OrderItemStatus newStatus,
  ) async {
    await _repo.updateOrderItemStatus(orderItemId, newStatus.name);
    await loadOrders();
  }

  /// Marca todos los items de un pedido como ready y el pedido como ready.
  Future<void> markOrderReady(String orderId) async {
    await _repo.markAllItemsReady(orderId);
    await _repo.updateOrderStatus(orderId, 'ready');
    await loadOrders();
  }

  /// Recalcula subtotal y total del pedido sumando sus items.
  Future<void> _recalculateOrderTotal(String orderId) async {
    final subtotal = await _repo.calculateOrderSubtotal(orderId);
    await _repo.updateOrderTotals(orderId, subtotal: subtotal, total: subtotal);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> refresh() async => loadOrders();

  @override
  void dispose() {
    _channel?.unsubscribe();
    _itemsChannel?.unsubscribe();
    super.dispose();
  }
}

// =============================================================================
// Provider: pedidos para cocina (pending / preparing / ready)
// =============================================================================

final kitchenOrdersProvider = Provider<List<OrderEntity>>((ref) {
  const kitchenStatuses = {
    OrderStatus.pending,
    OrderStatus.preparing,
    OrderStatus.ready,
  };
  final orders = ref.watch(ordersProvider).valueOrNull ?? [];
  return orders.where((o) => kitchenStatuses.contains(o.status)).toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
});

// =============================================================================
// Provider: pedido activo de una mesa específica
// =============================================================================

/// Carga el pedido activo para una mesa dada.
final activeOrderForTableProvider = FutureProvider.family<OrderEntity?, String>(
  (ref, tableId) async {
    final notifier = ref.read(ordersProvider.notifier);
    return notifier.getActiveOrderForTable(tableId);
  },
);

// =============================================================================
// Provider: ítems del menú para el picker
// =============================================================================

final menuItemsForPickerProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.read(orderRepositoryProvider);
  final tenantId = ref.read(activeTenantIdProvider);
  if (tenantId == null) return [];
  return await repo.getMenuItemsForPicker(tenantId);
});
