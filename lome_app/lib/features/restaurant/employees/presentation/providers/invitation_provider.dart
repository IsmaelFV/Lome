import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/providers/supabase_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/invitation_remote_datasource.dart';
import '../../data/repositories/invitation_repository_impl.dart';
import '../../domain/entities/employee_entity.dart';
import '../../domain/entities/invitation_entity.dart';
import '../../domain/repositories/invitation_repository.dart';
import '../../domain/usecases/invitation_usecases.dart';

// ---------------------------------------------------------------------------
// Data layer
// ---------------------------------------------------------------------------

final invitationDataSourceProvider = Provider<InvitationRemoteDataSource>((
  ref,
) {
  return InvitationRemoteDataSourceImpl(
    client: ref.watch(supabaseClientProvider),
  );
});

final invitationRepositoryProvider = Provider<InvitationRepository>((ref) {
  return InvitationRepositoryImpl(
    remoteDataSource: ref.watch(invitationDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

// ---------------------------------------------------------------------------
// Use cases
// ---------------------------------------------------------------------------

final sendInvitationUseCaseProvider = Provider<SendInvitationUseCase>((ref) {
  return SendInvitationUseCase(ref.watch(invitationRepositoryProvider));
});

final getInvitationsUseCaseProvider = Provider<GetInvitationsUseCase>((ref) {
  return GetInvitationsUseCase(ref.watch(invitationRepositoryProvider));
});

final cancelInvitationUseCaseProvider = Provider<CancelInvitationUseCase>((
  ref,
) {
  return CancelInvitationUseCase(ref.watch(invitationRepositoryProvider));
});

final resendInvitationUseCaseProvider = Provider<ResendInvitationUseCase>((
  ref,
) {
  return ResendInvitationUseCase(ref.watch(invitationRepositoryProvider));
});

final removeEmployeeUseCaseProvider = Provider<RemoveEmployeeUseCase>((ref) {
  return RemoveEmployeeUseCase(ref.watch(invitationRepositoryProvider));
});

final updateEmployeeRoleUseCaseProvider = Provider<UpdateEmployeeRoleUseCase>((
  ref,
) {
  return UpdateEmployeeRoleUseCase(ref.watch(invitationRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Employees list
// ---------------------------------------------------------------------------

/// Provider que carga la lista de empleados activos del tenant.
/// Se invalida cuando cambia el tenant activo.
final employeesProvider = FutureProvider<List<EmployeeEntity>>((ref) async {
  final tenantId = ref.watch(activeTenantIdProvider);
  if (tenantId == null) return [];

  final datasource = ref.watch(invitationDataSourceProvider);
  return datasource.getEmployees(tenantId: tenantId);
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class InvitationState {
  final List<InvitationEntity> invitations;
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;
  final String? successMessage;

  const InvitationState({
    this.invitations = const [],
    this.isLoading = false,
    this.isSending = false,
    this.errorMessage,
    this.successMessage,
  });

  InvitationState copyWith({
    List<InvitationEntity>? invitations,
    bool? isLoading,
    bool? isSending,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return InvitationState(
      invitations: invitations ?? this.invitations,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

final invitationNotifierProvider =
    StateNotifierProvider<InvitationNotifier, InvitationState>((ref) {
      return InvitationNotifier(ref);
    });

class InvitationNotifier extends StateNotifier<InvitationState> {
  final Ref _ref;

  InvitationNotifier(this._ref) : super(const InvitationState());

  String? get _tenantId => _ref.read(activeTenantIdProvider);

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  /// Carga las invitaciones del tenant activo.
  Future<void> loadInvitations({InvitationStatus? filterStatus}) async {
    final tenantId = _tenantId;
    if (tenantId == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _ref
        .read(getInvitationsUseCaseProvider)
        .call(tenantId: tenantId, filterStatus: filterStatus);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (invitations) =>
          state = state.copyWith(isLoading: false, invitations: invitations),
    );
  }

  /// Envía una invitación a un email con un rol.
  Future<bool> sendInvitation({
    required String email,
    required String role,
  }) async {
    final tenantId = _tenantId;
    if (tenantId == null) {
      state = state.copyWith(errorMessage: 'No hay restaurante activo');
      return false;
    }

    state = state.copyWith(
      isSending: true,
      clearError: true,
      clearSuccess: true,
    );
    final result = await _ref
        .read(sendInvitationUseCaseProvider)
        .call(tenantId: tenantId, email: email, role: role);
    return result.fold(
      (failure) {
        state = state.copyWith(isSending: false, errorMessage: failure.message);
        return false;
      },
      (invitation) {
        state = state.copyWith(
          isSending: false,
          invitations: [invitation, ...state.invitations],
          successMessage: 'Invitación enviada a $email',
        );
        return true;
      },
    );
  }

  /// Cancela una invitación pendiente.
  Future<void> cancelInvitation(String invitationId) async {
    state = state.copyWith(clearError: true);
    final result = await _ref
        .read(cancelInvitationUseCaseProvider)
        .call(invitationId: invitationId);
    result.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
      (_) {
        final updated = state.invitations
            .map(
              (i) => i.id == invitationId
                  ? InvitationEntity(
                      id: i.id,
                      tenantId: i.tenantId,
                      tenantName: i.tenantName,
                      email: i.email,
                      role: i.role,
                      invitedByUserId: i.invitedByUserId,
                      invitedByName: i.invitedByName,
                      status: InvitationStatus.cancelled,
                      createdAt: i.createdAt,
                      expiresAt: i.expiresAt,
                    )
                  : i,
            )
            .toList();
        state = state.copyWith(
          invitations: updated,
          successMessage: 'Invitación cancelada',
        );
      },
    );
  }

  /// Reenvía una invitación.
  Future<void> resendInvitation(String invitationId) async {
    state = state.copyWith(clearError: true);
    final result = await _ref
        .read(resendInvitationUseCaseProvider)
        .call(invitationId: invitationId);
    result.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
      (updated) {
        final list = state.invitations
            .map((i) => i.id == invitationId ? updated : i)
            .toList();
        state = state.copyWith(
          invitations: list,
          successMessage: 'Invitación reenviada',
        );
      },
    );
  }

  /// Elimina un empleado (desactiva su membresía).
  Future<bool> removeEmployee(String membershipId) async {
    final tenantId = _tenantId;
    if (tenantId == null) return false;

    state = state.copyWith(clearError: true);
    final result = await _ref
        .read(removeEmployeeUseCaseProvider)
        .call(tenantId: tenantId, membershipId: membershipId);
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          successMessage: 'Empleado eliminado del restaurante',
        );
        return true;
      },
    );
  }

  /// Actualiza el rol de un empleado.
  Future<bool> updateEmployeeRole({
    required String membershipId,
    required String newRole,
  }) async {
    state = state.copyWith(clearError: true);
    final result = await _ref
        .read(updateEmployeeRoleUseCaseProvider)
        .call(membershipId: membershipId, newRole: newRole);
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(successMessage: 'Rol actualizado');
        return true;
      },
    );
  }
}
