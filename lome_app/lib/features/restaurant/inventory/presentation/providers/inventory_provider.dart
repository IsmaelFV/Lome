import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/restaurant_support_repository_impl.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../domain/repositories/restaurant_support_repository.dart';
import '../../domain/entities/inventory_item_entity.dart';

// =============================================================================
// Provider: items de inventario del tenant activo
// =============================================================================

final inventoryItemsProvider =
    FutureProvider.autoDispose<List<InventoryItemEntity>>((ref) async {
      final repo = ref.read(restaurantSupportRepositoryProvider);
      final tenantId = ref.read(activeTenantIdProvider);
      if (tenantId == null) return [];

      final rows = await repo.getInventoryItems(tenantId);

      return rows.map<InventoryItemEntity>((r) {
        return InventoryItemEntity(
          id: r['id'] as String,
          tenantId: r['tenant_id'] as String,
          name: r['name'] as String,
          description: r['description'] as String?,
          sku: r['sku'] as String?,
          unit: r['unit'] as String? ?? 'unidad',
          currentStock: (r['current_stock'] as num?)?.toDouble() ?? 0,
          minimumStock: (r['minimum_stock'] as num?)?.toDouble() ?? 0,
          costPerUnit: (r['cost_per_unit'] as num?)?.toDouble(),
          supplier: r['supplier'] as String?,
          category: r['category'] as String?,
          isActive: r['is_active'] as bool? ?? true,
        );
      }).toList();
    });

// =============================================================================
// Provider: búsqueda de inventario
// =============================================================================

final inventorySearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

final filteredInventoryProvider =
    Provider.autoDispose<AsyncValue<List<InventoryItemEntity>>>((ref) {
      final query = ref.watch(inventorySearchQueryProvider).toLowerCase();
      final items = ref.watch(inventoryItemsProvider);
      if (query.isEmpty) return items;
      return items.whenData(
        (list) => list
            .where(
              (i) =>
                  i.name.toLowerCase().contains(query) ||
                  (i.sku?.toLowerCase().contains(query) ?? false) ||
                  (i.category?.toLowerCase().contains(query) ?? false),
            )
            .toList(),
      );
    });

// =============================================================================
// CRUD Notifier para inventario
// =============================================================================

final inventoryCrudProvider =
    AsyncNotifierProvider.autoDispose<InventoryCrud, void>(InventoryCrud.new);

class InventoryCrud extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  RestaurantSupportRepository get _repo =>
      ref.read(restaurantSupportRepositoryProvider);
  String? get _tenantId => ref.read(activeTenantIdProvider);

  Future<void> create({
    required String name,
    required String unit,
    double currentStock = 0,
    double minimumStock = 0,
    double? costPerUnit,
    String? description,
    String? sku,
    String? supplier,
    String? category,
  }) async {
    final tenantId = _tenantId;
    if (tenantId == null) {
      throw Exception(
        'No se encontró el restaurante activo. Cierra sesión e inicia de nuevo.',
      );
    }

    await _repo.createInventoryItem({
      'tenant_id': tenantId,
      'name': name,
      'unit': unit,
      'current_stock': currentStock,
      'minimum_stock': minimumStock,
      if (costPerUnit != null) 'cost_per_unit': costPerUnit,
      if (description != null) 'description': description,
      if (sku != null) 'sku': sku,
      if (supplier != null) 'supplier': supplier,
      if (category != null) 'category': category,
    });
    ref.invalidate(inventoryItemsProvider);
  }

  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    await _repo.updateInventoryItem(id, data);
    ref.invalidate(inventoryItemsProvider);
  }

  Future<void> delete(String id) async {
    await _repo.deleteInventoryItem(id);
    ref.invalidate(inventoryItemsProvider);
  }

  Future<void> adjustStock(String id, double newStock) async {
    await _repo.updateInventoryItem(id, {'current_stock': newStock});
    ref.invalidate(inventoryItemsProvider);
  }
}
