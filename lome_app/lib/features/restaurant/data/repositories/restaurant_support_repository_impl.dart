import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/repositories/restaurant_support_repository.dart';

class SupabaseRestaurantSupportRepository
    implements RestaurantSupportRepository {
  final SupabaseClient _client;

  SupabaseRestaurantSupportRepository(this._client);

  // ---------------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------------

  @override
  Future<double> fetchSalesToday(String tenantId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String();

    final response = await _client
        .from('orders')
        .select('total')
        .eq('tenant_id', tenantId)
        .gte('created_at', startOfDay)
        .inFilter('status', ['completed', 'delivered']);

    double total = 0;
    for (final row in response as List) {
      total += (row['total'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  @override
  Future<int> fetchActiveOrdersCount(String tenantId) async {
    final response = await _client
        .from('orders')
        .select('id')
        .eq('tenant_id', tenantId)
        .inFilter('status', ['pending', 'confirmed', 'preparing', 'ready']);
    return (response as List).length;
  }

  @override
  Future<Map<String, int>> fetchTableStats(String tenantId) async {
    final allTables = await _client
        .from('restaurant_tables')
        .select('id, status')
        .eq('tenant_id', tenantId)
        .eq('is_active', true);

    final total = (allTables as List).length;
    final occupied = allTables.where((t) => t['status'] == 'occupied').length;
    return {'total': total, 'occupied': occupied};
  }

  @override
  Future<int> fetchPendingOrdersCount(String tenantId) async {
    final response = await _client
        .from('orders')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('status', 'pending');
    return (response as List).length;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTopSellingItems(
    String tenantId,
  ) async {
    final today = DateTime.now();
    final startOfDay = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String();

    return await _client
        .from('order_items')
        .select('name, quantity')
        .eq('tenant_id', tenantId)
        .gte('created_at', startOfDay);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchLowStockItems(String tenantId) async {
    return await _client
        .from('inventory_items')
        .select('name, current_stock, minimum_stock, unit')
        .eq('tenant_id', tenantId)
        .eq('is_active', true)
        .order('current_stock');
  }

  // ---------------------------------------------------------------------------
  // Notificaciones
  // ---------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getNotifications(String tenantId) async {
    return await _client
        .from('notifications')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false)
        .limit(50);
  }

  @override
  Future<void> markNotificationAsRead(String id) async {
    await _client
        .from('notifications')
        .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  @override
  Future<void> markNotificationsAsRead(List<String> ids) async {
    await _client
        .from('notifications')
        .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
        .inFilter('id', ids);
  }

  // ---------------------------------------------------------------------------
  // Activity logs
  // ---------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getActivityLogs(
    String tenantId, {
    int limit = 50,
    int offset = 0,
  }) async {
    return await _client
        .from('activity_logs')
        .select('*, profiles(full_name)')
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
  }

  @override
  Future<void> createActivityLog(Map<String, dynamic> data) async {
    await _client.from('activity_logs').insert(data);
  }

  // ---------------------------------------------------------------------------
  // Menú
  // ---------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getMenuCategories(String tenantId) async {
    return await _client
        .from('menu_categories')
        .select()
        .eq('tenant_id', tenantId)
        .order('sort_order');
  }

  @override
  Future<List<Map<String, dynamic>>> getMenuItems(
    String tenantId, {
    String? categoryId,
  }) async {
    var query = _client
        .from('menu_items')
        .select('*, menu_categories(name)')
        .eq('tenant_id', tenantId)
        .eq('is_active', true);

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    return await query.order('name');
  }

  @override
  Future<Map<String, dynamic>> createMenuCategory(
    Map<String, dynamic> data,
  ) async {
    final result = await _client
        .from('menu_categories')
        .insert(data)
        .select()
        .single();
    return result;
  }

  @override
  Future<void> updateMenuCategory(String id, Map<String, dynamic> data) async {
    await _client.from('menu_categories').update(data).eq('id', id);
  }

  @override
  Future<void> deleteMenuCategory(String id) async {
    await _client.from('menu_categories').delete().eq('id', id);
  }

  @override
  Future<Map<String, dynamic>> createMenuItem(Map<String, dynamic> data) async {
    final result = await _client
        .from('menu_items')
        .insert(data)
        .select()
        .single();
    return result;
  }

  @override
  Future<void> updateMenuItem(String id, Map<String, dynamic> data) async {
    await _client.from('menu_items').update(data).eq('id', id);
  }

  @override
  Future<void> deleteMenuItem(String id) async {
    await _client.from('menu_items').update({'is_active': false}).eq('id', id);
  }

  // ---------------------------------------------------------------------------
  // Opciones de items
  // ---------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getMenuItemOptions(
    String menuItemId,
  ) async {
    return await _client
        .from('menu_item_options')
        .select()
        .eq('menu_item_id', menuItemId)
        .eq('is_active', true)
        .order('group_name')
        .order('sort_order');
  }

  @override
  Future<void> upsertMenuItemOptions(List<Map<String, dynamic>> options) async {
    await _client.from('menu_item_options').upsert(options);
  }

  @override
  Future<void> deleteMenuItemOption(String id) async {
    await _client
        .from('menu_item_options')
        .update({'is_active': false})
        .eq('id', id);
  }

  // ---------------------------------------------------------------------------
  // Diseño de carta digital
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> getOrCreateMenuDesign(String tenantId) async {
    final result = await _client.rpc(
      'get_or_create_menu_design',
      params: {'p_tenant_id': tenantId},
    );
    final list = result as List;
    return list.first as Map<String, dynamic>;
  }

  @override
  Future<void> updateMenuDesign(String id, Map<String, dynamic> data) async {
    await _client.from('menu_designs').update(data).eq('id', id);
  }

  // ---------------------------------------------------------------------------
  // Inventory
  // ---------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getInventoryItems(String tenantId) async {
    final res = await _client
        .from('inventory_items')
        .select()
        .eq('tenant_id', tenantId)
        .eq('is_active', true)
        .order('name');
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<Map<String, dynamic>> createInventoryItem(
    Map<String, dynamic> data,
  ) async {
    final res =
        await _client.from('inventory_items').insert(data).select().single();
    return Map<String, dynamic>.from(res);
  }

  @override
  Future<void> updateInventoryItem(String id, Map<String, dynamic> data) async {
    await _client.from('inventory_items').update(data).eq('id', id);
  }

  @override
  Future<void> deleteInventoryItem(String id) async {
    await _client
        .from('inventory_items')
        .update({'is_active': false})
        .eq('id', id);
  }
}

final restaurantSupportRepositoryProvider =
    Provider<RestaurantSupportRepository>((ref) {
      return SupabaseRestaurantSupportRepository(
        ref.read(supabaseClientProvider),
      );
    });
