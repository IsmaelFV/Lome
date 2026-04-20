import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/repositories/marketplace_repository.dart';

const _restaurantFields = '''
  id, name, slug, description, logo_url, cover_image_url,
  cuisine_type, rating, total_reviews,
  delivery_enabled, takeaway_enabled, delivery_radius_km,
  minimum_order_amount, delivery_fee, estimated_delivery_time_min,
  average_price_range, city, latitude, longitude,
  is_featured, status
''';

class SupabaseMarketplaceRepository implements MarketplaceRepository {
  final SupabaseClient _client;

  SupabaseMarketplaceRepository(this._client);

  // ---------------------------------------------------------------------------
  // Restaurantes
  // ---------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getRestaurants({
    String? status,
    bool? deliveryOnly,
    bool? featuredOnly,
    String? cuisineType,
    int limit = 50,
  }) async {
    var query = _client.from('tenants').select(_restaurantFields);

    if (status != null) query = query.eq('status', status);
    if (deliveryOnly == true) query = query.eq('delivery_enabled', true);
    if (featuredOnly == true) query = query.eq('is_featured', true);
    if (cuisineType != null) {
      query = query.contains('cuisine_type', [cuisineType]);
    }

    return await query
        .order('is_featured', ascending: false)
        .order('rating', ascending: false)
        .limit(limit);
  }

  @override
  Future<Map<String, dynamic>?> getRestaurantDetail(
      String restaurantId) async {
    return await _client
        .from('tenants')
        .select(_restaurantFields)
        .eq('id', restaurantId)
        .maybeSingle();
  }

  @override
  Future<List<String>> getCuisineTypes() async {
    final response = await _client
        .from('tenants')
        .select('cuisine_type')
        .eq('status', 'active');

    final types = <String>{};
    for (final row in response as List) {
      final list = row['cuisine_type'] as List?;
      if (list != null) {
        for (final t in list) {
          types.add(t.toString());
        }
      }
    }
    return types.toList()..sort();
  }

  // ---------------------------------------------------------------------------
  // Menú público
  // ---------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getMenuCategories(
      String tenantId) async {
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
        .select()
        .eq('tenant_id', tenantId)
        .eq('is_available', true);

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    return await query.order('name');
  }

  @override
  Future<List<Map<String, dynamic>>> searchDishes(
    String query, {
    int limit = 20,
  }) async {
    return await _client
        .from('menu_items')
        .select('*, tenants!inner(id, name, logo_url, slug)')
        .eq('is_available', true)
        .ilike('name', '%$query%')
        .limit(limit);
  }

  @override
  Future<List<Map<String, dynamic>>> searchRestaurants(
    String query, {
    int limit = 15,
  }) async {
    return await _client
        .from('tenants')
        .select(_restaurantFields)
        .eq('status', 'active')
        .ilike('name', '%$query%')
        .order('is_featured', ascending: false)
        .order('rating', ascending: false)
        .limit(limit);
  }

  // ---------------------------------------------------------------------------
  // Reseñas
  // ---------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getRestaurantReviews(
      String tenantId) async {
    return await _client
        .from('reviews')
        .select('*, profiles(full_name, avatar_url)')
        .eq('tenant_id', tenantId)
        .eq('status', 'approved')
        .order('created_at', ascending: false);
  }

  @override
  Future<Map<String, dynamic>?> getUserReviewForOrder(
      String userId, String orderId) async {
    return await _client
        .from('reviews')
        .select()
        .eq('user_id', userId)
        .eq('order_id', orderId)
        .maybeSingle();
  }

  @override
  Future<void> submitReview(Map<String, dynamic> data) async {
    await _client.from('reviews').insert(data);
  }

  // ---------------------------------------------------------------------------
  // Favoritos
  // ---------------------------------------------------------------------------

  @override
  Future<List<String>> getFavoriteIds(String userId) async {
    final rows = await _client
        .from('favorites')
        .select('tenant_id')
        .eq('user_id', userId);
    return (rows as List).map((r) => r['tenant_id'] as String).toList();
  }

  @override
  Future<bool> isFavorite(String userId, String tenantId) async {
    final row = await _client
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('tenant_id', tenantId)
        .maybeSingle();
    return row != null;
  }

  @override
  Future<void> addFavorite(String userId, String tenantId) async {
    await _client.from('favorites').insert({
      'user_id': userId,
      'tenant_id': tenantId,
    });
  }

  @override
  Future<void> removeFavorite(String userId, String tenantId) async {
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('tenant_id', tenantId);
  }

  @override
  Future<List<Map<String, dynamic>>> getFavoriteRestaurants(
      List<String> tenantIds) async {
    if (tenantIds.isEmpty) return [];
    return await _client
        .from('tenants')
        .select(_restaurantFields)
        .inFilter('id', tenantIds)
        .eq('status', 'active');
  }

  // ---------------------------------------------------------------------------
  // Promociones y recomendaciones
  // ---------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getActivePromotions() async {
    return await _client
        .from('promotions')
        .select('*, tenants(name, logo_url)')
        .eq('is_active', true)
        .gte('end_date', DateTime.now().toIso8601String())
        .order('created_at', ascending: false);
  }

  @override
  Future<List<Map<String, dynamic>>> getRestaurantPromotions(
      String tenantId) async {
    return await _client
        .from('promotions')
        .select()
        .eq('tenant_id', tenantId)
        .eq('is_active', true)
        .gte('end_date', DateTime.now().toIso8601String())
        .order('created_at', ascending: false);
  }

  @override
  Future<List<Map<String, dynamic>>> getRecommendedRestaurants(
      String userId) async {
    final response = await _client.rpc('get_recommended_restaurants', params: {
      'p_user_id': userId,
    });
    return List<Map<String, dynamic>>.from(response as List);
  }
}

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return SupabaseMarketplaceRepository(ref.read(supabaseClientProvider));
});
