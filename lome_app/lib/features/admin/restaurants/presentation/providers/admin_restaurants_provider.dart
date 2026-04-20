import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/admin_repository_impl.dart';
import '../../../dashboard/presentation/providers/admin_dashboard_provider.dart';
import '../../../domain/entities/admin_entities.dart';

// ---------------------------------------------------------------------------
// Filter state
// ---------------------------------------------------------------------------

final adminRestaurantFilterProvider =
    StateProvider<String>((_) => 'all'); // all, active, pending, suspended

final adminRestaurantSearchProvider =
    StateProvider<String>((_) => '');

// ---------------------------------------------------------------------------
// All restaurants for admin
// ---------------------------------------------------------------------------

final adminRestaurantsProvider =
    FutureProvider<List<AdminRestaurant>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  final filter = ref.watch(adminRestaurantFilterProvider);
  final search = ref.watch(adminRestaurantSearchProvider);

  final response = await repo.getRestaurants(
    status: filter != 'all' ? filter : null,
  );

  var restaurants = response
      .map((r) => AdminRestaurant.fromJson(r))
      .toList();

  if (search.isNotEmpty) {
    final q = search.toLowerCase();
    restaurants = restaurants
        .where((r) =>
            r.name.toLowerCase().contains(q) ||
            (r.city?.toLowerCase().contains(q) ?? false) ||
            (r.email?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  return restaurants;
});

// ---------------------------------------------------------------------------
// Restaurant counts by status
// ---------------------------------------------------------------------------

final adminRestaurantCountsProvider =
    Provider<Map<String, int>>((ref) {
  final all = ref.watch(adminRestaurantsProvider).valueOrNull ?? [];
  // When filter is applied, we only see filtered restaurants.
  // So we fetch all first via a separate provider for counts.
  return {
    'total': all.length,
    'active': all.where((r) => r.status == 'active').length,
    'pending': all.where((r) => r.status == 'pending').length,
    'suspended': all.where((r) => r.status == 'suspended').length,
  };
});

// Use the unfiltered list for counts
final adminAllRestaurantsProvider =
    FutureProvider<List<AdminRestaurant>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  final response = await repo.getRestaurants();

  return response
      .map((r) => AdminRestaurant.fromJson(r))
      .toList();
});

final adminStatusCountsProvider =
    Provider<Map<String, int>>((ref) {
  final all = ref.watch(adminAllRestaurantsProvider).valueOrNull ?? [];
  return {
    'total': all.length,
    'active': all.where((r) => r.status == 'active').length,
    'pending': all.where((r) => r.status == 'pending').length,
    'suspended': all.where((r) => r.status == 'suspended').length,
  };
});

// ---------------------------------------------------------------------------
// Single restaurant detail
// ---------------------------------------------------------------------------

final adminRestaurantDetailProvider =
    FutureProvider.family<AdminRestaurant?, String>((ref, id) async {
  final repo = ref.read(adminRepositoryProvider);
  final response = await repo.getRestaurantDetail(id);

  if (response == null) return null;
  return AdminRestaurant.fromJson(response);
});

// ---------------------------------------------------------------------------
// Restaurant stats (RPC)
// ---------------------------------------------------------------------------

final adminRestaurantStatsProvider =
    FutureProvider.family<AdminRestaurantStats, String>((ref, tenantId) async {
  final repo = ref.read(adminRepositoryProvider);
  final response = await repo.getRestaurantStats(tenantId);
  return AdminRestaurantStats.fromJson(response);
});

// ---------------------------------------------------------------------------
// Toggle restaurant status
// ---------------------------------------------------------------------------

final toggleRestaurantStatusProvider =
    FutureProvider.family<void, ({String id, String newStatus})>(
        (ref, params) async {
  final repo = ref.read(adminRepositoryProvider);
  await repo.toggleRestaurantStatus(params.id, params.newStatus);

  ref.invalidate(adminRestaurantsProvider);
  ref.invalidate(adminAllRestaurantsProvider);
  ref.invalidate(adminRestaurantDetailProvider(params.id));
  ref.invalidate(adminPlatformStatsProvider);
});


