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
import '../../../../../core/widgets/lome_loading.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../domain/entities/order_entity.dart';
import '../providers/orders_provider.dart';

/// Página de gestión de pedidos con tabs por estado.
class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(
        title: context.l10n.ordersTitle,
        showBack: false,
        useGradient: true,
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            Container(
              color: AppColors.white,
              child: TabBar(
                tabs: [
                  Tab(text: context.l10n.ordersTabActive),
                  Tab(text: context.l10n.ordersTabInKitchen),
                  Tab(text: context.l10n.ordersTabReady),
                  Tab(text: context.l10n.ordersTabHistory),
                ],
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.grey400,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.5,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: ordersAsync.when(
                loading: () => const LomeLoading(),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (orders) {
                  final pendingCount = orders
                      .where((o) => o.status == OrderStatus.pending)
                      .length;
                  final preparingCount = orders
                      .where((o) => o.status == OrderStatus.preparing)
                      .length;
                  final readyCount = orders
                      .where(
                        (o) =>
                            o.status == OrderStatus.ready ||
                            o.status == OrderStatus.served,
                      )
                      .length;

                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMd,
                          vertical: AppTheme.spacingSm,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMd,
                          vertical: AppTheme.spacingSm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: AppShadows.card,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _OrderStatDot(
                              label: context.l10n.ordersTabActive,
                              count: pendingCount,
                              color: AppColors.statusPending,
                            ),
                            _OrderStatDot(
                              label: context.l10n.ordersTabInKitchen,
                              count: preparingCount,
                              color: AppColors.statusPreparing,
                            ),
                            _OrderStatDot(
                              label: context.l10n.ordersTabReady,
                              count: readyCount,
                              color: AppColors.statusReady,
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: -0.05),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _OrderList(
                              orders: orders
                                  .where((o) =>
                                      o.status == OrderStatus.pending)
                                  .toList(),
                              emptyIcon: PhosphorIcons.receipt(
                                  PhosphorIconsStyle.duotone),
                              emptyTitle: context.l10n.ordersEmptyActive,
                              emptySubtitle:
                                  context.l10n.ordersEmptyActiveSubtitle,
                            ),
                            _OrderList(
                              orders: orders
                                  .where((o) =>
                                      o.status == OrderStatus.preparing)
                                  .toList(),
                              emptyIcon: PhosphorIcons.cookingPot(
                                  PhosphorIconsStyle.duotone),
                              emptyTitle: context.l10n.ordersEmptyKitchen,
                              emptySubtitle:
                                  context.l10n.ordersEmptyKitchenSubtitle,
                            ),
                            _OrderList(
                              orders: orders
                                  .where(
                                    (o) =>
                                        o.status == OrderStatus.ready ||
                                        o.status == OrderStatus.served,
                                  )
                                  .toList(),
                              emptyIcon: PhosphorIcons.checkCircle(
                                  PhosphorIconsStyle.duotone),
                              emptyTitle: context.l10n.ordersEmptyReady,
                              emptySubtitle:
                                  context.l10n.ordersEmptyReadySubtitle,
                            ),
                            _OrderList(
                              orders: orders
                                  .where(
                                    (o) =>
                                        o.status == OrderStatus.completed ||
                                        o.status == OrderStatus.cancelled,
                                  )
                                  .toList(),
                              emptyIcon:
                                  PhosphorIcons.clockCounterClockwise(
                                      PhosphorIconsStyle.duotone),
                              emptyTitle:
                                  context.l10n.ordersEmptyHistory,
                              emptySubtitle:
                                  context.l10n.ordersEmptyHistorySubtitle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Lista de pedidos
// =============================================================================

class _OrderList extends StatelessWidget {
  final List<OrderEntity> orders;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  const _OrderList({
    required this.orders,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return LomeEmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: orders.length,
      itemBuilder: (ctx, i) => _OrderCard(
        order: orders[i],
      )
          .animate()
          .fadeIn(duration: 200.ms, delay: (50 * i).ms)
          .slideY(begin: 0.03, end: 0, delay: (50 * i).ms),
    );
  }
}

// =============================================================================
// Card de pedido
// =============================================================================

class _OrderCard extends StatelessWidget {
  final OrderEntity order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);
    final elapsed = DateTime.now().difference(order.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: TactileWrapper(
        onTap: () {
          if (order.tableSessionId != null) {
            // Navigate to order detail
          }
        },
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Center(
                  child: Text(
                    '#${order.orderNumber}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withAlpha(20),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
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
                          _formatElapsed(elapsed),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.ordersItemCountAndType(
                        order.itemCount,
                        order.orderType.label,
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey500,
                      ),
                    ),
                    if (order.waiterName != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            PhosphorIcons.user(PhosphorIconsStyle.duotone),
                            size: 12,
                            color: AppColors.grey400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            order.waiterName!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.grey400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Text(
                '€${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.grey800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatElapsed(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inDays}d';
  }
}

// =============================================================================
// Resumen de stats por estado
// =============================================================================

class _OrderStatDot extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _OrderStatDot({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            shape: BoxShape.circle,
            border: Border.all(
              color: count > 0 ? color.withAlpha(80) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.grey500,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Helpers
// =============================================================================

Color _statusColor(OrderStatus status) => switch (status) {
  OrderStatus.pending => AppColors.statusPending,
  OrderStatus.confirmed => AppColors.statusConfirmed,
  OrderStatus.preparing => AppColors.statusPreparing,
  OrderStatus.ready => AppColors.statusReady,
  OrderStatus.served => AppColors.statusServed,
  OrderStatus.delivered => AppColors.statusDelivered,
  OrderStatus.cancelled => AppColors.statusCancelled,
  OrderStatus.completed => AppColors.statusCompleted,
};
