import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/providers/supabase_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/reservation_repository_impl.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../../domain/entities/reservation_entity.dart';

// =============================================================================
// Provider principal – reservas del restaurante
// =============================================================================

final reservationsProvider =
    StateNotifierProvider<
      ReservationsNotifier,
      AsyncValue<List<ReservationEntity>>
    >((ref) {
      return ReservationsNotifier(ref);
    });

class ReservationsNotifier
    extends StateNotifier<AsyncValue<List<ReservationEntity>>> {
  final Ref _ref;
  RealtimeChannel? _channel;
  Timer? _activationTimer;

  ReservationsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  SupabaseClient get _client => _ref.read(supabaseClientProvider);
  String? get _tenantId => _ref.read(activeTenantIdProvider);
  ReservationRepository get _repo => _ref.read(reservationRepositoryProvider);

  Future<void> _init() async {
    await _activateUpcoming();
    await loadReservations();
    _subscribeRealtime();
    _startActivationTimer();
  }

  /// Carga reservas de hoy y futuras (pendientes y activas).
  Future<void> loadReservations() async {
    final tenantId = _tenantId;
    if (tenantId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final reservations = await _repo.getReservations(tenantId);
      if (mounted) state = AsyncValue.data(reservations);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  void _subscribeRealtime() {
    final tenantId = _tenantId;
    if (tenantId == null) return;

    _channel = _client
        .channel('reservations-$tenantId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reservations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tenant_id',
            value: tenantId,
          ),
          callback: (_) => loadReservations(),
        )
        .subscribe();
  }

  /// Llama al RPC para activar reservas próximas y marcar no-show.
  Future<void> _activateUpcoming() async {
    final tenantId = _tenantId;
    if (tenantId == null) return;

    try {
      await _repo.activateUpcoming(tenantId);
    } catch (_) {
      // No bloquear la carga si el RPC falla
    }
  }

  /// Timer que revisa reservas cada 2 minutos.
  void _startActivationTimer() {
    _activationTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _activateUpcoming(),
    );
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Crea una nueva reserva.
  Future<void> createReservation({
    required String tableId,
    required String customerName,
    String? phone,
    required DateTime reservationTime,
    required int guests,
    String? notes,
  }) async {
    final tenantId = _tenantId;
    if (tenantId == null) return;

    await _repo.createReservation(
      tenantId: tenantId,
      tableId: tableId,
      customerName: customerName,
      phone: phone,
      reservationTime: reservationTime,
      guests: guests,
      notes: notes,
      createdBy: _client.auth.currentUser?.id,
    );

    await loadReservations();
  }

  /// Cancela una reserva.
  Future<void> cancelReservation(String reservationId) async {
    await _repo.cancelReservation(reservationId);

    // Si la mesa estaba reservada, volver a available
    final current = state.valueOrNull ?? [];
    final reservation = current.where((r) => r.id == reservationId).firstOrNull;
    if (reservation != null && reservation.isActive) {
      await _repo.releaseTable(reservation.tableId);
    }

    await loadReservations();
  }

  /// Obtiene la reserva activa para una mesa específica.
  ReservationEntity? getActiveReservationForTable(String tableId) {
    final reservations = state.valueOrNull ?? [];
    return reservations
        .where(
          (r) =>
              r.tableId == tableId &&
              (r.status == ReservationStatus.active ||
                  r.status == ReservationStatus.pending),
        )
        .firstOrNull;
  }

  Future<void> refresh() async {
    await _activateUpcoming();
    await loadReservations();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _activationTimer?.cancel();
    super.dispose();
  }
}

// =============================================================================
// Provider: reservas para una mesa específica
// =============================================================================

final reservationsForTableProvider =
    Provider.family<List<ReservationEntity>, String>((ref, tableId) {
      final all = ref.watch(reservationsProvider).valueOrNull ?? [];
      return all.where((r) => r.tableId == tableId).toList();
    });
