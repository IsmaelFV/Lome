import 'package:equatable/equatable.dart';

/// Entidad de item de inventario.
class InventoryItemEntity extends Equatable {
  final String id;
  final String tenantId;
  final String name;
  final String? description;
  final String? sku;
  final String unit;
  final double currentStock;
  final double minimumStock;
  final double? costPerUnit;
  final String? supplier;
  final String? category;
  final bool isActive;

  const InventoryItemEntity({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    this.sku,
    required this.unit,
    required this.currentStock,
    this.minimumStock = 0,
    this.costPerUnit,
    this.supplier,
    this.category,
    this.isActive = true,
  });

  bool get isLowStock => currentStock <= minimumStock;
  bool get isOutOfStock => currentStock <= 0;

  @override
  List<Object?> get props => [id, name, currentStock];
}
