/// Entidades del dominio de checkout y delivery.

// ---------------------------------------------------------------------------
// Dirección de entrega
// ---------------------------------------------------------------------------

class DeliveryAddress {
  final String id;
  final String userId;
  final String label; // 'Casa', 'Trabajo', 'Otro'
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String? state;
  final String postalCode;
  final String country;
  final double? latitude;
  final double? longitude;
  final String? instructions;
  final bool isDefault;

  const DeliveryAddress({
    required this.id,
    required this.userId,
    required this.label,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.state,
    required this.postalCode,
    this.country = 'ES',
    this.latitude,
    this.longitude,
    this.instructions,
    this.isDefault = false,
  });

  String get fullAddress {
    final parts = [addressLine1];
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      parts.add(addressLine2!);
    }
    parts.add('$postalCode $city');
    return parts.join(', ');
  }

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      label: json['label'] as String? ?? 'Casa',
      addressLine1: json['address_line1'] as String,
      addressLine2: json['address_line2'] as String?,
      city: json['city'] as String,
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String,
      country: json['country'] as String? ?? 'ES',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      instructions: json['instructions'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'label': label,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'instructions': instructions,
      'is_default': isDefault,
    };
  }
}

// ---------------------------------------------------------------------------
// Pedido delivery (vista marketplace)
// ---------------------------------------------------------------------------

enum DeliveryOrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  delivering,
  delivered,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case pending:
        return 'Pendiente';
      case confirmed:
        return 'Confirmado';
      case preparing:
        return 'En preparación';
      case ready:
        return 'Listo';
      case delivering:
        return 'En camino';
      case delivered:
        return 'Entregado';
      case completed:
        return 'Completado';
      case cancelled:
        return 'Cancelado';
    }
  }

  int get stepIndex {
    switch (this) {
      case pending:
      case confirmed:
        return 0;
      case preparing:
        return 1;
      case ready:
        return 2;
      case delivering:
        return 3;
      case delivered:
      case completed:
        return 4;
      case cancelled:
        return -1;
    }
  }

  static DeliveryOrderStatus fromString(String value) {
    return DeliveryOrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DeliveryOrderStatus.pending,
    );
  }
}

class DeliveryOrder {
  final String id;
  final String tenantId;
  final int? orderNumber;
  final String? customerId;
  final DeliveryOrderStatus status;
  final String paymentStatus;
  final String? paymentMethod;
  final double subtotal;
  final double taxAmount;
  final double deliveryFee;
  final double discountAmount;
  final double total;
  final String? deliveryAddressId;
  final String? deliveryNotes;
  final DateTime? estimatedDeliveryAt;
  final DateTime? deliveredAt;
  final String? notes;
  final String? cancellationReason;
  final List<DeliveryOrderItem> items;
  final DateTime createdAt;

  // Info desnormalizada para UI
  final String? restaurantName;
  final String? restaurantLogo;

  const DeliveryOrder({
    required this.id,
    required this.tenantId,
    this.orderNumber,
    this.customerId,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    required this.subtotal,
    required this.taxAmount,
    required this.deliveryFee,
    required this.discountAmount,
    required this.total,
    this.deliveryAddressId,
    this.deliveryNotes,
    this.estimatedDeliveryAt,
    this.deliveredAt,
    this.notes,
    this.cancellationReason,
    this.items = const [],
    required this.createdAt,
    this.restaurantName,
    this.restaurantLogo,
  });

  bool get isCancelled => status == DeliveryOrderStatus.cancelled;
  bool get canBeCancelled =>
      status == DeliveryOrderStatus.pending ||
      status == DeliveryOrderStatus.confirmed;
  bool get isDelivered =>
      status == DeliveryOrderStatus.delivered ||
      status == DeliveryOrderStatus.completed;

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    final tenant = json['tenants'] as Map<String, dynamic>?;
    final itemsList = json['order_items'] as List<dynamic>?;

    return DeliveryOrder(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      orderNumber: json['order_number'] as int?,
      customerId: json['customer_id'] as String?,
      status: DeliveryOrderStatus.fromString(json['status'] as String),
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      paymentMethod: json['payment_method'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      deliveryAddressId: json['delivery_address_id'] as String?,
      deliveryNotes: json['delivery_notes'] as String?,
      estimatedDeliveryAt: json['estimated_delivery_at'] != null
          ? DateTime.parse(json['estimated_delivery_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      notes: json['notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      items:
          itemsList
              ?.map(
                (i) => DeliveryOrderItem.fromJson(i as Map<String, dynamic>),
              )
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      restaurantName: tenant?['name'] as String?,
      restaurantLogo: tenant?['logo_url'] as String?,
    );
  }
}

class DeliveryOrderItem {
  final String id;
  final String? menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;

  const DeliveryOrderItem({
    required this.id,
    this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
  });

  factory DeliveryOrderItem.fromJson(Map<String, dynamic> json) {
    return DeliveryOrderItem(
      id: json['id'] as String,
      menuItemId: json['menu_item_id'] as String?,
      name: json['name'] as String,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// Pago
// ---------------------------------------------------------------------------

enum PaymentMethod {
  card,
  online,
  cash;

  String get label {
    switch (this) {
      case card:
        return 'Tarjeta bancaria';
      case online:
        return 'Pago online';
      case cash:
        return 'Efectivo';
    }
  }

  String get icon {
    switch (this) {
      case card:
        return 'credit_card';
      case online:
        return 'language';
      case cash:
        return 'payments';
    }
  }
}

class Payment {
  final String id;
  final String orderId;
  final double amount;
  final PaymentMethod method;
  final String status; // pending, paid, refunded, failed
  final String? transactionRef;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionRef,
    required this.createdAt,
  });

  bool get isPaid => status == 'paid';
  bool get isFailed => status == 'failed';

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      method: PaymentMethod.values.firstWhere(
        (m) => m.name == json['method'],
        orElse: () => PaymentMethod.cash,
      ),
      status: json['status'] as String? ?? 'pending',
      transactionRef: json['transaction_ref'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
