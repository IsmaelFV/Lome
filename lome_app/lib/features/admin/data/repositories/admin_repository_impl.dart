import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/repositories/admin_repository.dart';

const _restaurantFields =
    'id, name, slug, description, logo_url, city, phone, email, '
    'status, rating, total_reviews, total_orders, subscription_plan, '
    'cuisine_type, created_at';

const _incidentSelect =
    '*, tenants:tenant_id(name), reporter:reported_by(full_name), '
    'assignee:assigned_to(full_name)';

const _reviewSelect =
    '*, profiles:user_id(full_name), tenants:tenant_id(name)';

const _subscriptionSelect = '*, tenants:tenant_id(name)';

const _invoiceSelect = '*, tenants:tenant_id(name)';

class SupabaseAdminRepository implements AdminRepository {
  final SupabaseClient _client;

  SupabaseAdminRepository(this._client);

  // ---------------------------------------------------------------------------
  // Dashboard y analytics
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> getPlatformMetrics() async {
    final response = await _client.rpc('get_admin_platform_metrics');
    return response as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentRestaurants(
      {int limit = 5}) async {
    return await _client
        .from('tenants')
        .select(_restaurantFields)
        .order('created_at', ascending: false)
        .limit(limit);
  }

  @override
  Future<List<Map<String, dynamic>>> getTopRestaurantsByRevenue({
    int limit = 10,
  }) async {
    final response =
        await _client.rpc('get_top_restaurants_by_revenue', params: {
      'p_limit': limit,
    });
    if (response == null) return [];
    return List<Map<String, dynamic>>.from(response as List);
  }

  // ---------------------------------------------------------------------------
  // Restaurantes
  // ---------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getRestaurants({String? status}) async {
    var query = _client.from('tenants').select(_restaurantFields);
    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }
    return await query.order('created_at', ascending: false);
  }

  @override
  Future<Map<String, dynamic>?> getRestaurantDetail(String id) async {
    return await _client
        .from('tenants')
        .select(_restaurantFields)
        .eq('id', id)
        .maybeSingle();
  }

  @override
  Future<Map<String, dynamic>> getRestaurantStats(String tenantId) async {
    final response =
        await _client.rpc('get_admin_restaurant_stats', params: {
      'p_tenant_id': tenantId,
    });
    return response as Map<String, dynamic>;
  }

  @override
  Future<void> toggleRestaurantStatus(String id, String newStatus) async {
    await _client
        .from('tenants')
        .update({'status': newStatus}).eq('id', id);
  }

  // ---------------------------------------------------------------------------
  // Incidentes
  // ---------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getIncidents({String? status}) async {
    var query = _client.from('incidents').select(_incidentSelect);
    if (status != null) query = query.eq('status', status);
    return await query.order('created_at', ascending: false);
  }

  @override
  Future<int> getOpenIncidentCount() async {
    final rows = await _client
        .from('incidents')
        .select('id')
        .inFilter('status', ['open', 'in_progress']);
    return (rows as List).length;
  }

  @override
  Future<Map<String, dynamic>?> getIncidentDetail(String id) async {
    return await _client
        .from('incidents')
        .select(_incidentSelect)
        .eq('id', id)
        .maybeSingle();
  }

  @override
  Future<void> updateIncidentStatus(
    String id,
    String newStatus, {
    String? resolvedBy,
  }) async {
    final updates = <String, dynamic>{'status': newStatus};
    if (newStatus == 'resolved' || newStatus == 'closed') {
      updates['resolved_at'] = DateTime.now().toIso8601String();
      if (resolvedBy != null) updates['resolved_by'] = resolvedBy;
    }
    await _client.from('incidents').update(updates).eq('id', id);
  }

  @override
  Future<void> createIncident(Map<String, dynamic> data) async {
    await _client.from('incidents').insert(data);
  }

  @override
  Future<void> resolveIncident(
    String id,
    String resolution, {
    required String resolvedBy,
  }) async {
    await _client.from('incidents').update({
      'status': 'resolved',
      'resolution': resolution,
      'resolved_at': DateTime.now().toIso8601String(),
      'resolved_by': resolvedBy,
    }).eq('id', id);
  }

  // ---------------------------------------------------------------------------
  // Moderación
  // ---------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getFlaggedReviews() async {
    return await _client
        .from('reviews')
        .select(_reviewSelect)
        .eq('is_flagged', true)
        .order('created_at', ascending: false);
  }

  @override
  Future<void> approveReview(String id, {required String moderatedBy}) async {
    await _client.from('reviews').update({
      'is_flagged': false,
      'moderated_at': DateTime.now().toIso8601String(),
      'moderated_by': moderatedBy,
    }).eq('id', id);
  }

  @override
  Future<void> rejectReview(String id, {required String moderatedBy}) async {
    await _client.from('reviews').update({
      'is_flagged': false,
      'is_visible': false,
      'moderated_at': DateTime.now().toIso8601String(),
      'moderated_by': moderatedBy,
    }).eq('id', id);
  }

  // ---------------------------------------------------------------------------
  // Suscripciones
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> getSubscriptionStats() async {
    final response = await _client.rpc('get_admin_subscription_stats');
    return response as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> getSubscriptions(
      {String? status}) async {
    var query =
        _client.from('subscriptions').select(_subscriptionSelect);
    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }
    return await query.order('created_at', ascending: false);
  }

  @override
  Future<List<Map<String, dynamic>>> getInvoices({String? status}) async {
    var query = _client.from('invoices').select(_invoiceSelect);
    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }
    return await query.order('created_at', ascending: false);
  }

  @override
  Future<void> updateSubscription(
      String id, Map<String, dynamic> data) async {
    await _client.from('subscriptions').update(data).eq('id', id);
  }

  @override
  Future<void> markInvoicePaid(String id) async {
    await _client.from('invoices').update({
      'status': 'paid',
      'paid_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // ---------------------------------------------------------------------------
  // Auditoría
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> getAuditSummary({required int hours}) async {
    final response = await _client.rpc(
      'get_audit_summary',
      params: {'p_hours': hours},
    );
    return response as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> getAuditLogs({
    String? entityType,
    String? action,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      'p_limit': limit,
      'p_offset': offset,
    };
    if (entityType != null) params['p_entity_type'] = entityType;
    if (action != null) params['p_action'] = action;
    final response = await _client.rpc('get_audit_logs', params: params);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // ---------------------------------------------------------------------------
  // Monitoreo
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> getMonitoringDashboard(
      {required int hours}) async {
    final response = await _client.rpc(
      'get_monitoring_dashboard',
      params: {'p_hours': hours},
    );
    return response as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> getErrorLogs({
    String? severity,
    String? source,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      'p_limit': limit,
      'p_offset': offset,
    };
    if (severity != null) params['p_severity'] = severity;
    if (source != null) params['p_source'] = source;
    final response = await _client.rpc('get_error_logs', params: params);
    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<Map<String, dynamic>> purgeOldLogs(int days) async {
    final response = await _client.rpc(
      'purge_old_logs',
      params: {'p_retention_days': days},
    );
    return response as Map<String, dynamic>;
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return SupabaseAdminRepository(ref.read(supabaseClientProvider));
});
