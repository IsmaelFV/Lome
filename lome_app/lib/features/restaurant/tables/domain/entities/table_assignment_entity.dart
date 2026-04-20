import 'package:equatable/equatable.dart';

/// Asignación de un camarero a una mesa.
class TableAssignmentEntity extends Equatable {
  final String id;
  final String tenantId;
  final String tableId;
  final String waiterId;
  final String? waiterName;
  final String? assignedBy;
  final bool isActive;
  final DateTime createdAt;

  const TableAssignmentEntity({
    required this.id,
    required this.tenantId,
    required this.tableId,
    required this.waiterId,
    this.waiterName,
    this.assignedBy,
    required this.isActive,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, tableId, waiterId, isActive];
}
