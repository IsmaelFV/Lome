import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/marketplace_repository_impl.dart';
import '../../../domain/entities/marketplace_entities.dart';

// ---------------------------------------------------------------------------
// Menú completo de un restaurante
// ---------------------------------------------------------------------------

final menuCategoriesProvider =
    FutureProvider.family<List<MenuCategory>, String>((
      ref,
      restaurantId,
    ) async {
      final repo = ref.read(marketplaceRepositoryProvider);
      final data = await repo.getMenuCategories(restaurantId);
      return data.map((r) => MenuCategory.fromJson(r)).toList();
    });

final menuDishesProvider = FutureProvider.family<List<Dish>, String>((
  ref,
  restaurantId,
) async {
  final repo = ref.read(marketplaceRepositoryProvider);
  final data = await repo.getMenuItems(restaurantId);
  return data.map((r) => Dish.fromJson(r)).toList();
});

// ---------------------------------------------------------------------------
// Categoría activa
// ---------------------------------------------------------------------------

final activeCategoryProvider = StateProvider<String?>((_) => null);
