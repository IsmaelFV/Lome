import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/marketplace_repository_impl.dart';
import '../../../domain/entities/marketplace_entities.dart';

// ---------------------------------------------------------------------------
// Filtros
// ---------------------------------------------------------------------------

class RestaurantFilter {
  final String? cuisineType;
  final String? searchQuery;
  final bool onlyDelivery;
  final bool onlyFeatured;

  const RestaurantFilter({
    this.cuisineType,
    this.searchQuery,
    this.onlyDelivery = false,
    this.onlyFeatured = false,
  });

  RestaurantFilter copyWith({
    String? cuisineType,
    String? searchQuery,
    bool? onlyDelivery,
    bool? onlyFeatured,
    bool clearCuisine = false,
    bool clearSearch = false,
  }) {
    return RestaurantFilter(
      cuisineType: clearCuisine ? null : (cuisineType ?? this.cuisineType),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      onlyDelivery: onlyDelivery ?? this.onlyDelivery,
      onlyFeatured: onlyFeatured ?? this.onlyFeatured,
    );
  }

  bool get hasFilters =>
      cuisineType != null ||
      (searchQuery != null && searchQuery!.isNotEmpty) ||
      onlyDelivery ||
      onlyFeatured;
}

final restaurantFilterProvider = StateProvider<RestaurantFilter>(
  (_) => const RestaurantFilter(),
);

// ---------------------------------------------------------------------------
// Lista de restaurantes
// ---------------------------------------------------------------------------

final marketplaceRestaurantsProvider =
    FutureProvider<List<MarketplaceRestaurant>>((ref) async {
      final repo = ref.read(marketplaceRepositoryProvider);
      final filter = ref.watch(restaurantFilterProvider);

      final rows = await repo.getRestaurants(
        status: 'active',
        deliveryOnly: filter.onlyDelivery ? true : null,
        featuredOnly: filter.onlyFeatured ? true : null,
        cuisineType: filter.cuisineType,
      );

      var restaurants = rows
          .map((r) => MarketplaceRestaurant.fromJson(r))
          .toList();

      // Búsqueda local por nombre
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final q = filter.searchQuery!.toLowerCase();
        restaurants = restaurants
            .where(
              (r) =>
                  r.name.toLowerCase().contains(q) ||
                  r.cuisineType.any((c) => c.toLowerCase().contains(q)) ||
                  (r.city?.toLowerCase().contains(q) ?? false),
            )
            .toList();
      }

      return restaurants;
    });

// ---------------------------------------------------------------------------
// Restaurantes destacados
// ---------------------------------------------------------------------------

final featuredRestaurantsProvider = FutureProvider<List<MarketplaceRestaurant>>(
  (ref) async {
    final repo = ref.read(marketplaceRepositoryProvider);

    final rows = await repo.getRestaurants(
      status: 'active',
      featuredOnly: true,
      limit: 10,
    );

    return rows.map((r) => MarketplaceRestaurant.fromJson(r)).toList();
  },
);

// ---------------------------------------------------------------------------
// Tipos de cocina disponibles
// ---------------------------------------------------------------------------

final cuisineTypesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.read(marketplaceRepositoryProvider);
  return await repo.getCuisineTypes();
});

// ---------------------------------------------------------------------------
// Detalle de un restaurante
// ---------------------------------------------------------------------------

final restaurantDetailProvider =
    FutureProvider.family<MarketplaceRestaurant?, String>((
      ref,
      restaurantId,
    ) async {
      final repo = ref.read(marketplaceRepositoryProvider);

      final response = await repo.getRestaurantDetail(restaurantId);
      if (response == null) return null;
      return MarketplaceRestaurant.fromJson(response);
    });
