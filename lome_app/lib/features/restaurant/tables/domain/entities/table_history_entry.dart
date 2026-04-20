import 'package:equatable/equatable.dart';

/// Registro de historial de uso de una mesa.
class TableHistoryEntry extends Equatable {
  final String orderId;
  final int orderNumber;
  final String? waiterName;
  final int guestsCount;
  final double total;
  final String? paymentMethod;
  final DateTime openedAt;
  final DateTime? closedAt;
  final int durationMinutes;

  const TableHistoryEntry({
    required this.orderId,
    required this.orderNumber,
    this.waiterName,
    required this.guestsCount,
    required this.total,
    this.paymentMethod,
    required this.openedAt,
    this.closedAt,
    required this.durationMinutes,
  });

  factory TableHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TableHistoryEntry(
      orderId: json['order_id'] as String,
      orderNumber: json['order_number'] as int,
      waiterName: json['waiter_name'] as String?,
      guestsCount: json['guests_count'] as int? ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['payment_method'] as String?,
      openedAt: DateTime.parse(json['opened_at'] as String),
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String)
          : null,
      durationMinutes: json['duration_minutes'] as int? ?? 0,
    );
  }

  String get durationFormatted {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }

  @override
  List<Object?> get props => [orderId, orderNumber];
}
