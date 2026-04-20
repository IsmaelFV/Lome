import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_info.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

// ---------------------------------------------------------------------------
// Data layer providers
// ---------------------------------------------------------------------------

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(client: ref.watch(supabaseClientProvider));
});

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

// ---------------------------------------------------------------------------
// Use case providers
// ---------------------------------------------------------------------------

final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  return SignInUseCase(ref.watch(authRepositoryProvider));
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  return SignUpUseCase(ref.watch(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>((ref) {
  return ResetPasswordUseCase(ref.watch(authRepositoryProvider));
});

final updatePasswordUseCaseProvider = Provider<UpdatePasswordUseCase>((ref) {
  return UpdatePasswordUseCase(ref.watch(authRepositoryProvider));
});

final resendVerificationUseCaseProvider = Provider<ResendVerificationUseCase>((
  ref,
) {
  return ResendVerificationUseCase(ref.watch(authRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Auth state provider (reactive)
// ---------------------------------------------------------------------------

/// Provider que escucha los cambios de estado de autenticación.
/// Es el punto central que el router usa para decidir las redirecciones.
final authStateProvider = StreamProvider<UserEntity?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

/// Provider del usuario actual autenticado.
final currentUserProvider = FutureProvider<UserEntity?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull;
});

/// true si existe sesión almacenada localmente (para el splash rápido).
final hasActiveSessionProvider = Provider<bool>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.hasActiveSession;
});

/// Provider del tenant activo seleccionado.
final activeTenantIdProvider = StateProvider<String?>((ref) => null);

/// Provider de la membresía activa del usuario en el tenant seleccionado.
final activeMembershipProvider = Provider<TenantMembership?>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final tenantId = ref.watch(activeTenantIdProvider);
  if (user == null || tenantId == null) return null;
  return user.memberships
      .where((m) => m.tenantId == tenantId && m.isActive)
      .firstOrNull;
});

// ---------------------------------------------------------------------------
// Auth actions notifier
// ---------------------------------------------------------------------------

/// Notifier para ejecutar acciones de autenticación.
/// Gestiona login, registro, cierre de sesión, recuperación y verificación.
final authActionsProvider =
    StateNotifierProvider<AuthActionsNotifier, AsyncValue<void>>((ref) {
      return AuthActionsNotifier(ref);
    });

class AuthActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AuthActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Limpia el estado de error actual.
  void clearError() {
    state = const AsyncValue.data(null);
  }

  /// Inicia sesión. Devuelve el [UserEntity] si tiene éxito, null si falla.
  Future<UserEntity?> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final result = await _ref
        .read(signInUseCaseProvider)
        .call(email: email, password: password);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (user) {
        state = const AsyncValue.data(null);
        // Auto-seleccionar primer tenant
        if (user.memberships.isNotEmpty) {
          _ref.read(activeTenantIdProvider.notifier).state =
              user.memberships.first.tenantId;
        }
        return user;
      },
    );
  }

  /// Registra un nuevo usuario. Devuelve el [UserEntity] si tiene éxito, null si falla.
  Future<UserEntity?> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required AccountType accountType,
    String? restaurantName,
  }) async {
    state = const AsyncValue.loading();
    final result = await _ref
        .read(signUpUseCaseProvider)
        .call(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
          accountType: accountType,
          restaurantName: restaurantName,
        );
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (user) {
        state = const AsyncValue.data(null);
        // Auto-seleccionar primer tenant (igual que signIn)
        if (user.memberships.isNotEmpty) {
          _ref.read(activeTenantIdProvider.notifier).state =
              user.memberships.first.tenantId;
        }
        // Forzar re-fetch del auth state para que el router tenga los memberships
        _ref.invalidate(authStateProvider);
        return user;
      },
    );
  }

  /// Cierra la sesión actual.
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await _ref.read(signOutUseCaseProvider).call();
    _ref.read(activeTenantIdProvider.notifier).state = null;
    state = const AsyncValue.data(null);
  }

  /// Envía email de recuperación de contraseña.
  Future<bool> resetPassword({required String email}) async {
    state = const AsyncValue.loading();
    final result = await _ref
        .read(resetPasswordUseCaseProvider)
        .call(email: email);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }

  /// Actualiza la contraseña del usuario (tras recovery o cambio voluntario).
  Future<bool> updatePassword({required String newPassword}) async {
    state = const AsyncValue.loading();
    final result = await _ref
        .read(updatePasswordUseCaseProvider)
        .call(newPassword: newPassword);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }

  /// Reenvía el email de verificación.
  Future<bool> resendVerification({required String email}) async {
    state = const AsyncValue.loading();
    final result = await _ref
        .read(resendVerificationUseCaseProvider)
        .call(email: email);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }
}
