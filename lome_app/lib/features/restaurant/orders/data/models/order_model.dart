import '../../domain/entities/order_entity.dart';

/// Modelo de serialización para order_items (Supabase).
class OrderItemModel {
  final String id;
  final String orderId;
  final String? menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final Map<String, dynamic>? options;
  final String status;
  final String? notes;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.options,
    required this.status,
    this.notes,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      menuItemId: json['menu_item_id'] as String?,
      name: json['name'] as String,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      options: json['options'] as Map<String, dynamic>?,
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
    );
  }

  OrderItemEntity toEntity() {
    return OrderItemEntity(
      id: id,
      menuItemId: menuItemId,
      name: name,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
      options: options,
      status: OrderItemStatus.fromString(status),
      notes: notes,
    );
  }
}

/// Modelo de serialización para orders (Supabase).
class OrderModel {
  final String id;
  final String tenantId;
  final int orderNumber;
  final String? tableSessionId;
  final String? customerId;
  final String? waiterId;
  final String orderType;
  final String status;
  final String paymentStatus;
  final String? paymentMethod;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double total;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Join data
  final String? waiterName;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.tenantId,
    required this.orderNumber,
    this.tableSessionId,
    this.customerId,
    this.waiterId,
    required this.orderType,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    required this.subtotal,
    required this.taxAmount,
    this.discountAmount = 0,
    required this.total,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.waiterName,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Items del pedido (join)
    final itemsList = json['order_items'] as List<dynamic>? ?? [];
    final items = itemsList
        .map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
        .toList();

    // Nombre del camarero (join con alias 'waiter')
    final waiter = json['waiter'] as Map<String, dynamic>?;

    return OrderModel(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      orderNumber: json['order_number'] as int? ?? 0,
      tableSessionId: json['table_session_id'] as String?,
      customerId: json['customer_id'] as String?,
      waiterId: json['waiter_id'] as String?,
      orderType: json['order_type'] as String? ?? 'dine_in',
      status: json['status'] as String? ?? 'pending',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      paymentMethod: json['payment_method'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      waiterName: waiter?['full_name'] as String?,
      items: items,
    );
  }

  OrderEntity toEntity() {
    return OrderEntity(
      id: id,
      tenantId: tenantId,
      orderNumber: orderNumber,
      tableSessionId: tableSessionId,
      customerId: customerId,
      waiterId: waiterId,
      waiterName: waiterName,
      orderType: OrderType.fromString(orderType),
      status: OrderStatus.fromString(status),
      subtotal: subtotal,
      taxAmount: taxAmount,
      discountAmount: discountAmount,
      total: total,
      paymentStatus: PaymentStatus.fromString(paymentStatus),
      paymentMethod: paymentMethod,
      notes: notes,
      items: items.map((i) => i.toEntity()).toList(),
      createdAt: createdAt,
    );
  }
}
