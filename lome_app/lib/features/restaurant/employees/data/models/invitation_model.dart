import '../../domain/entities/invitation_entity.dart';

/// Modelo de datos para la invitación, mapea desde/hacia JSON (Supabase).
class InvitationModel {
  final String id;
  final String tenantId;
  final String tenantName;
  final String email;
  final String role;
  final String invitedByUserId;
  final String? invitedByName;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? acceptedAt;

  const InvitationModel({
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

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    final tenant = json['tenants'] as Map<String, dynamic>?;
    final inviter = json['inviter'] as Map<String, dynamic>?;

    return InvitationModel(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      tenantName: tenant?['name'] as String? ?? '',
      email: json['email'] as String,
      role: json['role'] as String,
      invitedByUserId: json['invited_by'] as String,
      invitedByName: inviter?['full_name'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
    );
  }

  InvitationEntity toEntity() {
    return InvitationEntity(
      id: id,
      tenantId: tenantId,
      tenantName: tenantName,
      email: email,
      role: role,
      invitedByUserId: invitedByUserId,
      invitedByName: invitedByName,
      status: InvitationStatus.fromString(status),
      createdAt: createdAt,
      expiresAt: expiresAt,
      acceptedAt: acceptedAt,
    );
  }
}
