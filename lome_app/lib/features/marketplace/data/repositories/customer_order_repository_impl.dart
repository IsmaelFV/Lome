import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/repositories/customer_order_repository.dart';

const _orderDetailSelect = '''
  *,
  order_items(*),
  tenants(name, logo_url, phone),
  payments(*)
''';

class SupabaseCustomerOrderRepository implements CustomerOrderRepository {
  final SupabaseClient _client;

  SupabaseCustomerOrderRepository(this._client);

  // ---------------------------------------------------------------------------
  // Checkout
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> placeOrder(
      Map<String, dynamic> orderData) async {
    final rows =
        await _client.from('orders').insert(orderData).select('id').single();
    return rows;
  }

  @override
  Future<void> insertOrderItems(List<Map<String, dynamic>> items) async {
    await _client.from('order_items').insert(items);
  }

  @override
  Future<void> insertPayment(Map<String, dynamic> paymentData) async {
    await _client.from('payments').insert(paymentData);
  }

  @override
  Future<void> updateOrderPaymentStatus(
      String orderId, String status) async {
    await _client
        .from('orders')
        .update({'payment_status': status}).eq('id', orderId);
  }

  @override
  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    return await _client
        .from('orders')
        .select(_orderDetailSelect)
        .eq('id', orderId)
        .single();
  }

  // ---------------------------------------------------------------------------
  // Direcciones
  // ---------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getAddresses(String userId) async {
    return await _client
        .from('customer_addresses')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);
  }

  @override
  Future<Map<String, dynamic>> createAddress(
      Map<String, dynamic> data) async {
    return await _client
        .from('customer_addresses')
        .insert(data)
        .select()
        .single();
  }

  @override
  Future<void> updateAddress(
      String id, Map<String, dynamic> data) async {
    await _client.from('customer_addresses').update(data).eq('id', id);
  }

  @override
  Future<void> clearDefaultAddresses(String userId) async {
    await _client
        .from('customer_addresses')
        .update({'is_default': false}).eq('user_id', userId);
  }

  @override
  Future<void> setDefaultAddress(String id) async {
    await _client
        .from('customer_addresses')
        .update({'is_default': true}).eq('id', id);
  }

  @override
  Future<void> softDeleteAddress(String id) async {
    await _client
        .from('customer_addresses')
        .update({'is_active': false}).eq('id', id);
  }

  // ---------------------------------------------------------------------------
  // Tracking
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>?> getDeliveryOrder(String orderId) async {
    return await _client
        .from('orders')
        .select(_orderDetailSelect)
        .eq('id', orderId)
        .maybeSingle();
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomerOrders(
      String userId) async {
    return await _client
        .from('orders')
        .select('*, tenants(name, logo_url)')
        .eq('customer_id', userId)
        .order('created_at', ascending: false)
        .limit(20);
  }

  @override
  Future<List<Map<String, dynamic>>> getActiveDeliveryOrders(
      String userId) async {
    return await _client
        .from('orders')
        .select(_orderDetailSelect)
        .eq('customer_id', userId)
        .inFilter('order_type', ['delivery', 'marketplace'])
        .not('status', 'in', '(completed,cancelled)')
        .order('created_at', ascending: false);
  }

  @override
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    final updates = <String, dynamic>{'status': 'cancelled'};
    if (reason != null) updates['cancellation_reason'] = reason;
    await _client.from('orders').update(updates).eq('id', orderId);
  }
}

final customerOrderRepositoryProvider =
    Provider<CustomerOrderRepository>((ref) {
  return SupabaseCustomerOrderRepository(ref.read(supabaseClientProvider));
});
