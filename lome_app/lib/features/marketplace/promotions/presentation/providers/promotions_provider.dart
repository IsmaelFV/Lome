import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/marketplace_repository_impl.dart';
import '../../../domain/entities/review_entities.dart';

// ---------------------------------------------------------------------------
// Promociones activas del marketplace (todas)
// ---------------------------------------------------------------------------

final activePromotionsProvider =
    FutureProvider<List<Promotion>>((ref) async {
  final repo = ref.read(marketplaceRepositoryProvider);
  final data = await repo.getActivePromotions();
  return data
      .map((r) => Promotion.fromJson(r))
      .toList();
});

// ---------------------------------------------------------------------------
// Promociones de un restaurante específico
// ---------------------------------------------------------------------------

final restaurantPromotionsProvider =
    FutureProvider.family<List<Promotion>, String>((ref, tenantId) async {
  final repo = ref.read(marketplaceRepositoryProvider);
  final data = await repo.getRestaurantPromotions(tenantId);
  return data
      .map((r) => Promotion.fromJson(r))
      .toList();
});
