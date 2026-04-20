import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/order_repository_impl.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/order_entity.dart';

// =============================================================================
// Filtros del historial
// =============================================================================

class OrderHistoryFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? waiterId;
  final String? waiterName;
  final OrderStatus? status;
  final String? searchQuery;

  const OrderHistoryFilter({
    this.startDate,
    this.endDate,
    this.waiterId,
    this.waiterName,
    this.status,
    this.searchQuery,
  });

  OrderHistoryFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? waiterId,
    String? waiterName,
    OrderStatus? status,
    String? searchQuery,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearWaiter = false,
    bool clearStatus = false,
    bool clearSearch = false,
  }) {
    return OrderHistoryFilter(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      waiterId: clearWaiter ? null : (waiterId ?? this.waiterId),
      waiterName: clearWaiter ? null : (waiterName ?? this.waiterName),
      status: clearStatus ? null : (status ?? this.status),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }

  bool get hasFilters =>
      startDate != null ||
      endDate != null ||
      waiterId != null ||
      status != null ||
      (searchQuery != null && searchQuery!.isNotEmpty);
}

// =============================================================================
// Provider del filtro
// =============================================================================

final orderHistoryFilterProvider = StateProvider<OrderHistoryFilter>(
  (_) => const OrderHistoryFilter(),
);

// =============================================================================
// Provider de datos
// =============================================================================

final orderHistoryProvider = FutureProvider<List<OrderEntity>>((ref) async {
  final repo = ref.read(orderRepositoryProvider);
  final tenantId = ref.read(activeTenantIdProvider);
  if (tenantId == null) return [];

  final filter = ref.watch(orderHistoryFilterProvider);

  // Determinar estados
  final statuses = filter.status != null
      ? [filter.status!.name]
      : ['completed', 'cancelled', 'delivered'];

  // Ajustar endDate al final del día
  DateTime? dateTo;
  if (filter.endDate != null) {
    dateTo = DateTime(
      filter.endDate!.year,
      filter.endDate!.month,
      filter.endDate!.day,
      23,
      59,
      59,
    );
  }

  var orders = await repo.getOrderHistory(
    tenantId,
    statuses: statuses,
    waiterId: filter.waiterId,
    dateFrom: filter.startDate,
    dateTo: dateTo,
    limit: 100,
  );

  // Filtro local por búsqueda (número de pedido)
  if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
    final q = filter.searchQuery!.toLowerCase();
    orders = orders
        .where(
          (o) =>
              o.orderNumber.toString().contains(q) ||
              (o.waiterName?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  return orders;
});

// =============================================================================
// Provider: lista de camareros para filtro
// =============================================================================

final waiterListProvider = FutureProvider<List<Map<String, String>>>((
  ref,
) async {
  final repo = ref.read(orderRepositoryProvider);
  final tenantId = ref.read(activeTenantIdProvider);
  if (tenantId == null) return [];

  final rows = await repo.getWaiterList(tenantId);

  return rows.map<Map<String, String>>((r) {
    final profile = r['profiles'] as Map<String, dynamic>?;
    return {
      'id': r['user_id'] as String,
      'name': profile?['full_name'] as String? ?? 'Sin nombre',
    };
  }).toList();
});
