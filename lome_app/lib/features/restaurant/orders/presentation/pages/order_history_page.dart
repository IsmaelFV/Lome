import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../core/widgets/lome_empty_state.dart';
import '../../../../../core/widgets/lome_loading.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../domain/entities/order_entity.dart';
import '../providers/order_history_provider.dart';
import 'ticket_preview_page.dart';

/// Página de historial de pedidos del restaurante.
///
/// Permite consultar pedidos completados y cancelados con filtros
/// por fecha, camarero y estado.
class OrderHistoryPage extends ConsumerStatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  ConsumerState<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends ConsumerState<OrderHistoryPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(orderHistoryProvider);
    final filter = ref.watch(orderHistoryFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(
        title: context.l10n.orderHistoryTitle,
        actions: [
          if (filter.hasFilters)
            TactileWrapper(
              onTap: () => ref.read(orderHistoryFilterProvider.notifier).state =
                  const OrderHistoryFilter(),
              child: Tooltip(
                message: context.l10n.orderHistoryClearFilters,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    PhosphorIcons.funnelX(PhosphorIconsStyle.duotone),
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de búsqueda + filtros ──
          _FilterBar(searchCtrl: _searchCtrl),

          // ── Chips de filtro activo ──
          if (filter.hasFilters) _ActiveFiltersRow(filter: filter),

          // ── Lista de pedidos ──
          Expanded(
            child: historyAsync.when(
              loading: () => const LomeLoading(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (orders) {
                if (orders.isEmpty) {
                  return LomeEmptyState(
                    icon: PhosphorIcons.clockCounterClockwise(
                      PhosphorIconsStyle.duotone,
                    ),
                    title: context.l10n.orderHistoryEmptyTitle,
                    subtitle: context.l10n.orderHistoryEmptySubtitle,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(orderHistoryProvider),
                  color: AppColors.primary,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    itemCount: orders.length,
                    itemBuilder: (ctx, i) => _HistoryOrderCard(order: orders[i])
                        .animate()
                        .fadeIn(duration: 200.ms, delay: (30 * i).ms)
                        .slideY(
                          begin: 0.05,
                          end: 0,
                          duration: 200.ms,
                          delay: (30 * i).ms,
                        ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Barra de filtros
// =============================================================================

class _FilterBar extends ConsumerWidget {
  final TextEditingController searchCtrl;

  const _FilterBar({required this.searchCtrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      color: AppColors.backgroundLight,
      child: Column(
        children: [
          // Búsqueda
          TextField(
            controller: searchCtrl,
            onChanged: (v) => ref
                .read(orderHistoryFilterProvider.notifier)
                .update(
                  (f) => f.copyWith(searchQuery: v, clearSearch: v.isEmpty),
                ),
            decoration: InputDecoration(
              hintText: context.l10n.orderHistorySearchHint,
              prefixIcon: Icon(
                PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.duotone),
                size: 20,
              ),
              suffixIcon: searchCtrl.text.isNotEmpty
                  ? TactileWrapper(
                      onTap: () {
                        searchCtrl.clear();
                        ref
                            .read(orderHistoryFilterProvider.notifier)
                            .update((f) => f.copyWith(clearSearch: true));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          PhosphorIcons.x(PhosphorIconsStyle.bold),
                          size: 18,
                        ),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.grey100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),

          // Botones de filtro
          Row(
            children: [
              _FilterButton(
                icon: PhosphorIcons.calendar(PhosphorIconsStyle.duotone),
                label: context.l10n.orderHistoryFilterDate,
                onTap: () => _pickDateRange(context, ref),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              _FilterButton(
                icon: PhosphorIcons.user(PhosphorIconsStyle.duotone),
                label: context.l10n.orderHistoryFilterWaiter,
                onTap: () => _pickWaiter(context, ref),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              _FilterButton(
                icon: PhosphorIcons.flag(PhosphorIconsStyle.duotone),
                label: context.l10n.orderHistoryFilterStatus,
                onTap: () => _pickStatus(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      locale: const Locale('es'),
    );
    if (range != null) {
      ref
          .read(orderHistoryFilterProvider.notifier)
          .update(
            (f) => f.copyWith(startDate: range.start, endDate: range.end),
          );
    }
  }

  Future<void> _pickWaiter(BuildContext context, WidgetRef ref) async {
    final waiters = ref.read(waiterListProvider).valueOrNull ?? [];
    if (waiters.isEmpty) return;

    final selected = await showModalBottomSheet<Map<String, String>>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Text(
                context.l10n.orderHistorySelectWaiter,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            ...waiters.map(
              (w) => ListTile(
                leading: Icon(PhosphorIcons.user(PhosphorIconsStyle.duotone)),
                title: Text(w['name']!),
                onTap: () => Navigator.pop(ctx, w),
              ),
            ),
            ListTile(
              leading: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold)),
              title: Text(context.l10n.all),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      ref
          .read(orderHistoryFilterProvider.notifier)
          .update(
            (f) => f.copyWith(
              waiterId: selected['id'],
              waiterName: selected['name'],
            ),
          );
    } else {
      ref
          .read(orderHistoryFilterProvider.notifier)
          .update((f) => f.copyWith(clearWaiter: true));
    }
  }

  Future<void> _pickStatus(BuildContext context, WidgetRef ref) async {
    final statuses = [
      OrderStatus.completed,
      OrderStatus.cancelled,
      OrderStatus.delivered,
    ];

    final selected = await showModalBottomSheet<OrderStatus?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Text(
                context.l10n.orderHistoryFilterByStatus,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            ListTile(
              leading: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold)),
              title: Text(context.l10n.all),
              onTap: () => Navigator.pop(ctx),
            ),
            ...statuses.map(
              (s) => ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _statusColor(s),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(s.label),
                onTap: () => Navigator.pop(ctx, s),
              ),
            ),
          ],
        ),
      ),
    );

    ref
        .read(orderHistoryFilterProvider.notifier)
        .update(
          (f) => selected != null
              ? f.copyWith(status: selected)
              : f.copyWith(clearStatus: true),
        );
  }
}

class _FilterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FilterButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TactileWrapper(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.grey200),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.grey500),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Chips de filtros activos
// =============================================================================

class _ActiveFiltersRow extends ConsumerWidget {
  final OrderHistoryFilter filter;

  const _ActiveFiltersRow({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd/MM', 'es');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      child: Row(
        children: [
          if (filter.startDate != null || filter.endDate != null)
            _FilterChip(
              label: filter.startDate != null && filter.endDate != null
                  ? '${fmt.format(filter.startDate!)} - ${fmt.format(filter.endDate!)}'
                  : filter.startDate != null
                  ? context.l10n.orderHistoryFilterFrom(
                      fmt.format(filter.startDate!),
                    )
                  : context.l10n.orderHistoryFilterTo(
                      fmt.format(filter.endDate!),
                    ),
              onRemove: () => ref
                  .read(orderHistoryFilterProvider.notifier)
                  .update(
                    (f) => f.copyWith(clearStartDate: true, clearEndDate: true),
                  ),
            ),
          if (filter.waiterName != null)
            _FilterChip(
              label: filter.waiterName!,
              onRemove: () => ref
                  .read(orderHistoryFilterProvider.notifier)
                  .update((f) => f.copyWith(clearWaiter: true)),
            ),
          if (filter.status != null)
            _FilterChip(
              label: filter.status!.label,
              onRemove: () => ref
                  .read(orderHistoryFilterProvider.notifier)
                  .update((f) => f.copyWith(clearStatus: true)),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacingSm),
      child: TactileWrapper(
        onTap: onRemove,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                PhosphorIcons.x(PhosphorIconsStyle.bold),
                size: 12,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Card de pedido en historial
// =============================================================================

class _HistoryOrderCard extends StatelessWidget {
  final OrderEntity order;

  const _HistoryOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);
    final fmt = DateFormat('dd/MM/yyyy HH:mm', 'es');

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppShadows.card,
      ),
      child: TactileWrapper(
        onTap: () => _showOrderDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '#${order.orderNumber}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      order.status.label,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '€${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.grey900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    PhosphorIcons.clock(PhosphorIconsStyle.duotone),
                    size: 14,
                    color: AppColors.grey400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    fmt.format(order.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey500,
                    ),
                  ),
                  if (order.waiterName != null) ...[
                    const SizedBox(width: AppTheme.spacingMd),
                    Icon(
                      PhosphorIcons.user(PhosphorIconsStyle.duotone),
                      size: 14,
                      color: AppColors.grey400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.waiterName!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                order.items.map((i) => '${i.quantity}x ${i.name}').join(', '),
                style: const TextStyle(fontSize: 12, color: AppColors.grey400),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (_) => _OrderDetailSheet(order: order),
    );
  }
}

// =============================================================================
// Detalle del pedido (bottom sheet)
// =============================================================================

class _OrderDetailSheet extends StatelessWidget {
  final OrderEntity order;

  const _OrderDetailSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);
    final fmt = DateFormat('dd/MM/yyyy HH:mm', 'es');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Text(
                  context.l10n.orderNumberLabel(order.orderNumber.toString()),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.grey900,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    order.status.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              fmt.format(order.createdAt),
              style: const TextStyle(fontSize: 12, color: AppColors.grey500),
            ),
            if (order.waiterName != null)
              Text(
                context.l10n.orderDetailWaiter(order.waiterName!),
                style: const TextStyle(fontSize: 12, color: AppColors.grey500),
              ),

            const Divider(height: AppTheme.spacingLg),

            // Items
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Center(
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (item.notes != null && item.notes!.isNotEmpty)
                            Text(
                              item.notes!,
                              style: TextStyle(
                                color: AppColors.grey500,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '€${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.total,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
                Text(
                  '€${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.grey900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Botón imprimir
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TicketPreviewPage(order: order),
                    ),
                  );
                },
                icon: Icon(
                  PhosphorIcons.printer(PhosphorIconsStyle.duotone),
                  size: 18,
                ),
                label: Text(context.l10n.orderDetailPrintTicket),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Helpers
// =============================================================================

Color _statusColor(OrderStatus status) => switch (status) {
  OrderStatus.completed => AppColors.statusCompleted,
  OrderStatus.cancelled => AppColors.statusCancelled,
  OrderStatus.delivered => AppColors.statusDelivered,
  OrderStatus.served => AppColors.statusServed,
  _ => AppColors.grey500,
};
