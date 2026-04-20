import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/config/supabase_config.dart';
import '../../../data/repositories/customer_order_repository_impl.dart';
import '../../../domain/entities/checkout_entities.dart';

// ---------------------------------------------------------------------------
// Pedido individual (con Realtime)
// ---------------------------------------------------------------------------

/// Provider que carga un pedido y se suscribe a cambios en tiempo real.
final deliveryOrderProvider = StreamProvider.autoDispose
    .family<DeliveryOrder?, String>((ref, orderId) async* {
  final repo = ref.read(customerOrderRepositoryProvider);

  // 1. Carga inicial
  final initial = await repo.getDeliveryOrder(orderId);

  if (initial == null) {
    yield null;
    return;
  }

  yield DeliveryOrder.fromJson(initial);

  // 2. Realtime: escuchar cambios en esta orden
  final controller = StreamController<DeliveryOrder?>();

  final channel = SupabaseConfig.client
      .channel('order_tracking_$orderId')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'orders',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: orderId,
        ),
        callback: (payload) async {
          final updated = await repo.getDeliveryOrder(orderId);
          if (updated != null) {
            controller.add(DeliveryOrder.fromJson(updated));
          }
        },
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  yield* controller.stream;
});

// ---------------------------------------------------------------------------
// Pedidos del cliente (historial)
// ---------------------------------------------------------------------------

final customerOrdersProvider =
    FutureProvider.autoDispose<List<DeliveryOrder>>((ref) async {
  final userId = SupabaseConfig.auth.currentUser?.id;
  if (userId == null) return [];

  final repo = ref.read(customerOrderRepositoryProvider);
  final data = await repo.getCustomerOrders(userId);
  return data.map((json) => DeliveryOrder.fromJson(json)).toList();
});

// ---------------------------------------------------------------------------
// Pedidos activos del cliente (en curso)
// ---------------------------------------------------------------------------

final activeDeliveryOrdersProvider =
    FutureProvider.autoDispose<List<DeliveryOrder>>((ref) async {
  final userId = SupabaseConfig.auth.currentUser?.id;
  if (userId == null) return [];

  final repo = ref.read(customerOrderRepositoryProvider);
  final data = await repo.getActiveDeliveryOrders(userId);
  return data.map((json) => DeliveryOrder.fromJson(json)).toList();
});

// ---------------------------------------------------------------------------
// Acciones de pedido (cancelar)
// ---------------------------------------------------------------------------

final customerOrderActionsProvider =
    Provider<CustomerOrderActions>((ref) {
  return CustomerOrderActions(ref);
});

class CustomerOrderActions {
  final Ref _ref;
  CustomerOrderActions(this._ref);

  Future<void> cancelOrder(String orderId, {String? reason}) async {
    final repo = _ref.read(customerOrderRepositoryProvider);
    await repo.cancelOrder(orderId, reason: reason);
    _ref.invalidate(customerOrdersProvider);
  }
}
