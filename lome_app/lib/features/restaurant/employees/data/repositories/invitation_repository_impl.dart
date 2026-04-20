import 'package:dartz/dartz.dart';
import '../../../../../core/errors/exceptions.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/network/network_info.dart';
import '../../domain/entities/invitation_entity.dart';
import '../../domain/repositories/invitation_repository.dart';
import '../datasources/invitation_remote_datasource.dart';

class InvitationRepositoryImpl implements InvitationRepository {
  final InvitationRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  InvitationRepositoryImpl({
    required InvitationRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, InvitationEntity>> sendInvitation({
    required String tenantId,
    required String email,
    required String role,
  }) async {
    return _execute(() async {
      final model = await _remoteDataSource.sendInvitation(
        tenantId: tenantId,
        email: email,
        role: role,
      );
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, List<InvitationEntity>>> getInvitations({
    required String tenantId,
    InvitationStatus? filterStatus,
  }) async {
    return _execute(() async {
      final models = await _remoteDataSource.getInvitations(
        tenantId: tenantId,
        filterStatus: filterStatus?.name,
      );
      return models.map((m) => m.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, void>> cancelInvitation({
    required String invitationId,
  }) async {
    return _execute(
      () => _remoteDataSource.cancelInvitation(invitationId: invitationId),
    );
  }

  @override
  Future<Either<Failure, InvitationEntity>> resendInvitation({
    required String invitationId,
  }) async {
    return _execute(() async {
      final model = await _remoteDataSource.resendInvitation(
        invitationId: invitationId,
      );
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, void>> acceptInvitation({
    required String invitationId,
  }) async {
    return _execute(
      () => _remoteDataSource.acceptInvitation(invitationId: invitationId),
    );
  }

  @override
  Future<Either<Failure, void>> rejectInvitation({
    required String invitationId,
  }) async {
    return _execute(
      () => _remoteDataSource.rejectInvitation(invitationId: invitationId),
    );
  }

  @override
  Future<Either<Failure, void>> removeEmployee({
    required String tenantId,
    required String membershipId,
  }) async {
    return _execute(
      () => _remoteDataSource.removeEmployee(
        tenantId: tenantId,
        membershipId: membershipId,
      ),
    );
  }

  @override
  Future<Either<Failure, void>> updateEmployeeRole({
    required String membershipId,
    required String newRole,
  }) async {
    return _execute(
      () => _remoteDataSource.updateEmployeeRole(
        membershipId: membershipId,
        newRole: newRole,
      ),
    );
  }

  Future<Either<Failure, T>> _execute<T>(
    Future<T> Function() operation,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await operation();
      return Right(result);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
