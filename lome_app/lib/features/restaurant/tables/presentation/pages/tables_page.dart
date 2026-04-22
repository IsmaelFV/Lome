import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/auth/app_permission.dart';
import '../../../../../core/auth/permission_guard.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../core/widgets/lome_empty_state.dart';
import '../../../../../core/widgets/lome_loading.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../../notifications/presentation/widgets/order_ready_banner.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../reservations/domain/entities/reservation_entity.dart';
import '../../../reservations/presentation/providers/reservations_provider.dart';
import '../../../reservations/presentation/widgets/reservation_form_sheet.dart';
import '../../domain/entities/table_entity.dart';
import '../providers/table_assignments_provider.dart';
import '../providers/tables_provider.dart';
import '../widgets/table_map_canvas.dart';
import '../widgets/waiter_assignment_sheet.dart';

/// Página del mapa visual de mesas.
///
/// Muestra un canvas interactivo con las mesas posicionadas según
/// sus coordenadas. Permite filtrar por zona y seleccionar mesas
/// para gestionar pedidos o cambiar estado.
class TablesPage extends ConsumerWidget {
  const TablesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(filteredTablesProvider);
    final allTables = ref.watch(tablesProvider).valueOrNull ?? [];
    final zones = allTables
        .map((t) => t.zone)
        .whereType<String>()
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(
        title: context.l10n.tablesTitle,
        showBack: false,
        useGradient: true,
        actions: [
          TactileWrapper(
            onTap: () => context.push(RoutePaths.tableStats),
            child: Tooltip(
              message: context.l10n.tablesStatistics,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  PhosphorIcons.chartBar(PhosphorIconsStyle.duotone),
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          PermissionGuard(
            permission: AppPermission.manageTables,
            child: TactileWrapper(
              onTap: () => context.push(RoutePaths.tableEditor),
              child: Tooltip(
                message: context.l10n.tableEditorTitle,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    PhosphorIcons.pencilSimple(PhosphorIconsStyle.duotone),
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
          TactileWrapper(
            onTap: () => context.push(RoutePaths.restaurantDashboard),
            child: Tooltip(
              message: context.l10n.restaurantDashboardTitle,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  PhosphorIcons.squaresFour(PhosphorIconsStyle.duotone),
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          TactileWrapper(
            onTap: () => context.pushNamed(RouteNames.settings),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                PhosphorIcons.gear(PhosphorIconsStyle.duotone),
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Banner de pedido listo (auto-visible) ──
          const OrderReadyBanner(),

          // ── Resumen rápido de mesas ──
          _SummaryStatsStrip(tables: allTables),

          // ── Leyenda de estados ──
          const _StatusLegend(),

          // ── Filtro de zonas ──
          if (zones.isNotEmpty) _ZoneFilterBar(zones: zones),

          // ── Mapa interactivo ──
          Expanded(
            child: tablesAsync.when(
              loading: () => const LomeLoading(),
              error: (e, _) => LomeErrorWidget(
                message: e.toString(),
                onRetry: () => ref.read(tablesProvider.notifier).refresh(),
              ),
              data: (tables) {
                if (tables.isEmpty) {
                  return LomeEmptyState(
                    icon: PhosphorIcons.table(PhosphorIconsStyle.duotone),
                    title: context.l10n.tablesEmpty,
                    subtitle: context.l10n.tablesEmptySubtitle,
                    actionLabel: context.l10n.tablesOpenEditor,
                  );
                }
                return TableMapCanvas(
                  tables: tables,
                  isEditing: false,
                  onTableTap: (table) => _showTableActions(context, ref, table),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showTableActions(
    BuildContext context,
    WidgetRef ref,
    TableEntity table,
  ) {
    ref.read(selectedTableProvider.notifier).state = table.id;

    // Para mesas ocupadas / esperando: navegar directamente al pedido
    if (table.status == TableStatus.occupied ||
        table.status == TableStatus.waitingFood ||
        table.status == TableStatus.waitingPayment) {
      // Animación de selección antes de navegar
      Future.delayed(const Duration(milliseconds: 300), () {
        context.push('${RoutePaths.tableOrder}?tableId=${table.id}');
        ref.read(selectedTableProvider.notifier).state = null;
      });
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (ctx) => _TableActionSheet(table: table, parentContext: context),
    ).whenComplete(() {
      ref.read(selectedTableProvider.notifier).state = null;
    });
  }
}

// =============================================================================
// Leyenda de estados
// =============================================================================

class _StatusLegend extends StatelessWidget {
  const _StatusLegend();

  @override
  Widget build(BuildContext context) {
    final items = [
      (AppColors.tableAvailable, context.l10n.tablesStatusFree),
      (AppColors.tableOccupied, context.l10n.tableStatus_occupied),
      (AppColors.tableReserved, context.l10n.tableStatus_reserved),
      (AppColors.tableWaitingFood, context.l10n.tablesStatusWaitingFood),
      (AppColors.tableWaitingPayment, context.l10n.tablesStatusWaitingPayment),
      (AppColors.tableMaintenance, context.l10n.tablesStatusMaintenance),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingXs,
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++)
            _LegendDot(color: items[i].$1, label: items[i].$2)
                .animate()
                .fadeIn(delay: Duration(milliseconds: i * 60))
                .slideX(begin: 0.05),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacingMd),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.grey600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Filtro de zonas
// =============================================================================

class _ZoneFilterBar extends ConsumerWidget {
  final List<String> zones;

  const _ZoneFilterBar({required this.zones});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedZone = ref.watch(tableZoneFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          FilterChip(
                label: Text(context.l10n.tablesFilterAll),
                selected: selectedZone == null,
                selectedColor: AppColors.primary.withValues(alpha: 0.12),
                onSelected: (_) =>
                    ref.read(tableZoneFilterProvider.notifier).state = null,
              )
              .animate()
              .fadeIn(delay: const Duration(milliseconds: 0))
              .slideX(begin: -0.03),
          const SizedBox(width: 8),
          ...zones.asMap().entries.map(
            (entry) =>
                Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(entry.value),
                        selected: selectedZone == entry.value,
                        selectedColor: AppColors.primary.withValues(
                          alpha: 0.12,
                        ),
                        checkmarkColor: AppColors.primary,
                        onSelected: (_) =>
                            ref
                                .read(tableZoneFilterProvider.notifier)
                                .state = selectedZone == entry.value
                            ? null
                            : entry.value,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: (entry.key + 1) * 50))
                    .slideX(begin: -0.03),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Bottom sheet de acciones por mesa
// =============================================================================

class _TableActionSheet extends ConsumerWidget {
  final TableEntity table;
  final BuildContext parentContext;

  const _TableActionSheet({required this.table, required this.parentContext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = tableStatusColor(table.status);
    final reservation = ref
        .watch(reservationsProvider.notifier)
        .getActiveReservationForTable(table.id);
    final assignment = ref.watch(assignmentForTableProvider(table.id));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Center(
                    child: Text(
                      '${table.number}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        table.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey900,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            table.status.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Icon(
                            PhosphorIcons.users(PhosphorIconsStyle.duotone),
                            size: 14,
                            color: AppColors.grey400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${table.guestsCount ?? 0}/${table.capacity}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                      if (assignment != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIcons.user(PhosphorIconsStyle.duotone),
                                size: 13,
                                color: AppColors.grey400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                assignment.waiterName ??
                                    context.l10n.tablesAssignedWaiter,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // ── Acciones según estado ──
            ..._buildActions(context, ref, reservation),

            const SizedBox(height: AppTheme.spacingSm),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    WidgetRef ref,
    ReservationEntity? reservation,
  ) {
    final stateActions = switch (table.status) {
      TableStatus.available => _availableActions(context, ref, reservation),
      TableStatus.reserved => _reservedActions(context, ref, reservation),
      TableStatus.maintenance => _maintenanceActions(context, ref),
      _ => <Widget>[],
    };

    return [
      ...stateActions,
      const SizedBox(height: AppTheme.spacingMd),
      const Divider(height: 1),
      const SizedBox(height: AppTheme.spacingSm),
      // Acciones comunes
      Row(
        children: [
          // Asignar camarero
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showWaiterAssignment(parentContext);
              },
              icon: Icon(
                PhosphorIcons.userPlus(PhosphorIconsStyle.duotone),
                size: 18,
              ),
              label: Text(context.l10n.tablesWaiter),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          // Historial
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                parentContext.push(
                  '${RoutePaths.tableHistory}?tableId=${table.id}',
                );
              },
              icon: Icon(
                PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.duotone),
                size: 18,
              ),
              label: Text(context.l10n.tablesHistory),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  // ── Mesa libre ──

  List<Widget> _availableActions(
    BuildContext context,
    WidgetRef ref,
    ReservationEntity? reservation,
  ) {
    return [
      // Abrir mesa
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _openTable(context, ref),
          icon: Icon(PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone)),
          label: Text(context.l10n.tablesOpenTable),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      const SizedBox(height: AppTheme.spacingSm),
      // Reservar
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showReservationForm(context),
          icon: Icon(PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.duotone)),
          label: Text(context.l10n.tablesReserveTable),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      // Mostrar reserva futura si existe
      if (reservation != null) ...[
        const SizedBox(height: AppTheme.spacingMd),
        _ReservationInfoBanner(reservation: reservation),
      ],
    ];
  }

  // ── Mesa reservada ──

  List<Widget> _reservedActions(
    BuildContext context,
    WidgetRef ref,
    ReservationEntity? reservation,
  ) {
    return [
      if (reservation != null) ...[
        _ReservationInfoBanner(reservation: reservation),
        const SizedBox(height: AppTheme.spacingMd),
      ],
      // Cliente llegó
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _openTableFromReservation(context, ref, reservation),
          icon: Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.duotone)),
          label: Text(context.l10n.tablesClientArrived),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      const SizedBox(height: AppTheme.spacingSm),
      // Cancelar reserva
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            if (reservation != null) {
              ref
                  .read(reservationsProvider.notifier)
                  .cancelReservation(reservation.id);
            }
            Navigator.pop(context);
          },
          icon: Icon(
            PhosphorIcons.xCircle(PhosphorIconsStyle.duotone),
            color: AppColors.error,
          ),
          label: Text(
            context.l10n.tablesCancelReservation,
            style: TextStyle(color: AppColors.error),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
          ),
        ),
      ),
    ];
  }

  // ── Mesa en mantenimiento ──

  List<Widget> _maintenanceActions(BuildContext context, WidgetRef ref) {
    return [
      Text(
        context.l10n.tablesChangeStatus,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.grey500,
        ),
      ),
      const SizedBox(height: AppTheme.spacingSm),
      Wrap(
        spacing: AppTheme.spacingSm,
        runSpacing: AppTheme.spacingSm,
        children: [TableStatus.available, TableStatus.maintenance].map((s) {
          final active = s == table.status;
          final c = tableStatusColor(s);
          return ChoiceChip(
            label: Text(s.label),
            selected: active,
            selectedColor: c.withValues(alpha: 0.15),
            labelStyle: TextStyle(
              color: active ? c : AppColors.grey600,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              fontSize: 12,
            ),
            onSelected: active
                ? null
                : (_) {
                    ref
                        .read(tablesProvider.notifier)
                        .updateTableStatus(table.id, s);
                    Navigator.pop(context);
                  },
          );
        }).toList(),
      ),
    ];
  }

  // ── Acciones ──

  Future<void> _openTable(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context);

    final guestCount = await _showGuestCountDialog(parentContext);
    if (guestCount == null) return;

    try {
      await ref
          .read(ordersProvider.notifier)
          .openTable(tableId: table.id, guestCount: guestCount);

      if (parentContext.mounted) {
        parentContext.push('${RoutePaths.tableOrder}?tableId=${table.id}');
      }
    } catch (e) {
      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(
            content: Text(
              parentContext.l10n.tablesErrorOpenTable(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _openTableFromReservation(
    BuildContext context,
    WidgetRef ref,
    ReservationEntity? reservation,
  ) async {
    Navigator.pop(context);

    try {
      if (reservation != null) {
        await ref
            .read(ordersProvider.notifier)
            .openTableFromReservation(
              tableId: table.id,
              reservationId: reservation.id,
              guestCount: reservation.guests,
            );
      } else {
        await ref
            .read(ordersProvider.notifier)
            .openTable(tableId: table.id, guestCount: 1);
      }

      if (parentContext.mounted) {
        parentContext.push('${RoutePaths.tableOrder}?tableId=${table.id}');
      }
    } catch (e) {
      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(
            content: Text(
              parentContext.l10n.tablesErrorOpenTable(e.toString()),
            ),
          ),
        );
      }
    }
  }

  void _showReservationForm(BuildContext context) {
    Navigator.pop(context);

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(parentContext).viewInsets.bottom,
        ),
        child: ReservationFormSheet(table: table),
      ),
    );
  }

  void _showWaiterAssignment(BuildContext context) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (_) => WaiterAssignmentSheet(table: table),
    );
  }

  Future<int?> _showGuestCountDialog(BuildContext context) async {
    int count = 1;
    return showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(context.l10n.tablesGuestCountTitle),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TactileWrapper(
                onTap: count > 1 ? () => setDialogState(() => count--) : null,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                  child: Icon(
                    PhosphorIcons.minusCircle(PhosphorIconsStyle.duotone),
                    color: count > 1 ? AppColors.grey700 : AppColors.grey300,
                  ),
                ),
              ),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey900,
                ),
              ),
              TactileWrapper(
                onTap: count < table.capacity
                    ? () => setDialogState(() => count++)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                  child: Icon(
                    PhosphorIcons.plusCircle(PhosphorIconsStyle.duotone),
                    color: count < table.capacity
                        ? AppColors.grey700
                        : AppColors.grey300,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, count),
              child: Text(context.l10n.tablesOpenTable),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Banner de información de reserva
// =============================================================================

class _ReservationInfoBanner extends StatelessWidget {
  final ReservationEntity reservation;

  const _ReservationInfoBanner({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final time = reservation.reservationTime;
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.tableReserved.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppColors.tableReserved.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.duotone),
            color: AppColors.tableReserved,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.customerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
                  ),
                ),
                Text(
                  '$timeStr · ${context.l10n.tablesCapacity(reservation.guests)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
          if (reservation.phone != null)
            Icon(
              PhosphorIcons.phone(PhosphorIconsStyle.duotone),
              size: 16,
              color: AppColors.grey400,
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Helper global de color por estado
// =============================================================================

Color tableStatusColor(TableStatus status) => switch (status) {
  TableStatus.available => AppColors.tableAvailable,
  TableStatus.occupied => AppColors.tableOccupied,
  TableStatus.reserved => AppColors.tableReserved,
  TableStatus.waitingFood => AppColors.tableWaitingFood,
  TableStatus.waitingPayment => AppColors.tableWaitingPayment,
  TableStatus.maintenance => AppColors.tableMaintenance,
};

// =============================================================================
// Resumen rápido de mesas
// =============================================================================

class _SummaryStatsStrip extends StatelessWidget {
  final List<TableEntity> tables;

  const _SummaryStatsStrip({required this.tables});

  @override
  Widget build(BuildContext context) {
    if (tables.isEmpty) return const SizedBox.shrink();

    final free = tables.where((t) => t.status == TableStatus.available).length;
    final occupied = tables
        .where(
          (t) =>
              t.status == TableStatus.occupied ||
              t.status == TableStatus.waitingFood ||
              t.status == TableStatus.waitingPayment,
        )
        .length;
    final reserved = tables
        .where((t) => t.status == TableStatus.reserved)
        .length;
    final maintenance = tables
        .where((t) => t.status == TableStatus.maintenance)
        .length;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            count: free,
            label: context.l10n.tablesStatusFree,
            color: AppColors.tableAvailable,
          ),
          _StatItem(
            count: occupied,
            label: context.l10n.tableStatus_occupied,
            color: AppColors.tableOccupied,
          ),
          _StatItem(
            count: reserved,
            label: context.l10n.tableStatus_reserved,
            color: AppColors.tableReserved,
          ),
          if (maintenance > 0)
            _StatItem(
              count: maintenance,
              label: context.l10n.tablesStatusMaintenance,
              color: AppColors.tableMaintenance,
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05);
  }
}

class _StatItem extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatItem({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.grey500),
        ),
      ],
    );
  }
}
