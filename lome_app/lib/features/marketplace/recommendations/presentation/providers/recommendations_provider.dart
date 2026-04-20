import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/config/supabase_config.dart';
import '../../../data/repositories/marketplace_repository_impl.dart';
import '../../../domain/entities/marketplace_entities.dart';

// ---------------------------------------------------------------------------
// Restaurantes recomendados (RPC PostgreSQL)
// ---------------------------------------------------------------------------

final recommendedRestaurantsProvider =
    FutureProvider<List<MarketplaceRestaurant>>((ref) async {
  final userId = SupabaseConfig.auth.currentUser?.id;
  if (userId == null) return [];

  final repo = ref.read(marketplaceRepositoryProvider);
  final data = await repo.getRecommendedRestaurants(userId);
  return data
      .map((r) => MarketplaceRestaurant.fromJson(r))
      .toList();
});
