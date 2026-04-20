import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/providers/supabase_provider.dart';
import '../../data/models/reservation_model.dart';
import '../../domain/entities/reservation_entity.dart';
import '../../domain/repositories/reservation_repository.dart';

class SupabaseReservationRepository implements ReservationRepository {
  final SupabaseClient _client;

  SupabaseReservationRepository(this._client);

  @override
  Future<List<ReservationEntity>> getReservations(String tenantId) async {
    final today = DateTime.now().subtract(const Duration(hours: 2));
    final rows = await _client
        .from('reservations')
        .select()
        .eq('tenant_id', tenantId)
        .inFilter('status', ['pending', 'active'])
        .gte('reservation_time', today.toIso8601String())
        .order('reservation_time');

    return rows.map((r) => ReservationModel.fromJson(r).toEntity()).toList();
  }

  @override
  Future<void> activateUpcoming(String tenantId) async {
    await _client.rpc('activate_upcoming_reservations',
        params: {'p_tenant_id': tenantId});
  }

  @override
  Future<void> createReservation({
    required String tenantId,
    required String tableId,
    required String customerName,
    String? phone,
    required DateTime reservationTime,
    required int guests,
    String? notes,
    String? createdBy,
  }) async {
    await _client.from('reservations').insert({
      'tenant_id': tenantId,
      'table_id': tableId,
      'customer_name': customerName,
      'phone': phone,
      'reservation_time': reservationTime.toIso8601String(),
      'guests': guests,
      'notes': notes,
      'created_by': createdBy,
    });
  }

  @override
  Future<void> cancelReservation(String reservationId) async {
    await _client
        .from('reservations')
        .update({'status': 'cancelled'}).eq('id', reservationId);
  }

  @override
  Future<void> releaseTable(String tableId) async {
    await _client
        .from('restaurant_tables')
        .update({'status': 'available'}).eq('id', tableId);
  }
}

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return SupabaseReservationRepository(ref.read(supabaseClientProvider));
});
