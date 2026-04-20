import 'package:equatable/equatable.dart';

/// Estadísticas de ocupación de una mesa.
class TableOccupancyStat extends Equatable {
  final String tableId;
  final int tableNumber;
  final String? tableName;
  final int totalSessions;
  final int totalOrders;
  final double totalRevenue;
  final int avgDurationMinutes;
  final double avgGuests;
  final double avgTicket;

  const TableOccupancyStat({
    required this.tableId,
    required this.tableNumber,
    this.tableName,
    required this.totalSessions,
    required this.totalOrders,
    required this.totalRevenue,
    required this.avgDurationMinutes,
    required this.avgGuests,
    required this.avgTicket,
  });

  factory TableOccupancyStat.fromJson(Map<String, dynamic> json) {
    return TableOccupancyStat(
      tableId: json['table_id'] as String,
      tableNumber: json['table_number'] as int,
      tableName: json['table_name'] as String?,
      totalSessions: json['total_sessions'] as int? ?? 0,
      totalOrders: json['total_orders'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      avgDurationMinutes: json['avg_duration_minutes'] as int? ?? 0,
      avgGuests: (json['avg_guests'] as num?)?.toDouble() ?? 0,
      avgTicket: (json['avg_ticket'] as num?)?.toDouble() ?? 0,
    );
  }

  String get displayName => tableName ?? 'Mesa $tableNumber';

  String get avgDurationFormatted {
    final h = avgDurationMinutes ~/ 60;
    final m = avgDurationMinutes % 60;
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }

  @override
  List<Object?> get props => [tableId, tableNumber];
}
