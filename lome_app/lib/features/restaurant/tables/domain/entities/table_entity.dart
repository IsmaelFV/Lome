import 'package:equatable/equatable.dart';

/// Forma visual de la mesa en el mapa.
enum TableShape {
  round,
  square,
  rectangle;

  String get label => switch (this) {
    round => 'Redonda',
    square => 'Cuadrada',
    rectangle => 'Rectangular',
  };

  static TableShape fromString(String value) => TableShape.values.firstWhere(
    (e) => e.name == value,
    orElse: () => TableShape.square,
  );
}

/// Entidad de mesa del restaurante.
class TableEntity extends Equatable {
  final String id;
  final String tenantId;
  final int number;
  final String? name;
  final int capacity;
  final String? zone;
  final TableStatus status;
  final TableShape shape;
  final double? positionX;
  final double? positionY;
  final double width;
  final double height;
  final bool isActive;
  final String? activeSessionId;
  final int? guestsCount;
  final String? waiterName;

  const TableEntity({
    required this.id,
    required this.tenantId,
    required this.number,
    this.name,
    required this.capacity,
    this.zone,
    required this.status,
    this.shape = TableShape.square,
    this.positionX,
    this.positionY,
    this.width = 1.0,
    this.height = 1.0,
    this.isActive = true,
    this.activeSessionId,
    this.guestsCount,
    this.waiterName,
  });

  String get displayName => name ?? 'Mesa $number';
  bool get isAvailable => status == TableStatus.available;
  bool get isOccupied => status == TableStatus.occupied;
  bool get hasActiveSession => activeSessionId != null;

  TableEntity copyWith({
    String? id,
    String? tenantId,
    int? number,
    String? name,
    int? capacity,
    String? zone,
    TableStatus? status,
    TableShape? shape,
    double? positionX,
    double? positionY,
    double? width,
    double? height,
    bool? isActive,
    String? activeSessionId,
    int? guestsCount,
    String? waiterName,
  }) {
    return TableEntity(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      number: number ?? this.number,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      zone: zone ?? this.zone,
      status: status ?? this.status,
      shape: shape ?? this.shape,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      width: width ?? this.width,
      height: height ?? this.height,
      isActive: isActive ?? this.isActive,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      guestsCount: guestsCount ?? this.guestsCount,
      waiterName: waiterName ?? this.waiterName,
    );
  }

  @override
  List<Object?> get props => [
    id,
    number,
    status,
    shape,
    positionX,
    positionY,
    activeSessionId,
  ];
}

enum TableStatus {
  available,
  occupied,
  reserved,
  waitingFood,
  waitingPayment,
  maintenance;

  String get label => switch (this) {
    available => 'Libre',
    occupied => 'Ocupada',
    reserved => 'Reservada',
    waitingFood => 'Esperando comida',
    waitingPayment => 'Esperando pago',
    maintenance => 'Mantenimiento',
  };

  String get dbValue => switch (this) {
    available => 'available',
    occupied => 'occupied',
    reserved => 'reserved',
    waitingFood => 'waiting_food',
    waitingPayment => 'waiting_payment',
    maintenance => 'maintenance',
  };

  static TableStatus fromString(String value) {
    return switch (value) {
      'available' => TableStatus.available,
      'occupied' => TableStatus.occupied,
      'reserved' => TableStatus.reserved,
      'waiting_food' => TableStatus.waitingFood,
      'waiting_payment' => TableStatus.waitingPayment,
      'maintenance' => TableStatus.maintenance,
      _ => TableStatus.available,
    };
  }
}
