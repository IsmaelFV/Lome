import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/table_repository_impl.dart';
import '../../domain/entities/table_occupancy_stat.dart';

/// Período para filtrar estadísticas.
enum StatsPeriod {
  week7('Última semana', 7),
  month30('Último mes', 30),
  quarter90('Último trimestre', 90);

  final String label;
  final int days;

  const StatsPeriod(this.label, this.days);
}

final statsPeriodProvider = StateProvider<StatsPeriod>(
  (ref) => StatsPeriod.month30,
);

// =============================================================================
// Provider: estadísticas de ocupación de todas las mesas
// =============================================================================

final tableOccupancyStatsProvider =
    FutureProvider.autoDispose<List<TableOccupancyStat>>((ref) async {
      final repo = ref.read(tableRepositoryProvider);
      final tenantId = ref.read(activeTenantIdProvider);
      final period = ref.watch(statsPeriodProvider);

      if (tenantId == null) return [];

      final from = DateTime.now().subtract(Duration(days: period.days));

      final rows = await repo.getTableOccupancyStats(
        tenantId,
        from.toUtc().toIso8601String(),
        DateTime.now().toUtc().toIso8601String(),
      );

      return rows.map((r) => TableOccupancyStat.fromJson(r)).toList();
    });
