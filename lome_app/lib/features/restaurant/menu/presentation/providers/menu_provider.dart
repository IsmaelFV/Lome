import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/restaurant_support_repository_impl.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/menu_design_entity.dart';
import '../../domain/entities/menu_item_entity.dart';
import '../../domain/entities/menu_item_option_entity.dart';

// =============================================================================
// Provider: categorías del menú
// =============================================================================

final menuCategoriesProvider = FutureProvider.autoDispose<List<CategoryEntity>>(
  (ref) async {
    final repo = ref.read(restaurantSupportRepositoryProvider);
    final tenantId = ref.read(activeTenantIdProvider);
    if (tenantId == null) return [];

    final rows = await repo.getMenuCategories(tenantId);

    return rows.map<CategoryEntity>((r) {
      return CategoryEntity(
        id: r['id'] as String,
        tenantId: r['tenant_id'] as String,
        name: r['name'] as String,
        description: r['description'] as String?,
        imageUrl: r['image_url'] as String?,
        sortOrder: r['sort_order'] as int? ?? 0,
        isActive: r['is_active'] as bool? ?? true,
      );
    }).toList();
  },
);

// =============================================================================
// Provider: platos del menú agrupados por categoría
// =============================================================================

final menuDishesProvider = FutureProvider.autoDispose<List<MenuItemEntity>>((
  ref,
) async {
  final repo = ref.read(restaurantSupportRepositoryProvider);
  final tenantId = ref.read(activeTenantIdProvider);
  if (tenantId == null) return [];

  final rows = await repo.getMenuItems(tenantId);

  return rows.map<MenuItemEntity>((r) {
    final category = r['menu_categories'] as Map<String, dynamic>?;
    return MenuItemEntity(
      id: r['id'] as String,
      tenantId: r['tenant_id'] as String,
      categoryId: r['category_id'] as String?,
      categoryName: category?['name'] as String?,
      name: r['name'] as String,
      description: r['description'] as String?,
      price: (r['price'] as num).toDouble(),
      imageUrl: r['image_url'] as String?,
      isAvailable: r['is_available'] as bool? ?? true,
      isFeatured: r['is_featured'] as bool? ?? false,
      preparationTime: r['preparation_time_min'] as int?,
      allergens:
          (r['allergens'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      tags:
          (r['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      sortOrder: r['sort_order'] as int? ?? 0,
    );
  }).toList();
});

// =============================================================================
// Provider: categoría seleccionada en el picker
// =============================================================================

final selectedCategoryProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

// =============================================================================
// Provider: platos filtrados por categoría seleccionada
// =============================================================================

final filteredDishesProvider =
    Provider.autoDispose<AsyncValue<List<MenuItemEntity>>>((ref) {
      final dishesAsync = ref.watch(menuDishesProvider);
      final selectedCat = ref.watch(selectedCategoryProvider);

      return dishesAsync.whenData((dishes) {
        if (selectedCat == null) return dishes;
        return dishes.where((d) => d.categoryId == selectedCat).toList();
      });
    });

// =============================================================================
// Provider: búsqueda de platos
// =============================================================================

final dishSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final searchedDishesProvider =
    Provider.autoDispose<AsyncValue<List<MenuItemEntity>>>((ref) {
      final filteredAsync = ref.watch(filteredDishesProvider);
      final query = ref.watch(dishSearchQueryProvider).toLowerCase().trim();

      if (query.isEmpty) return filteredAsync;

      return filteredAsync.whenData((dishes) {
        return dishes
            .where((d) => d.name.toLowerCase().contains(query))
            .toList();
      });
    });

// =============================================================================
// Notifier: CRUD de categorías
// =============================================================================

final menuCategoryCrudProvider =
    AsyncNotifierProvider.autoDispose<MenuCategoryCrud, void>(
      MenuCategoryCrud.new,
    );

class MenuCategoryCrud extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create({
    required String name,
    String? description,
    String? imageUrl,
  }) async {
    final repo = ref.read(restaurantSupportRepositoryProvider);
    final tenantId = ref.read(activeTenantIdProvider);
    if (tenantId == null) {
      throw Exception(
        'No se encontró el restaurante activo. Cierra sesión e inicia de nuevo.',
      );
    }

    await repo.createMenuCategory({
      'tenant_id': tenantId,
      'name': name,
      'description': description,
      'image_url': imageUrl,
    });
    ref.invalidate(menuCategoriesProvider);
  }

  Future<void> updateCategory(
    String id, {
    String? name,
    String? description,
  }) async {
    final repo = ref.read(restaurantSupportRepositoryProvider);
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    await repo.updateMenuCategory(id, data);
    ref.invalidate(menuCategoriesProvider);
  }

  Future<void> delete(String id) async {
    final repo = ref.read(restaurantSupportRepositoryProvider);
    await repo.deleteMenuCategory(id);
    ref.invalidate(menuCategoriesProvider);
  }
}

// =============================================================================
// Notifier: CRUD de items del menú
// =============================================================================

final menuItemCrudProvider =
    AsyncNotifierProvider.autoDispose<MenuItemCrud, void>(MenuItemCrud.new);

class MenuItemCrud extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create({
    required String name,
    required double price,
    String? categoryId,
    String? description,
    String? imageUrl,
    List<String> allergens = const [],
    List<String> tags = const [],
    int? preparationTime,
    int? calories,
    bool isFeatured = false,
  }) async {
    final repo = ref.read(restaurantSupportRepositoryProvider);
    final tenantId = ref.read(activeTenantIdProvider);
    if (tenantId == null) {
      throw Exception(
        'No se encontró el restaurante activo. Cierra sesión e inicia de nuevo.',
      );
    }

    await repo.createMenuItem({
      'tenant_id': tenantId,
      'category_id': categoryId,
      'name': name,
      'price': price,
      'description': description,
      'image_url': imageUrl,
      'allergens': allergens,
      'tags': tags,
      'preparation_time_min': preparationTime,
      'calories': calories,
      'is_featured': isFeatured,
    });
    ref.invalidate(menuDishesProvider);
  }

  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    final repo = ref.read(restaurantSupportRepositoryProvider);
    await repo.updateMenuItem(id, data);
    ref.invalidate(menuDishesProvider);
  }

  Future<void> delete(String id) async {
    final repo = ref.read(restaurantSupportRepositoryProvider);
    await repo.deleteMenuItem(id);
    ref.invalidate(menuDishesProvider);
  }

  Future<void> toggleAvailability(String id, bool isAvailable) async {
    final repo = ref.read(restaurantSupportRepositoryProvider);
    await repo.updateMenuItem(id, {'is_available': isAvailable});
    ref.invalidate(menuDishesProvider);
  }
}

// =============================================================================
// Provider: opciones de un item
// =============================================================================

final menuItemOptionsProvider = FutureProvider.autoDispose
    .family<List<MenuItemOption>, String>((ref, menuItemId) async {
      final repo = ref.read(restaurantSupportRepositoryProvider);
      final rows = await repo.getMenuItemOptions(menuItemId);
      return rows.map((r) => MenuItemOption.fromJson(r)).toList();
    });

// =============================================================================
// Provider: diseño de carta digital
// =============================================================================

final menuDesignProvider = FutureProvider.autoDispose<MenuDesign?>((ref) async {
  final repo = ref.read(restaurantSupportRepositoryProvider);
  final tenantId = ref.read(activeTenantIdProvider);
  if (tenantId == null) return null;

  final data = await repo.getOrCreateMenuDesign(tenantId);
  return MenuDesign.fromJson(data);
});

final menuDesignCrudProvider =
    AsyncNotifierProvider.autoDispose<MenuDesignCrud, void>(MenuDesignCrud.new);

class MenuDesignCrud extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updateDesign(String id, Map<String, dynamic> data) async {
    final repo = ref.read(restaurantSupportRepositoryProvider);
    await repo.updateMenuDesign(id, data);
    ref.invalidate(menuDesignProvider);
  }

  Future<void> publish(String id) async {
    final repo = ref.read(restaurantSupportRepositoryProvider);
    await repo.updateMenuDesign(id, {
      'is_published': true,
      'published_at': DateTime.now().toIso8601String(),
    });
    ref.invalidate(menuDesignProvider);
  }

  Future<void> unpublish(String id) async {
    final repo = ref.read(restaurantSupportRepositoryProvider);
    await repo.updateMenuDesign(id, {'is_published': false});
    ref.invalidate(menuDesignProvider);
  }
}
