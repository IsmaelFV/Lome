import 'package:equatable/equatable.dart';

/// Entidad de pedido del dominio.
class OrderEntity extends Equatable {
  final String id;
  final String tenantId;
  final int orderNumber;
  final String? tableSessionId;
  final String? customerId;
  final String? customerName;
  final String? waiterId;
  final String? waiterName;
  final OrderType orderType;
  final OrderStatus status;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double total;
  final PaymentStatus paymentStatus;
  final String? paymentMethod;
  final String? notes;
  final List<OrderItemEntity> items;
  final DateTime? estimatedReadyAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  const OrderEntity({
    required this.id,
    required this.tenantId,
    required this.orderNumber,
    this.tableSessionId,
    this.customerId,
    this.customerName,
    this.waiterId,
    this.waiterName,
    required this.orderType,
    required this.status,
    required this.subtotal,
    required this.taxAmount,
    this.discountAmount = 0,
    required this.total,
    required this.paymentStatus,
    this.paymentMethod,
    this.notes,
    this.items = const [],
    this.estimatedReadyAt,
    this.completedAt,
    required this.createdAt,
  });

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
  bool get isPaid => paymentStatus == PaymentStatus.paid;
  bool get canBeCancelled =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;

  /// El pedido se puede editar solo mientras no se haya enviado a cocina.
  bool get canEdit => status == OrderStatus.pending;

  @override
  List<Object?> get props => [id, orderNumber, status, paymentStatus];
}

class OrderItemEntity extends Equatable {
  final String id;
  final String? menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final Map<String, dynamic>? options;
  final OrderItemStatus status;
  final String? notes;

  const OrderItemEntity({
    required this.id,
    this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.options,
    required this.status,
    this.notes,
  });

  @override
  List<Object?> get props => [id, name, quantity, status];
}

enum OrderType {
  dineIn,
  takeaway,
  delivery,
  marketplace;

  String get label {
    switch (this) {
      case OrderType.dineIn:
        return 'En sala';
      case OrderType.takeaway:
        return 'Para llevar';
      case OrderType.delivery:
        return 'Delivery';
      case OrderType.marketplace:
        return 'Marketplace';
    }
  }

  static OrderType fromString(String value) {
    switch (value) {
      case 'dine_in':
        return OrderType.dineIn;
      case 'takeaway':
        return OrderType.takeaway;
      case 'delivery':
        return OrderType.delivery;
      case 'marketplace':
        return OrderType.marketplace;
      default:
        return OrderType.dineIn;
    }
  }
}

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  served,
  delivered,
  cancelled,
  completed;

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pendiente';
      case OrderStatus.confirmed:
        return 'Confirmado';
      case OrderStatus.preparing:
        return 'Preparando';
      case OrderStatus.ready:
        return 'Listo';
      case OrderStatus.served:
        return 'Servido';
      case OrderStatus.delivered:
        return 'Entregado';
      case OrderStatus.cancelled:
        return 'Cancelado';
      case OrderStatus.completed:
        return 'Completado';
    }
  }

  /// Valor que se almacena en la base de datos.
  String get dbValue => switch (this) {
    served => 'delivered',
    delivered => 'delivering',
    _ => name,
  };

  static OrderStatus fromString(String value) {
    return switch (value) {
      'pending' => OrderStatus.pending,
      'confirmed' => OrderStatus.confirmed,
      'preparing' => OrderStatus.preparing,
      'ready' => OrderStatus.ready,
      'delivering' => OrderStatus.delivered,
      'delivered' => OrderStatus.served,
      'completed' => OrderStatus.completed,
      'cancelled' => OrderStatus.cancelled,
      _ => OrderStatus.pending,
    };
  }
}

enum PaymentStatus {
  pending,
  paid,
  refunded,
  partial;

  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pendiente';
      case PaymentStatus.paid:
        return 'Pagado';
      case PaymentStatus.refunded:
        return 'Reembolsado';
      case PaymentStatus.partial:
        return 'Parcial';
    }
  }

  String get dbValue => name;

  static PaymentStatus fromString(String value) {
    return switch (value) {
      'pending' => PaymentStatus.pending,
      'paid' => PaymentStatus.paid,
      'refunded' => PaymentStatus.refunded,
      'partial' || 'failed' => PaymentStatus.partial,
      _ => PaymentStatus.pending,
    };
  }
}

enum OrderItemStatus {
  pending,
  preparing,
  ready,
  served,
  cancelled;

  String get label {
    switch (this) {
      case OrderItemStatus.pending:
        return 'Pendiente';
      case OrderItemStatus.preparing:
        return 'Preparando';
      case OrderItemStatus.ready:
        return 'Listo';
      case OrderItemStatus.served:
        return 'Servido';
      case OrderItemStatus.cancelled:
        return 'Cancelado';
    }
  }

  static OrderItemStatus fromString(String value) {
    return OrderItemStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderItemStatus.pending,
    );
  }
}
