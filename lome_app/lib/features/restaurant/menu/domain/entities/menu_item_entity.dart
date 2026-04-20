import 'package:equatable/equatable.dart';

/// Entidad de item del menu.
class MenuItemEntity extends Equatable {
  final String id;
  final String tenantId;
  final String? categoryId;
  final String? categoryName;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
  final bool isFeatured;
  final int? preparationTime;
  final List<String> allergens;
  final List<String> tags;
  final int sortOrder;

  const MenuItemEntity({
    required this.id,
    required this.tenantId,
    this.categoryId,
    this.categoryName,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.isAvailable = true,
    this.isFeatured = false,
    this.preparationTime,
    this.allergens = const [],
    this.tags = const [],
    this.sortOrder = 0,
  });

  @override
  List<Object?> get props => [id, name, price, isAvailable];
}

/// Entidad de categoria del menu.
class CategoryEntity extends Equatable {
  final String id;
  final String tenantId;
  final String name;
  final String? description;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;
  final List<MenuItemEntity> items;

  const CategoryEntity({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    this.imageUrl,
    this.sortOrder = 0,
    this.isActive = true,
    this.items = const [],
  });

  @override
  List<Object?> get props => [id, name, isActive];
}
