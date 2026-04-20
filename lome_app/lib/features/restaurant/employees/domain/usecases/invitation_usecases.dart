import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/invitation_entity.dart';
import '../repositories/invitation_repository.dart';

/// Envía una invitación a un email para unirse al restaurante.
class SendInvitationUseCase {
  final InvitationRepository _repository;
  const SendInvitationUseCase(this._repository);

  Future<Either<Failure, InvitationEntity>> call({
    required String tenantId,
    required String email,
    required String role,
  }) {
    return _repository.sendInvitation(
      tenantId: tenantId,
      email: email,
      role: role,
    );
  }
}

/// Obtiene las invitaciones de un tenant.
class GetInvitationsUseCase {
  final InvitationRepository _repository;
  const GetInvitationsUseCase(this._repository);

  Future<Either<Failure, List<InvitationEntity>>> call({
    required String tenantId,
    InvitationStatus? filterStatus,
  }) {
    return _repository.getInvitations(
      tenantId: tenantId,
      filterStatus: filterStatus,
    );
  }
}

/// Cancela una invitación pendiente.
class CancelInvitationUseCase {
  final InvitationRepository _repository;
  const CancelInvitationUseCase(this._repository);

  Future<Either<Failure, void>> call({required String invitationId}) {
    return _repository.cancelInvitation(invitationId: invitationId);
  }
}

/// Reenvía una invitación.
class ResendInvitationUseCase {
  final InvitationRepository _repository;
  const ResendInvitationUseCase(this._repository);

  Future<Either<Failure, InvitationEntity>> call({
    required String invitationId,
  }) {
    return _repository.resendInvitation(invitationId: invitationId);
  }
}

/// Acepta la invitación y crea la membresía.
class AcceptInvitationUseCase {
  final InvitationRepository _repository;
  const AcceptInvitationUseCase(this._repository);

  Future<Either<Failure, void>> call({required String invitationId}) {
    return _repository.acceptInvitation(invitationId: invitationId);
  }
}

/// Elimina un empleado del restaurante.
class RemoveEmployeeUseCase {
  final InvitationRepository _repository;
  const RemoveEmployeeUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String tenantId,
    required String membershipId,
  }) {
    return _repository.removeEmployee(
      tenantId: tenantId,
      membershipId: membershipId,
    );
  }
}

/// Actualiza el rol de un empleado.
class UpdateEmployeeRoleUseCase {
  final InvitationRepository _repository;
  const UpdateEmployeeRoleUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String membershipId,
    required String newRole,
  }) {
    return _repository.updateEmployeeRole(
      membershipId: membershipId,
      newRole: newRole,
    );
  }
}
