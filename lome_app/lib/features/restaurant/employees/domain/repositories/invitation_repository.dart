import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/invitation_entity.dart';

/// Contrato del repositorio de invitaciones de empleados.
abstract class InvitationRepository {
  /// Envía una invitación a un email para unirse al tenant con un rol.
  Future<Either<Failure, InvitationEntity>> sendInvitation({
    required String tenantId,
    required String email,
    required String role,
  });

  /// Lista las invitaciones de un tenant (pendientes, aceptadas, etc.).
  Future<Either<Failure, List<InvitationEntity>>> getInvitations({
    required String tenantId,
    InvitationStatus? filterStatus,
  });

  /// Cancela una invitación pendiente.
  Future<Either<Failure, void>> cancelInvitation({required String invitationId});

  /// Reenvía una invitación existente (genera nuevo token/fecha expiración).
  Future<Either<Failure, InvitationEntity>> resendInvitation({
    required String invitationId,
  });

  /// Acepta una invitación (crea la membresía del empleado).
  Future<Either<Failure, void>> acceptInvitation({required String invitationId});

  /// Rechaza una invitación.
  Future<Either<Failure, void>> rejectInvitation({required String invitationId});

  /// Elimina la membresía de un empleado del tenant.
  Future<Either<Failure, void>> removeEmployee({
    required String tenantId,
    required String membershipId,
  });

  /// Actualiza el rol de un empleado en el tenant.
  Future<Either<Failure, void>> updateEmployeeRole({
    required String membershipId,
    required String newRole,
  });
}
