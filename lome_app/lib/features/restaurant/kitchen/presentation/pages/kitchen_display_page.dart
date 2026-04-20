import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../core/widgets/lome_empty_state.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/providers/orders_provider.dart';

/// Pantalla de cocina (Kitchen Display System).
///
/// Muestra los pedidos pendientes de preparar en formato de columnas
/// optimizado para tablets/pantallas grandes en la cocina.
/// Cada item muestra su estado individual y puede ser marcado
/// independientemente por el cocinero.
class KitchenDisplayPage extends ConsumerStatefulWidget {
  const KitchenDisplayPage({super.key});

  @override
  ConsumerState<KitchenDisplayPage> createState() => _KitchenDisplayPageState();
}

class _KitchenDisplayPageState extends ConsumerState<KitchenDisplayPage> {
  Set<String> _knownOrderIds = {};

  @override
  Widget build(BuildContext context) {
    final kitchenOrders = ref.watch(kitchenOrdersProvider);

    final currentIds = kitchenOrders.map((o) => o.id).toSet();
    final newIds = currentIds.difference(_knownOrderIds);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _knownOrderIds = currentIds;
    });

    final pending = kitchenOrders
        .where((o) => o.status == OrderStatus.pending)
        .length;
    final preparing = kitchenOrders
        .where((o) => o.status == OrderStatus.preparing)
        .length;
    final ready = kitchenOrders
        .where((o) => o.status == OrderStatus.ready)
        .length;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(
        title: context.l10n.kitchenTitle,
        showBack: false,
        useGradient: true,
      ),
      body: Column(
        children: [
          // ── Summary stats bar ──
          Container(
            margin: const EdgeInsets.fromLTRB(
              AppTheme.spacingMd, AppTheme.spacingSm,
              AppTheme.spacingMd, AppTheme.spacingXs,
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
              children: [
                Flexible(
                  child: _KitchenStat(
                    label: context.l10n.kitchenStatPending,
                    value: '$pending',
                    color: AppColors.statusPending,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Flexible(
                  child: _KitchenStat(
                    label: context.l10n.kitchenStatPreparing,
                    value: '$preparing',
                    color: AppColors.statusPreparing,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Flexible(
                  child: _KitchenStat(
                    label: context.l10n.kitchenStatReady,
                    value: '$ready',
                    color: AppColors.statusReady,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                TactileWrapper(
                  onTap: () => ref.read(ordersProvider.notifier).refresh(),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingSm),
                    child: Icon(
                      PhosphorIcons.arrowClockwise(PhosphorIconsStyle.duotone),
                      color: AppColors.grey500,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.08, end: 0),

          // ── Kitchen orders grid ──
          Expanded(
            child: kitchenOrders.isEmpty
                ? LomeEmptyState(
                    icon: PhosphorIcons.cookingPot(PhosphorIconsStyle.duotone),
                    title: context.l10n.kitchenEmptyTitle,
                    subtitle: context.l10n.kitchenEmptySubtitle,
                  )
                : GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppTheme.spacingMd,
                          crossAxisSpacing: AppTheme.spacingMd,
                          childAspectRatio: 0.7,
                        ),
                    itemCount: kitchenOrders.length,
                    itemBuilder: (ctx, i) {
                      final order = kitchenOrders[i];
                      final isNew = newIds.contains(order.id);
                      final card = _KitchenOrderCard(order: order);
                      if (isNew) {
                        return card
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.15, end: 0, duration: 400.ms)
                            .scale(
                              begin: const Offset(0.92, 0.92),
                              end: const Offset(1, 1),
                              duration: 400.ms,
                            );
                      }
                      return card;
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Card de pedido en cocina
// =============================================================================

class _KitchenOrderCard extends ConsumerWidget {
  final OrderEntity order;

  const _KitchenOrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _kitchenStatusColor(order.status);
    final elapsed = DateTime.now().difference(order.createdAt);
    final minutes = elapsed.inMinutes;

    final activeItems = order.items.where(
      (i) => i.status != OrderItemStatus.cancelled,
    );
    final readyCount = activeItems
        .where(
          (i) =>
              i.status == OrderItemStatus.ready ||
              i.status == OrderItemStatus.served,
        )
        .length;
    final totalCount = activeItems.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLg),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      '#${order.orderNumber}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    _TimerBadge(minutes: minutes),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: totalCount > 0 ? readyCount / totalCount : 0,
                          backgroundColor: AppColors.grey200,
                          color: AppColors.statusReady,
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      '$readyCount/$totalCount',
                      style: const TextStyle(
                        color: AppColors.grey500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Items ──
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
                vertical: AppTheme.spacingXs,
              ),
              children: order.items
                  .where((i) => i.status != OrderItemStatus.cancelled)
                  .map((item) => _KitchenItemRow(item: item, orderId: order.id))
                  .toList(),
            ),
          ),

          // ── Action button ──
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            child: SizedBox(
              width: double.infinity,
              child: _buildActionButton(context, ref, color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref, Color color) {
    switch (order.status) {
      case OrderStatus.pending:
        return TactileWrapper(
          onTap: () =>
              ref.read(ordersProvider.notifier).sendToKitchen(order.id),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.statusPreparing,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIcons.play(PhosphorIconsStyle.fill), size: 16, color: AppColors.white),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    context.l10n.kitchenStartPreparing,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.white),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      case OrderStatus.preparing:
        return TactileWrapper(
          onTap: () =>
              ref.read(ordersProvider.notifier).markOrderReady(order.id),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.statusReady,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), size: 16, color: AppColors.white),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    context.l10n.kitchenAllReady,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.white),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      case OrderStatus.ready:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.statusReady.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Center(
            child: Text(
              context.l10n.kitchenReadyToServe,
              style: const TextStyle(
                color: AppColors.statusReady,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// =============================================================================
// Item row
// =============================================================================

class _KitchenItemRow extends ConsumerWidget {
  final OrderItemEntity item;
  final String orderId;

  const _KitchenItemRow({required this.item, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _itemStatusColor(item.status);
    final isDone =
        item.status == OrderItemStatus.ready ||
        item.status == OrderItemStatus.served;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TactileWrapper(
        onTap: () => _advanceStatus(ref),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isDone
                ? AppColors.statusReady.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDone ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: isDone
                    ? Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 14, color: statusColor)
                    : Center(
                        child: Text(
                          '${item.quantity}',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
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
                      '${item.quantity}x ${item.name}',
                      style: TextStyle(
                        color: isDone ? AppColors.grey400 : AppColors.grey900,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        decoration: isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    if (item.notes != null && item.notes!.isNotEmpty)
                      Text(
                        item.notes!,
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.status.label,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _advanceStatus(WidgetRef ref) {
    final next = switch (item.status) {
      OrderItemStatus.pending => OrderItemStatus.preparing,
      OrderItemStatus.preparing => OrderItemStatus.ready,
      _ => null,
    };
    if (next == null) return;
    ref.read(ordersProvider.notifier).updateItemStatus(item.id, next);
  }
}

// =============================================================================
// Timer badge
// =============================================================================

class _TimerBadge extends StatelessWidget {
  final int minutes;

  const _TimerBadge({required this.minutes});

  @override
  Widget build(BuildContext context) {
    final isUrgent = minutes > 20;
    final isWarning = minutes > 10;
    final color = isUrgent
        ? AppColors.error
        : isWarning
        ? AppColors.warning
        : AppColors.grey500;
    final bgColor = isUrgent
        ? AppColors.error.withValues(alpha: 0.1)
        : isWarning
        ? AppColors.warning.withValues(alpha: 0.1)
        : AppColors.grey100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.clock(PhosphorIconsStyle.duotone), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '${minutes}m',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Helpers
// =============================================================================

class _KitchenStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _KitchenStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: AppColors.grey900,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.grey500, fontSize: 12),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

Color _kitchenStatusColor(OrderStatus status) => switch (status) {
  OrderStatus.pending => AppColors.statusPending,
  OrderStatus.preparing => AppColors.statusPreparing,
  OrderStatus.ready => AppColors.statusReady,
  _ => AppColors.grey500,
};

Color _itemStatusColor(OrderItemStatus status) => switch (status) {
  OrderItemStatus.pending => AppColors.statusPending,
  OrderItemStatus.preparing => AppColors.statusPreparing,
  OrderItemStatus.ready => AppColors.statusReady,
  OrderItemStatus.served => AppColors.statusServed,
  OrderItemStatus.cancelled => AppColors.grey500,
};
