import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/table_entity.dart';

/// Contrato del repositorio de mesas.
abstract class TablesRepository {
  /// Obtiene todas las mesas del restaurante.
  Future<Either<Failure, List<TableEntity>>> getTables(String tenantId);

  /// Obtiene una mesa por ID.
  Future<Either<Failure, TableEntity>> getTableById(String tableId);

  /// Crea una nueva mesa.
  Future<Either<Failure, TableEntity>> createTable({
    required String tenantId,
    required int number,
    String? name,
    required int capacity,
    String? zone,
  });

  /// Actualiza una mesa.
  Future<Either<Failure, TableEntity>> updateTable({
    required String tableId,
    int? number,
    String? name,
    int? capacity,
    String? zone,
    TableStatus? status,
  });

  /// Elimina (desactiva) una mesa.
  Future<Either<Failure, void>> deleteTable(String tableId);

  /// Abre una sesion en una mesa.
  Future<Either<Failure, String>> openTableSession({
    required String tenantId,
    required String tableId,
    String? waiterId,
    int guestsCount,
  });

  /// Cierra la sesion de una mesa.
  Future<Either<Failure, void>> closeTableSession(String sessionId);

  /// Stream de mesas en tiempo real.
  Stream<List<TableEntity>> watchTables(String tenantId);
}
