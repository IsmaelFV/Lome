import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/repositories/restaurant_config_repository.dart';

class SupabaseRestaurantConfigRepository implements RestaurantConfigRepository {
  final SupabaseClient _client;

  SupabaseRestaurantConfigRepository(this._client);

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> getRestaurantData(String tenantId) async {
    return await _client
        .from('tenants')
        .select(
          'id, name, description, logo_url, cover_image_url, '
          'phone, email, website, '
          'address_line1, address_line2, city, state, postal_code, country, '
          'cuisine_type',
        )
        .eq('id', tenantId)
        .single();
  }

  @override
  Future<void> updateRestaurantData(
    String tenantId,
    Map<String, dynamic> data,
  ) async {
    await _client
        .from('tenants')
        .update(data)
        .eq('id', tenantId)
        .timeout(const Duration(seconds: 15));
  }

  @override
  Future<void> updateLogoUrl(String tenantId, String url) async {
    await _client
        .from('tenants')
        .update({'logo_url': url})
        .eq('id', tenantId)
        .timeout(const Duration(seconds: 15));
  }

  // ---------------------------------------------------------------------------
  // Status operativo
  // ---------------------------------------------------------------------------

  @override
  Future<String> getOperationalStatus(String tenantId) async {
    final row = await _client
        .from('tenants')
        .select('operational_status')
        .eq('id', tenantId)
        .single();
    return row['operational_status'] as String? ?? 'open';
  }

  @override
  Future<void> setOperationalStatus(String tenantId, String status) async {
    await _client
        .from('tenants')
        .update({'operational_status': status})
        .eq('id', tenantId);
  }

  // ---------------------------------------------------------------------------
  // Horarios
  // ---------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getHours(String tenantId) async {
    return await _client
        .from('restaurant_hours')
        .select()
        .eq('tenant_id', tenantId)
        .order('day_of_week')
        .order('open_time');
  }

  @override
  Future<void> upsertHour(String id, Map<String, dynamic> data) async {
    await _client.from('restaurant_hours').update(data).eq('id', id);
  }

  @override
  Future<void> insertHour(Map<String, dynamic> data) async {
    await _client.from('restaurant_hours').insert(data);
  }

  @override
  Future<void> deleteHour(String id) async {
    await _client.from('restaurant_hours').delete().eq('id', id);
  }

  // ---------------------------------------------------------------------------
  // Roles personalizados
  // ---------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getRoles(String tenantId) async {
    return await _client
        .from('custom_roles')
        .select()
        .eq('tenant_id', tenantId)
        .order('name');
  }

  @override
  Future<Map<String, dynamic>> createRole(Map<String, dynamic> data) async {
    final rows = await _client
        .from('custom_roles')
        .insert(data)
        .select()
        .single();
    return rows;
  }

  @override
  Future<void> updateRole(String id, Map<String, dynamic> data) async {
    await _client.from('custom_roles').update(data).eq('id', id);
  }

  @override
  Future<void> deleteRole(String id) async {
    await _client.from('custom_roles').delete().eq('id', id);
  }
}

final restaurantConfigRepositoryProvider = Provider<RestaurantConfigRepository>(
  (ref) {
    return SupabaseRestaurantConfigRepository(ref.read(supabaseClientProvider));
  },
);
