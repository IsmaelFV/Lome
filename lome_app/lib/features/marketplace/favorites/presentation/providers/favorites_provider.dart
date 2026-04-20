import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/config/supabase_config.dart';
import '../../../data/repositories/marketplace_repository_impl.dart';
import '../../../domain/entities/marketplace_entities.dart';

// ---------------------------------------------------------------------------
// IDs de restaurantes favoritos del usuario
// ---------------------------------------------------------------------------

final favoriteIdsProvider = FutureProvider<Set<String>>((ref) async {
  final userId = SupabaseConfig.auth.currentUser?.id;
  if (userId == null) return {};
  final repo = ref.read(marketplaceRepositoryProvider);
  final ids = await repo.getFavoriteIds(userId);
  return ids.toSet();
});

// ---------------------------------------------------------------------------
// Comprobar si un restaurante es favorito
// ---------------------------------------------------------------------------

final isFavoriteProvider =
    Provider.family<bool, String>((ref, tenantId) {
  final ids = ref.watch(favoriteIdsProvider).valueOrNull ?? {};
  return ids.contains(tenantId);
});

// ---------------------------------------------------------------------------
// Toggle favorito
// ---------------------------------------------------------------------------

final toggleFavoriteProvider =
    FutureProvider.family<void, String>((ref, tenantId) async {
  final repo = ref.read(marketplaceRepositoryProvider);
  final userId = SupabaseConfig.auth.currentUser!.id;
  final isFav = await repo.isFavorite(userId, tenantId);

  if (isFav) {
    await repo.removeFavorite(userId, tenantId);
  } else {
    await repo.addFavorite(userId, tenantId);
  }

  ref.invalidate(favoriteIdsProvider);
  ref.invalidate(favoriteRestaurantsProvider);
});

// ---------------------------------------------------------------------------
// Lista de restaurantes favoritos (con datos completos)
// ---------------------------------------------------------------------------

final favoriteRestaurantsProvider =
    FutureProvider<List<MarketplaceRestaurant>>((ref) async {
  final userId = SupabaseConfig.auth.currentUser?.id;
  if (userId == null) return [];

  final repo = ref.read(marketplaceRepositoryProvider);
  final ids = await repo.getFavoriteIds(userId);
  if (ids.isEmpty) return [];

  final data = await repo.getFavoriteRestaurants(ids);
  return data
      .map((r) => MarketplaceRestaurant.fromJson(r))
      .toList();
});
