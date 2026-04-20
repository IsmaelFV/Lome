import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/marketplace_entities.dart';

// ---------------------------------------------------------------------------
// Cart item model
// ---------------------------------------------------------------------------

class CartItem {
  final String id; // dish.id + notes hash for uniqueness
  final String dishId;
  final String restaurantId;
  final String name;
  final double unitPrice;
  final String? imageUrl;
  final int quantity;
  final String? notes;

  const CartItem({
    required this.id,
    required this.dishId,
    required this.restaurantId,
    required this.name,
    required this.unitPrice,
    this.imageUrl,
    required this.quantity,
    this.notes,
  });

  double get totalPrice => unitPrice * quantity;

  CartItem copyWith({int? quantity, String? notes}) {
    return CartItem(
      id: id,
      dishId: dishId,
      restaurantId: restaurantId,
      name: name,
      unitPrice: unitPrice,
      imageUrl: imageUrl,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }
}

// ---------------------------------------------------------------------------
// Cart state
// ---------------------------------------------------------------------------

class CartState {
  final String? restaurantId;
  final String? restaurantName;
  final List<CartItem> items;

  const CartState({
    this.restaurantId,
    this.restaurantName,
    this.items = const [],
  });

  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);
  double get subtotal => items.fold(0, (sum, i) => sum + i.totalPrice);
  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    String? restaurantId,
    String? restaurantName,
    List<CartItem>? items,
    bool clearRestaurant = false,
  }) {
    return CartState(
      restaurantId: clearRestaurant
          ? null
          : (restaurantId ?? this.restaurantId),
      restaurantName: clearRestaurant
          ? null
          : (restaurantName ?? this.restaurantName),
      items: items ?? this.items,
    );
  }
}

// ---------------------------------------------------------------------------
// Cart notifier
// ---------------------------------------------------------------------------

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(),
);

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  /// Añade un plato al carrito.
  /// Si el carrito tiene items de otro restaurante se vacía primero.
  void addItem({
    required Dish dish,
    required String restaurantId,
    String? restaurantName,
    int quantity = 1,
    String? notes,
  }) {
    // Si cambia de restaurante, vaciar carrito
    if (state.restaurantId != null && state.restaurantId != restaurantId) {
      state = CartState(
        restaurantId: restaurantId,
        restaurantName: restaurantName,
      );
    }

    final itemId = '${dish.id}_${notes?.hashCode ?? 0}';
    final existing = state.items.indexWhere((i) => i.id == itemId);

    if (existing >= 0) {
      // Incrementar cantidad
      final updated = List<CartItem>.from(state.items);
      updated[existing] = updated[existing].copyWith(
        quantity: updated[existing].quantity + quantity,
      );
      state = state.copyWith(
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        items: updated,
      );
    } else {
      state = state.copyWith(
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        items: [
          ...state.items,
          CartItem(
            id: itemId,
            dishId: dish.id,
            restaurantId: restaurantId,
            name: dish.name,
            unitPrice: dish.price,
            imageUrl: dish.imageUrl,
            quantity: quantity,
            notes: notes,
          ),
        ],
      );
    }
  }

  /// Actualiza la cantidad de un item.
  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }
    final updated = state.items
        .map((i) => i.id == itemId ? i.copyWith(quantity: quantity) : i)
        .toList();
    state = state.copyWith(items: updated);
  }

  /// Elimina un item.
  void removeItem(String itemId) {
    final updated = state.items.where((i) => i.id != itemId).toList();
    if (updated.isEmpty) {
      state = const CartState();
    } else {
      state = state.copyWith(items: updated);
    }
  }

  /// Vacía el carrito completo.
  void clear() {
    state = const CartState();
  }
}
