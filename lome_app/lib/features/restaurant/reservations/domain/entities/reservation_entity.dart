import 'package:equatable/equatable.dart';

/// Estado de una reserva.
enum ReservationStatus {
  pending,
  active,
  fulfilled,
  cancelled,
  noShow;

  String get label => switch (this) {
    pending => 'Pendiente',
    active => 'Activa',
    fulfilled => 'Atendida',
    cancelled => 'Cancelada',
    noShow => 'No presentado',
  };

  static ReservationStatus fromString(String value) {
    return switch (value) {
      'pending' => ReservationStatus.pending,
      'active' => ReservationStatus.active,
      'fulfilled' => ReservationStatus.fulfilled,
      'cancelled' => ReservationStatus.cancelled,
      'no_show' => ReservationStatus.noShow,
      _ => ReservationStatus.pending,
    };
  }

  String get dbValue => switch (this) {
    noShow => 'no_show',
    _ => name,
  };
}

/// Entidad de reserva de mesa.
class ReservationEntity extends Equatable {
  final String id;
  final String tenantId;
  final String tableId;
  final String customerName;
  final String? phone;
  final DateTime reservationTime;
  final int guests;
  final ReservationStatus status;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;

  const ReservationEntity({
    required this.id,
    required this.tenantId,
    required this.tableId,
    required this.customerName,
    this.phone,
    required this.reservationTime,
    required this.guests,
    required this.status,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  bool get isPending => status == ReservationStatus.pending;
  bool get isActive => status == ReservationStatus.active;

  @override
  List<Object?> get props => [id, tableId, reservationTime, status];
}
