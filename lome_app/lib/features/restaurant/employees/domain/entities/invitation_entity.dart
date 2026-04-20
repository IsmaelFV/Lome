import 'package:equatable/equatable.dart';

/// Entidad de invitación de empleado a un restaurante.
///
/// Representa una invitación pendiente, aceptada o expirada
/// para unirse a un tenant con un rol específico.
class InvitationEntity extends Equatable {
  final String id;
  final String tenantId;
  final String tenantName;
  final String email;
  final String role;
  final String invitedByUserId;
  final String? invitedByName;
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? acceptedAt;

  const InvitationEntity({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.email,
    required this.role,
    required this.invitedByUserId,
    this.invitedByName,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.acceptedAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPending => status == InvitationStatus.pending && !isExpired;

  @override
  List<Object?> get props => [id, tenantId, email, status];
}

enum InvitationStatus {
  pending,
  accepted,
  rejected,
  expired,
  cancelled;

  static InvitationStatus fromString(String value) {
    return InvitationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InvitationStatus.pending,
    );
  }
}
