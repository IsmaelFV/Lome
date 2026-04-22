import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/repositories/marketplace_repository_impl.dart';
import '../../../domain/entities/marketplace_entities.dart';

// =============================================================================
// Query
// =============================================================================

final searchQueryProvider = StateProvider.autoDispose<String>((_) => '');

// =============================================================================
// Resultados combinados
// =============================================================================

class SearchResults {
  final List<MarketplaceRestaurant> restaurants;
  final List<DishSearchResult> dishes;

  const SearchResults({this.restaurants = const [], this.dishes = const []});

  bool get isEmpty => restaurants.isEmpty && dishes.isEmpty;
  int get totalCount => restaurants.length + dishes.length;
}

/// Plato con info desnormalizada del restaurante para mostrar en UI.
class DishSearchResult {
  final Dish dish;
  final String restaurantId;
  final String restaurantName;
  final String? restaurantLogo;

  const DishSearchResult({
    required this.dish,
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantLogo,
  });
}

final searchResultsProvider = FutureProvider.autoDispose<SearchResults>((
  ref,
) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.length < 2) return const SearchResults();

  final repo = ref.read(marketplaceRepositoryProvider);

  // Lanzar ambas búsquedas en paralelo
  final results = await Future.wait([
    repo.searchRestaurants(query),
    repo.searchDishes(query),
  ]);

  final restaurants = (results[0])
      .map((r) => MarketplaceRestaurant.fromJson(r))
      .toList();

  final dishes = (results[1]).map((r) {
    final tenant = r['tenants'] as Map<String, dynamic>?;
    return DishSearchResult(
      dish: Dish.fromJson(r),
      restaurantId: tenant?['id'] as String? ?? r['tenant_id'] as String,
      restaurantName: tenant?['name'] as String? ?? '',
      restaurantLogo: tenant?['logo_url'] as String?,
    );
  }).toList();

  return SearchResults(restaurants: restaurants, dishes: dishes);
});

// =============================================================================
// Búsquedas recientes (SharedPreferences)
// =============================================================================

const _recentSearchesKey = 'recent_searches';
const _maxRecentSearches = 8;

final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<String>>((ref) {
      return RecentSearchesNotifier();
    });

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_recentSearchesKey) ?? [];
  }

  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final updated = [
      trimmed,
      ...state.where((s) => s.toLowerCase() != trimmed.toLowerCase()),
    ].take(_maxRecentSearches).toList();

    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, updated);
  }

  Future<void> remove(String query) async {
    state = state.where((s) => s != query).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, state);
  }

  Future<void> clear() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
  }
}
