import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/admin_repository_impl.dart';
import '../../../domain/entities/admin_entities.dart';

// ---------------------------------------------------------------------------
// Platform analytics (uses the same RPC + extras)
// ---------------------------------------------------------------------------

final adminAnalyticsStatsProvider =
    FutureProvider<AdminPlatformStats>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  final response = await repo.getPlatformMetrics();
  return AdminPlatformStats.fromJson(response);
});

// ---------------------------------------------------------------------------
// Top restaurants by revenue (RPC)
// ---------------------------------------------------------------------------

final adminTopRestaurantsProvider =
    FutureProvider<List<TopRestaurant>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  final response = await repo.getTopRestaurantsByRevenue();

  return response
      .map((r) => TopRestaurant.fromJson(r))
      .toList();
});
