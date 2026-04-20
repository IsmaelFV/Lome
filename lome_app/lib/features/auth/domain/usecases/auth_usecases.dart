import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: Iniciar sesión con email.
class SignInUseCase {
  final AuthRepository _repository;

  const SignInUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
  }) {
    return _repository.signInWithEmail(email: email, password: password);
  }
}

/// Caso de uso: Registrar nuevo usuario.
class SignUpUseCase {
  final AuthRepository _repository;

  const SignUpUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required AccountType accountType,
    String? restaurantName,
  }) {
    return _repository.signUpWithEmail(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      accountType: accountType,
      restaurantName: restaurantName,
    );
  }
}

/// Caso de uso: Cerrar sesión.
class SignOutUseCase {
  final AuthRepository _repository;

  const SignOutUseCase(this._repository);

  Future<Either<Failure, void>> call() => _repository.signOut();
}

/// Caso de uso: Obtener usuario actual.
class GetCurrentUserUseCase {
  final AuthRepository _repository;

  const GetCurrentUserUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call() => _repository.getCurrentUser();
}

/// Caso de uso: Recuperar contraseña.
class ResetPasswordUseCase {
  final AuthRepository _repository;

  const ResetPasswordUseCase(this._repository);

  Future<Either<Failure, void>> call({required String email}) {
    return _repository.resetPassword(email: email);
  }
}

/// Caso de uso: Actualizar contraseña (tras recovery o cambio voluntario).
class UpdatePasswordUseCase {
  final AuthRepository _repository;

  const UpdatePasswordUseCase(this._repository);

  Future<Either<Failure, void>> call({required String newPassword}) {
    return _repository.updatePassword(newPassword: newPassword);
  }
}

/// Caso de uso: Reenviar email de verificación.
class ResendVerificationUseCase {
  final AuthRepository _repository;

  const ResendVerificationUseCase(this._repository);

  Future<Either<Failure, void>> call({required String email}) {
    return _repository.resendVerificationEmail(email: email);
  }
}
