import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementación concreta del repositorio de autenticación.
///
/// Orquesta el acceso a datos remotos, maneja excepciones
/// y las convierte en Failures para la capa de dominio.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo;

  @override
  bool get hasActiveSession => _remoteDataSource.currentSession != null;

  @override
  Stream<UserEntity?> get authStateChanges {
    return _remoteDataSource.authStateChanges.asyncMap((state) async {
      if (state.session?.user != null) {
        try {
          final user = await _remoteDataSource.getCurrentUser();
          return user.toEntity();
        } catch (_) {
          return null;
        }
      }
      return null;
    });
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    return _execute(() async {
      final user = await _remoteDataSource.getCurrentUser();
      return user.toEntity();
    });
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _execute(() async {
      final user = await _remoteDataSource.signInWithEmail(email, password);
      return user.toEntity();
    });
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required AccountType accountType,
    String? restaurantName,
  }) async {
    return _execute(() async {
      final user = await _remoteDataSource.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        accountType: accountType,
        restaurantName: restaurantName,
      );
      return user.toEntity();
    });
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    return _execute(() => _remoteDataSource.signOut());
  }

  @override
  Future<Either<Failure, void>> resetPassword({required String email}) async {
    return _execute(() => _remoteDataSource.resetPassword(email));
  }

  @override
  Future<Either<Failure, void>> updatePassword({
    required String newPassword,
  }) async {
    return _execute(() => _remoteDataSource.updatePassword(newPassword));
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    return _execute(() async {
      final user = await _remoteDataSource.updateProfile(
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      return user.toEntity();
    });
  }

  @override
  Future<Either<Failure, void>> resendVerificationEmail({
    required String email,
  }) async {
    return _execute(() => _remoteDataSource.resendVerificationEmail(email));
  }

  /// Ejecuta una operación con manejo de errores estandarizado.
  Future<Either<Failure, T>> _execute<T>(Future<T> Function() operation) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await operation();
      return Right(result);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
