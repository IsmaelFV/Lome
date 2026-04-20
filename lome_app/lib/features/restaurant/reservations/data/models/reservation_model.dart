import '../../domain/entities/reservation_entity.dart';

/// Modelo de serialización para reservas (Supabase).
class ReservationModel {
  final String id;
  final String tenantId;
  final String tableId;
  final String customerName;
  final String? phone;
  final DateTime reservationTime;
  final int guests;
  final String status;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReservationModel({
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
    required this.updatedAt,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      tableId: json['table_id'] as String,
      customerName: json['customer_name'] as String,
      phone: json['phone'] as String?,
      reservationTime: DateTime.parse(json['reservation_time'] as String),
      guests: json['guests'] as int? ?? 2,
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  ReservationEntity toEntity() {
    return ReservationEntity(
      id: id,
      tenantId: tenantId,
      tableId: tableId,
      customerName: customerName,
      phone: phone,
      reservationTime: reservationTime,
      guests: guests,
      status: ReservationStatus.fromString(status),
      notes: notes,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}
