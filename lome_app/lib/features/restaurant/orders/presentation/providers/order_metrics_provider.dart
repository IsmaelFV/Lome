import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/order_repository_impl.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class OrderMetrics {
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double totalRevenue;
  final double avgTicket;
  final double avgPrepTimeMinutes;

  const OrderMetrics({
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.cancelledOrders = 0,
    this.totalRevenue = 0,
    this.avgTicket = 0,
    this.avgPrepTimeMinutes = 0,
  });
}

class TopDish {
  final String name;
  final int totalQuantity;
  final double totalRevenue;

  const TopDish({
    required this.name,
    required this.totalQuantity,
    required this.totalRevenue,
  });
}

class HourlyData {
  final int hour;
  final int orderCount;
  final double revenue;

  const HourlyData({
    required this.hour,
    required this.orderCount,
    required this.revenue,
  });
}

// ---------------------------------------------------------------------------
// Period filter
// ---------------------------------------------------------------------------

enum MetricsPeriod { today, week, month, custom }

class MetricsFilter {
  final MetricsPeriod period;
  final DateTime? customStart;
  final DateTime? customEnd;

  const MetricsFilter({
    this.period = MetricsPeriod.today,
    this.customStart,
    this.customEnd,
  });

  MetricsFilter copyWith({
    MetricsPeriod? period,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    return MetricsFilter(
      period: period ?? this.period,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
    );
  }

  DateTime get startDate {
    final now = DateTime.now();
    return switch (period) {
      MetricsPeriod.today => DateTime(now.year, now.month, now.day),
      MetricsPeriod.week => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 7)),
      MetricsPeriod.month => DateTime(now.year, now.month - 1, now.day),
      MetricsPeriod.custom =>
        customStart ?? DateTime(now.year, now.month, now.day),
    };
  }

  DateTime get endDate {
    final now = DateTime.now();
    return switch (period) {
      MetricsPeriod.custom => customEnd ?? now,
      _ => now,
    };
  }
}

final metricsFilterProvider = StateProvider<MetricsFilter>(
  (_) => const MetricsFilter(),
);

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final orderMetricsProvider = FutureProvider<OrderMetrics>((ref) async {
  final repo = ref.read(orderRepositoryProvider);
  final tenantId = ref.watch(activeTenantIdProvider);
  final filter = ref.watch(metricsFilterProvider);
  if (tenantId == null) return const OrderMetrics();

  final data = await repo.getOrderMetrics(
    tenantId,
    filter.startDate.toIso8601String(),
    filter.endDate.toIso8601String(),
  );
  return OrderMetrics(
    totalOrders: (data['total_orders'] as num?)?.toInt() ?? 0,
    completedOrders: (data['completed_orders'] as num?)?.toInt() ?? 0,
    cancelledOrders: (data['cancelled_orders'] as num?)?.toInt() ?? 0,
    totalRevenue: (data['total_revenue'] as num?)?.toDouble() ?? 0,
    avgTicket: (data['avg_ticket'] as num?)?.toDouble() ?? 0,
    avgPrepTimeMinutes:
        (data['avg_prep_time_minutes'] as num?)?.toDouble() ?? 0,
  );
});

final topDishesProvider = FutureProvider<List<TopDish>>((ref) async {
  final repo = ref.read(orderRepositoryProvider);
  final tenantId = ref.watch(activeTenantIdProvider);
  final filter = ref.watch(metricsFilterProvider);
  if (tenantId == null) return [];

  final response = await repo.getTopDishes(
    tenantId,
    filter.startDate.toIso8601String(),
    filter.endDate.toIso8601String(),
  );

  return (response as List).map((row) {
    final d = row as Map<String, dynamic>;
    return TopDish(
      name: d['name'] as String? ?? '',
      totalQuantity: (d['total_quantity'] as num?)?.toInt() ?? 0,
      totalRevenue: (d['total_revenue'] as num?)?.toDouble() ?? 0,
    );
  }).toList();
});

final ordersByHourProvider = FutureProvider<List<HourlyData>>((ref) async {
  final repo = ref.read(orderRepositoryProvider);
  final tenantId = ref.watch(activeTenantIdProvider);
  final filter = ref.watch(metricsFilterProvider);
  if (tenantId == null) return [];

  final response = await repo.getOrdersByHour(
    tenantId,
    filter.startDate.toIso8601String(),
    filter.endDate.toIso8601String(),
  );

  return (response as List).map((row) {
    final d = row as Map<String, dynamic>;
    return HourlyData(
      hour: (d['hour'] as num?)?.toInt() ?? 0,
      orderCount: (d['order_count'] as num?)?.toInt() ?? 0,
      revenue: (d['revenue'] as num?)?.toDouble() ?? 0,
    );
  }).toList();
});
