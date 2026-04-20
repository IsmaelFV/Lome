import '../../domain/entities/reservation_entity.dart';

/// Contrato del repositorio de reservas.
abstract class ReservationRepository {
  Future<List<ReservationEntity>> getReservations(String tenantId);

  Future<void> activateUpcoming(String tenantId);

  Future<void> createReservation({
    required String tenantId,
    required String tableId,
    required String customerName,
    String? phone,
    required DateTime reservationTime,
    required int guests,
    String? notes,
    String? createdBy,
  });

  Future<void> cancelReservation(String reservationId);

  Future<void> releaseTable(String tableId);
}
