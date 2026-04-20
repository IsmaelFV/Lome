import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/providers/supabase_provider.dart';
import '../../data/models/order_model.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';

const _orderSelectQuery = '''
  *,
  order_items(*),
  waiter:profiles!waiter_id(full_name)
''';

/// Implementación Supabase del repositorio de pedidos.
class SupabaseOrderRepository implements OrderRepository {
  final SupabaseClient _client;

  SupabaseOrderRepository(this._client);

  // ---------------------------------------------------------------------------
  // Consultas
  // ---------------------------------------------------------------------------

  @override
  Future<List<OrderEntity>> getActiveOrders(String tenantId) async {
    final rows = await _client
        .from('orders')
        .select(_orderSelectQuery)
        .eq('tenant_id', tenantId)
        .not('status', 'in', '(completed,cancelled)')
        .order('created_at', ascending: false);

    return rows.map((r) => OrderModel.fromJson(r).toEntity()).toList();
  }

  @override
  Future<OrderEntity?> getActiveOrderForTable(
      String tenantId, String tableId) async {
    final sessions = await _client
        .from('table_sessions')
        .select('id')
        .eq('table_id', tableId)
        .eq('is_active', true)
        .limit(1);

    if (sessions.isEmpty) return null;
    final sessionId = sessions.first['id'] as String;

    final orders = await _client
        .from('orders')
        .select(_orderSelectQuery)
        .eq('table_session_id', sessionId)
        .not('status', 'in', '(completed,cancelled)')
        .order('created_at', ascending: false)
        .limit(1);

    if (orders.isEmpty) return null;
    return OrderModel.fromJson(orders.first).toEntity();
  }

  @override
  Future<List<Map<String, dynamic>>> getMenuItemsForPicker(
      String tenantId) async {
    return await _client
        .from('menu_items')
        .select('id, name, price, category_id, image_url')
        .eq('tenant_id', tenantId)
        .eq('is_available', true)
        .eq('is_active', true)
        .order('name');
  }

  // ---------------------------------------------------------------------------
  // Apertura de mesa / sesión
  // ---------------------------------------------------------------------------

  @override
  Future<String> createTableSession({
    required String tenantId,
    required String tableId,
    required String? userId,
    int guestCount = 1,
  }) async {
    final row = await _client
        .from('table_sessions')
        .insert({
          'tenant_id': tenantId,
          'table_id': tableId,
          'opened_by': userId,
          'guests_count': guestCount,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  @override
  Future<String> createDineInOrder({
    required String tenantId,
    required String sessionId,
    required String? waiterId,
  }) async {
    final row = await _client
        .from('orders')
        .insert({
          'tenant_id': tenantId,
          'table_session_id': sessionId,
          'waiter_id': waiterId,
          'order_type': 'dine_in',
          'status': 'pending',
          'payment_status': 'pending',
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  @override
  Future<void> fulfillReservation(String reservationId) async {
    await _client
        .from('reservations')
        .update({'status': 'fulfilled'}).eq('id', reservationId);
  }

  // ---------------------------------------------------------------------------
  // Flujo de estados
  // ---------------------------------------------------------------------------

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _client
        .from('orders')
        .update({'status': status}).eq('id', orderId);
  }

  @override
  Future<void> updateOrderPayment(
    String orderId, {
    required String paymentStatus,
    String? paymentMethod,
    String? status,
  }) async {
    final data = <String, dynamic>{'payment_status': paymentStatus};
    if (paymentMethod != null) data['payment_method'] = paymentMethod;
    if (status != null) data['status'] = status;
    await _client.from('orders').update(data).eq('id', orderId);
  }

  @override
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    final updates = <String, dynamic>{'status': 'cancelled'};
    if (reason != null) updates['cancellation_reason'] = reason;
    await _client.from('orders').update(updates).eq('id', orderId);
  }

  @override
  Future<void> refundOrder(String orderId, {String? reason}) async {
    // Actualizar payment_status en orders
    final updates = <String, dynamic>{'payment_status': 'refunded'};
    if (reason != null) updates['cancellation_reason'] = reason;
    await _client.from('orders').update(updates).eq('id', orderId);

    // Actualizar payment_status en payments
    await _client
        .from('payments')
        .update({'status': 'refunded'})
        .eq('order_id', orderId);
  }

  // ---------------------------------------------------------------------------
  // Items del pedido
  // ---------------------------------------------------------------------------

  @override
  Future<void> addOrderItem({
    required String orderId,
    required String tenantId,
    required String menuItemId,
    required String name,
    required double unitPrice,
    int quantity = 1,
    String? notes,
  }) async {
    await _client.from('order_items').insert({
      'order_id': orderId,
      'tenant_id': tenantId,
      'menu_item_id': menuItemId,
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': unitPrice * quantity,
      'status': 'pending',
      'notes': notes,
    });
  }

  @override
  Future<void> removeOrderItem(String orderItemId) async {
    await _client.from('order_items').delete().eq('id', orderItemId);
  }

  @override
  Future<double> getItemUnitPrice(String orderItemId) async {
    final row = await _client
        .from('order_items')
        .select('unit_price')
        .eq('id', orderItemId)
        .single();
    return (row['unit_price'] as num).toDouble();
  }

  @override
  Future<void> updateOrderItem(
    String orderItemId, {
    required Map<String, dynamic> data,
  }) async {
    await _client.from('order_items').update(data).eq('id', orderItemId);
  }

  @override
  Future<void> updateOrderItemStatus(
      String orderItemId, String status) async {
    await _client
        .from('order_items')
        .update({'status': status}).eq('id', orderItemId);
  }

  @override
  Future<void> updateItemsStatus(
    String orderId, {
    required String newStatus,
    String? currentStatus,
  }) async {
    var query = _client
        .from('order_items')
        .update({'status': newStatus})
        .eq('order_id', orderId);

    if (currentStatus != null) {
      query = query.eq('status', currentStatus);
    } else {
      query = query.neq('status', 'cancelled');
    }
    await query;
  }

  @override
  Future<void> markAllItemsReady(String orderId) async {
    await _client
        .from('order_items')
        .update({'status': 'ready'})
        .eq('order_id', orderId)
        .neq('status', 'cancelled');
  }

  // ---------------------------------------------------------------------------
  // Recalculación
  // ---------------------------------------------------------------------------

  @override
  Future<double> calculateOrderSubtotal(String orderId) async {
    final items = await _client
        .from('order_items')
        .select('total_price')
        .eq('order_id', orderId);

    double subtotal = 0;
    for (final item in items) {
      subtotal += (item['total_price'] as num).toDouble();
    }
    return subtotal;
  }

  @override
  Future<void> updateOrderTotals(
    String orderId, {
    required double subtotal,
    required double total,
  }) async {
    await _client.from('orders').update({
      'subtotal': subtotal,
      'total': total,
    }).eq('id', orderId);
  }

  // ---------------------------------------------------------------------------
  // Historial y métricas
  // ---------------------------------------------------------------------------

  @override
  Future<List<OrderEntity>> getOrderHistory(
    String tenantId, {
    List<String>? statuses,
    String? waiterId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client
        .from('orders')
        .select(_orderSelectQuery)
        .eq('tenant_id', tenantId);

    if (statuses != null && statuses.isNotEmpty) {
      query = query.inFilter('status', statuses);
    }
    if (waiterId != null) query = query.eq('waiter_id', waiterId);
    if (dateFrom != null) {
      query = query.gte('created_at', dateFrom.toIso8601String());
    }
    if (dateTo != null) {
      query = query.lte('created_at', dateTo.toIso8601String());
    }

    final rows = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return rows.map((r) => OrderModel.fromJson(r).toEntity()).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getWaiterList(String tenantId) async {
    return await _client
        .from('restaurant_staff')
        .select('user_id, profiles(full_name)')
        .eq('tenant_id', tenantId);
  }

  @override
  Future<Map<String, dynamic>> getOrderMetrics(
    String tenantId,
    String startDate,
    String endDate,
  ) async {
    final response = await _client.rpc('get_order_metrics', params: {
      'p_tenant_id': tenantId,
      'p_start_date': startDate,
      'p_end_date': endDate,
    });
    return response as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> getTopDishes(
    String tenantId,
    String startDate,
    String endDate,
  ) async {
    final response = await _client.rpc('get_top_dishes', params: {
      'p_tenant_id': tenantId,
      'p_start_date': startDate,
      'p_end_date': endDate,
    });
    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<List<Map<String, dynamic>>> getOrdersByHour(
    String tenantId,
    String startDate,
    String endDate,
  ) async {
    final response = await _client.rpc('get_orders_by_hour', params: {
      'p_tenant_id': tenantId,
      'p_start_date': startDate,
      'p_end_date': endDate,
    });
    return List<Map<String, dynamic>>.from(response as List);
  }
}

// =============================================================================
// Riverpod Provider
// =============================================================================

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return SupabaseOrderRepository(ref.read(supabaseClientProvider));
});
