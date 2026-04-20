import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../entities/user_entity.dart';

/// Contrato del repositorio de autenticación.
///
/// Define las operaciones de auth disponibles en la capa de dominio.
/// La implementación concreta está en la capa de datos.
abstract class AuthRepository {
  /// Stream del estado de autenticación.
  Stream<UserEntity?> get authStateChanges;

  /// true si hay una sesión activa almacenada localmente.
  bool get hasActiveSession;

  /// Usuario actual o null si no está autenticado.
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Inicio de sesión con email y contraseña.
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Registro con email y contraseña.
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required AccountType accountType,
    String? restaurantName,
  });

  /// Cierre de sesión.
  Future<Either<Failure, void>> signOut();

  /// Enviar email de recuperación de contraseña.
  Future<Either<Failure, void>> resetPassword({required String email});

  /// Actualizar contraseña.
  Future<Either<Failure, void>> updatePassword({
    required String newPassword,
  });

  /// Actualizar perfil del usuario.
  Future<Either<Failure, UserEntity>> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  });

  /// Reenviar email de verificación.
  Future<Either<Failure, void>> resendVerificationEmail({required String email});
}
