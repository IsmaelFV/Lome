import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/admin_repository_impl.dart';
import '../../../domain/entities/admin_entities.dart';

// ---------------------------------------------------------------------------
// Platform Stats (RPC)
// ---------------------------------------------------------------------------

final adminPlatformStatsProvider =
    FutureProvider<AdminPlatformStats>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  final response = await repo.getPlatformMetrics();
  return AdminPlatformStats.fromJson(response);
});

// ---------------------------------------------------------------------------
// Recent Restaurants
// ---------------------------------------------------------------------------

final adminRecentRestaurantsProvider =
    FutureProvider<List<AdminRestaurant>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  final response = await repo.getRecentRestaurants();

  return response
      .map((r) => AdminRestaurant.fromJson(r))
      .toList();
});

// ---------------------------------------------------------------------------
// System Alerts (computed from stats)
// ---------------------------------------------------------------------------

class SystemAlert {
  final String title;
  final String subtitle;
  final String type; // warning, info, success, error

  const SystemAlert({
    required this.title,
    required this.subtitle,
    required this.type,
  });
}

final adminSystemAlertsProvider =
    Provider<List<SystemAlert>>((ref) {
  final stats = ref.watch(adminPlatformStatsProvider).valueOrNull;
  if (stats == null) return [];

  final alerts = <SystemAlert>[];

  if (stats.openIncidents > 0) {
    alerts.add(SystemAlert(
      title: '${stats.openIncidents} incidencias abiertas',
      subtitle: 'Requieren atención del equipo de soporte',
      type: stats.openIncidents > 5 ? 'error' : 'warning',
    ));
  }

  if (stats.flaggedReviews > 0) {
    alerts.add(SystemAlert(
      title: '${stats.flaggedReviews} reseñas pendientes de moderación',
      subtitle: 'Revisar contenido reportado por usuarios',
      type: 'info',
    ));
  }

  if (stats.pendingTenants > 0) {
    alerts.add(SystemAlert(
      title: '${stats.pendingTenants} restaurantes pendientes de aprobación',
      subtitle: 'Revisar solicitudes de registro nuevas',
      type: 'warning',
    ));
  }

  if (alerts.isEmpty) {
    alerts.add(const SystemAlert(
      title: 'Sistema operativo sin alertas',
      subtitle: 'Todos los servicios funcionando correctamente',
      type: 'success',
    ));
  }

  return alerts;
});
