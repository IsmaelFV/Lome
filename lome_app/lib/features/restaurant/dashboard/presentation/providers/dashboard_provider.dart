import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/providers/supabase_provider.dart';
import '../../../data/repositories/restaurant_support_repository_impl.dart';
import '../../../domain/repositories/restaurant_support_repository.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Dashboard state
// ---------------------------------------------------------------------------

class DashboardStats {
  final double salesToday;
  final int activeOrders;
  final int occupiedTables;
  final int totalTables;
  final int pendingOrders;
  final List<TopSellingItem> topSelling;
  final List<LowStockItem> lowStockItems;
  final List<RecentAlert> alerts;

  const DashboardStats({
    this.salesToday = 0,
    this.activeOrders = 0,
    this.occupiedTables = 0,
    this.totalTables = 0,
    this.pendingOrders = 0,
    this.topSelling = const [],
    this.lowStockItems = const [],
    this.alerts = const [],
  });

  double get occupancyRate =>
      totalTables > 0 ? (occupiedTables / totalTables) * 100 : 0;

  DashboardStats copyWith({
    double? salesToday,
    int? activeOrders,
    int? occupiedTables,
    int? totalTables,
    int? pendingOrders,
    List<TopSellingItem>? topSelling,
    List<LowStockItem>? lowStockItems,
    List<RecentAlert>? alerts,
  }) {
    return DashboardStats(
      salesToday: salesToday ?? this.salesToday,
      activeOrders: activeOrders ?? this.activeOrders,
      occupiedTables: occupiedTables ?? this.occupiedTables,
      totalTables: totalTables ?? this.totalTables,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      topSelling: topSelling ?? this.topSelling,
      lowStockItems: lowStockItems ?? this.lowStockItems,
      alerts: alerts ?? this.alerts,
    );
  }
}

class TopSellingItem {
  final String name;
  final int quantity;

  const TopSellingItem({required this.name, required this.quantity});
}

class LowStockItem {
  final String name;
  final double currentStock;
  final double minimumStock;
  final String unit;

  const LowStockItem({
    required this.name,
    required this.currentStock,
    required this.minimumStock,
    required this.unit,
  });

  double get stockPercentage =>
      minimumStock > 0 ? (currentStock / minimumStock) * 100 : 0;
}

class RecentAlert {
  final String title;
  final String message;
  final AlertType type;
  final DateTime createdAt;

  const RecentAlert({
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
  });
}

enum AlertType { warning, error, info }

// ---------------------------------------------------------------------------
// Dashboard state wrapper
// ---------------------------------------------------------------------------

class DashboardState {
  final DashboardStats stats;
  final bool isLoading;
  final String? errorMessage;

  const DashboardState({
    this.stats = const DashboardStats(),
    this.isLoading = false,
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardStats? stats,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard notifier
// ---------------------------------------------------------------------------

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
      return DashboardNotifier(ref);
    });

class DashboardNotifier extends StateNotifier<DashboardState> {
  final Ref _ref;
  final List<RealtimeChannel> _channels = [];

  DashboardNotifier(this._ref) : super(const DashboardState()) {
    _init();
  }

  SupabaseClient get _client => _ref.read(supabaseClientProvider);
  String? get _tenantId => _ref.read(activeTenantIdProvider);
  RestaurantSupportRepository get _repo =>
      _ref.read(restaurantSupportRepositoryProvider);

  Future<void> _init() async {
    await loadStats();
    _subscribeToRealtime();
  }

  /// Carga todas las estadísticas del dashboard.
  Future<void> loadStats() async {
    final tenantId = _tenantId;
    if (tenantId == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Ejecutar consultas en paralelo
      final results = await Future.wait([
        _fetchSalesToday(tenantId),
        _fetchActiveOrders(tenantId),
        _fetchTableStats(tenantId),
        _fetchPendingOrders(tenantId),
        _fetchTopSelling(tenantId),
        _fetchLowStock(tenantId),
      ]);

      final salesToday = results[0] as double;
      final activeOrders = results[1] as int;
      final tableStats = results[2] as Map<String, int>;
      final pendingOrders = results[3] as int;
      final topSelling = results[4] as List<TopSellingItem>;
      final lowStock = results[5] as List<LowStockItem>;

      // Generar alertas basadas en datos
      final alerts = _generateAlerts(
        lowStock: lowStock,
        pendingOrders: pendingOrders,
        occupancyRate: tableStats['total']! > 0
            ? (tableStats['occupied']! / tableStats['total']!) * 100
            : 0,
      );

      state = state.copyWith(
        isLoading: false,
        stats: DashboardStats(
          salesToday: salesToday,
          activeOrders: activeOrders,
          occupiedTables: tableStats['occupied'] ?? 0,
          totalTables: tableStats['total'] ?? 0,
          pendingOrders: pendingOrders,
          topSelling: topSelling,
          lowStockItems: lowStock,
          alerts: alerts,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar estadísticas: $e',
      );
    }
  }

  // ── Consultas individuales ──

  Future<double> _fetchSalesToday(String tenantId) async {
    return await _repo.fetchSalesToday(tenantId);
  }

  Future<int> _fetchActiveOrders(String tenantId) async {
    return await _repo.fetchActiveOrdersCount(tenantId);
  }

  Future<Map<String, int>> _fetchTableStats(String tenantId) async {
    return await _repo.fetchTableStats(tenantId);
  }

  Future<int> _fetchPendingOrders(String tenantId) async {
    return await _repo.fetchPendingOrdersCount(tenantId);
  }

  Future<List<TopSellingItem>> _fetchTopSelling(String tenantId) async {
    final response = await _repo.fetchTopSellingItems(tenantId);

    // Agrupar por nombre y sumar cantidades
    final Map<String, int> grouped = {};
    for (final row in response) {
      final name = row['name'] as String;
      final qty = (row['quantity'] as num?)?.toInt() ?? 1;
      grouped[name] = (grouped[name] ?? 0) + qty;
    }

    final sorted = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(5)
        .map((e) => TopSellingItem(name: e.key, quantity: e.value))
        .toList();
  }

  Future<List<LowStockItem>> _fetchLowStock(String tenantId) async {
    final response = await _repo.fetchLowStockItems(tenantId);

    return response
        .where(
          (row) =>
              (row['current_stock'] as num) <= (row['minimum_stock'] as num),
        )
        .take(5)
        .map(
          (row) => LowStockItem(
            name: row['name'] as String,
            currentStock: (row['current_stock'] as num).toDouble(),
            minimumStock: (row['minimum_stock'] as num).toDouble(),
            unit: row['unit'] as String? ?? 'unidad',
          ),
        )
        .toList();
  }

  // ── Alertas automáticas ──

  List<RecentAlert> _generateAlerts({
    required List<LowStockItem> lowStock,
    required int pendingOrders,
    required double occupancyRate,
  }) {
    final alerts = <RecentAlert>[];

    if (lowStock.isNotEmpty) {
      alerts.add(
        RecentAlert(
          title: 'Stock bajo',
          message:
              '${lowStock.length} ingrediente${lowStock.length > 1 ? 's' : ''} por debajo del mínimo',
          type: AlertType.warning,
          createdAt: DateTime.now(),
        ),
      );
    }

    if (pendingOrders > 3) {
      alerts.add(
        RecentAlert(
          title: 'Pedidos acumulados',
          message: '$pendingOrders pedidos esperando confirmación',
          type: AlertType.error,
          createdAt: DateTime.now(),
        ),
      );
    }

    if (occupancyRate > 85) {
      alerts.add(
        RecentAlert(
          title: 'Alta ocupación',
          message: '${occupancyRate.toStringAsFixed(0)}% de mesas ocupadas',
          type: AlertType.info,
          createdAt: DateTime.now(),
        ),
      );
    }

    return alerts;
  }

  // ── Realtime subscriptions ──

  void _subscribeToRealtime() {
    final tenantId = _tenantId;
    if (tenantId == null) return;

    // Suscribirse a cambios en orders
    final ordersChannel = _client
        .channel('dashboard-orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tenant_id',
            value: tenantId,
          ),
          callback: (_) => _refreshOrderStats(),
        )
        .subscribe();

    // Suscribirse a cambios en mesas
    final tablesChannel = _client
        .channel('dashboard-tables')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'restaurant_tables',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tenant_id',
            value: tenantId,
          ),
          callback: (_) => _refreshTableStats(),
        )
        .subscribe();

    _channels.addAll([ordersChannel, tablesChannel]);
  }

  /// Refresca solo las estadísticas de pedidos (tras evento realtime).
  Future<void> _refreshOrderStats() async {
    final tenantId = _tenantId;
    if (tenantId == null) return;

    try {
      final results = await Future.wait([
        _fetchSalesToday(tenantId),
        _fetchActiveOrders(tenantId),
        _fetchPendingOrders(tenantId),
        _fetchTopSelling(tenantId),
      ]);

      state = state.copyWith(
        stats: state.stats.copyWith(
          salesToday: results[0] as double,
          activeOrders: results[1] as int,
          pendingOrders: results[2] as int,
          topSelling: results[3] as List<TopSellingItem>,
        ),
      );
    } catch (_) {}
  }

  /// Refresca solo las estadísticas de mesas (tras evento realtime).
  Future<void> _refreshTableStats() async {
    final tenantId = _tenantId;
    if (tenantId == null) return;

    try {
      final tableStats = await _fetchTableStats(tenantId);
      state = state.copyWith(
        stats: state.stats.copyWith(
          occupiedTables: tableStats['occupied'] ?? 0,
          totalTables: tableStats['total'] ?? 0,
        ),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final channel in _channels) {
      _client.removeChannel(channel);
    }
    super.dispose();
  }
}
