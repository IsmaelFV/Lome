import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/config/supabase_config.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../data/repositories/customer_order_repository_impl.dart';
import '../../../domain/entities/checkout_entities.dart';
import 'address_provider.dart';

// ---------------------------------------------------------------------------
// Estado del checkout
// ---------------------------------------------------------------------------

enum CheckoutStep { address, payment, confirmation }

class CheckoutState {
  final CheckoutStep step;
  final DeliveryAddress? address;
  final PaymentMethod? paymentMethod;
  final String? deliveryNotes;
  final bool isSubmitting;
  final String? error;
  final DeliveryOrder? createdOrder;

  const CheckoutState({
    this.step = CheckoutStep.address,
    this.address,
    this.paymentMethod,
    this.deliveryNotes,
    this.isSubmitting = false,
    this.error,
    this.createdOrder,
  });

  bool get canProceed {
    switch (step) {
      case CheckoutStep.address:
        return address != null;
      case CheckoutStep.payment:
        return paymentMethod != null;
      case CheckoutStep.confirmation:
        return true;
    }
  }

  CheckoutState copyWith({
    CheckoutStep? step,
    DeliveryAddress? address,
    PaymentMethod? paymentMethod,
    String? deliveryNotes,
    bool? isSubmitting,
    String? error,
    DeliveryOrder? createdOrder,
    bool clearError = false,
    bool clearNotes = false,
  }) {
    return CheckoutState(
      step: step ?? this.step,
      address: address ?? this.address,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryNotes: clearNotes ? null : (deliveryNotes ?? this.deliveryNotes),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      createdOrder: createdOrder ?? this.createdOrder,
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final checkoutProvider =
    StateNotifierProvider.autoDispose<CheckoutNotifier, CheckoutState>((ref) {
      return CheckoutNotifier(ref);
    });

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final Ref _ref;

  CheckoutNotifier(this._ref) : super(const CheckoutState()) {
    // Pre-seleccionar dirección por defecto si existe
    _preselectDefaults();
  }

  Future<void> _preselectDefaults() async {
    try {
      final addresses = await _ref.read(customerAddressesProvider.future);
      final defaultAddr =
          addresses.where((a) => a.isDefault).firstOrNull ??
          (addresses.isNotEmpty ? addresses.first : null);
      if (defaultAddr != null && mounted) {
        state = state.copyWith(address: defaultAddr);
      }
    } catch (_) {}
  }

  void selectAddress(DeliveryAddress address) {
    state = state.copyWith(address: address, clearError: true);
  }

  void selectPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method, clearError: true);
  }

  void setDeliveryNotes(String? notes) {
    if (notes != null && notes.isEmpty) {
      state = state.copyWith(clearNotes: true);
    } else {
      state = state.copyWith(deliveryNotes: notes);
    }
  }

  void nextStep() {
    if (!state.canProceed) return;
    switch (state.step) {
      case CheckoutStep.address:
        state = state.copyWith(step: CheckoutStep.payment, clearError: true);
        break;
      case CheckoutStep.payment:
        state = state.copyWith(
          step: CheckoutStep.confirmation,
          clearError: true,
        );
        break;
      case CheckoutStep.confirmation:
        break;
    }
  }

  void previousStep() {
    switch (state.step) {
      case CheckoutStep.address:
        break;
      case CheckoutStep.payment:
        state = state.copyWith(step: CheckoutStep.address, clearError: true);
        break;
      case CheckoutStep.confirmation:
        state = state.copyWith(step: CheckoutStep.payment, clearError: true);
        break;
    }
  }

  /// Crea el pedido a través del repositorio (orders + order_items + payments).
  Future<String?> placeOrder() async {
    if (state.isSubmitting) return null;

    final cart = _ref.read(cartProvider);
    final address = state.address;
    final paymentMethod = state.paymentMethod;

    if (cart.isEmpty || address == null || paymentMethod == null) {
      state = state.copyWith(error: 'Faltan datos del pedido');
      return null;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final userId = SupabaseConfig.auth.currentUser!.id;
      final repo = _ref.read(customerOrderRepositoryProvider);

      // Calcular totales
      final subtotal = cart.subtotal;
      const deliveryFee = 0.0;
      const taxRate = 0.10;
      final taxAmount = subtotal * taxRate;
      final total = subtotal + taxAmount + deliveryFee;

      // 1. Insertar orden
      final orderData = await repo.placeOrder({
        'tenant_id': cart.restaurantId,
        'customer_id': userId,
        'order_type': 'delivery',
        'status': 'pending',
        'payment_status': 'pending',
        'payment_method': paymentMethod.name,
        'subtotal': subtotal,
        'tax_amount': taxAmount,
        'delivery_fee': deliveryFee,
        'total': total,
        'delivery_address_id': address.id,
        'delivery_notes': state.deliveryNotes,
      });

      final orderId = orderData['id'] as String;

      // 2. Insertar items
      final itemsPayload = cart.items
          .map(
            (item) => {
              'order_id': orderId,
              'tenant_id': cart.restaurantId,
              'menu_item_id': item.dishId,
              'name': item.name,
              'quantity': item.quantity,
              'unit_price': item.unitPrice,
              'total_price': item.totalPrice,
              'notes': item.notes,
            },
          )
          .toList();

      await repo.insertOrderItems(itemsPayload);

      // 3. Registrar pago
      await repo.insertPayment({
        'order_id': orderId,
        'amount': total,
        'method': paymentMethod.name,
        'status': paymentMethod == PaymentMethod.cash ? 'pending' : 'paid',
      });

      // 4. Si no es efectivo, marcar orden como pagada
      if (paymentMethod != PaymentMethod.cash) {
        await repo.updateOrderPaymentStatus(orderId, 'paid');
      }

      // 5. Refrescar con items incluidos
      final fullOrder = await repo.getOrderById(orderId);
      final order = DeliveryOrder.fromJson(fullOrder);
      state = state.copyWith(isSubmitting: false, createdOrder: order);

      // 6. Vaciar carrito
      _ref.read(cartProvider.notifier).clear();

      return orderId;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Error al crear el pedido: $e',
      );
      return null;
    }
  }
}
