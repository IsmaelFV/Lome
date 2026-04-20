import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../core/widgets/lome_empty_state.dart';
import '../../../../../core/widgets/lome_loading.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../../domain/entities/checkout_entities.dart';
import '../../../order_tracking/presentation/providers/order_tracking_provider.dart';

/// Página de historial de pedidos del cliente.
class CustomerOrdersPage extends ConsumerWidget {
  const CustomerOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(customerOrdersProvider);

    return Scaffold(
      appBar: LomeAppBar(
        title: context.l10n.marketplaceCustomerOrdersTitle,
        showBack: true,
      ),
      body: ordersAsync.when(
        loading: () => const LomeLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (orders) {
          if (orders.isEmpty) {
            return LomeEmptyState(
              icon: PhosphorIcons.receipt(PhosphorIconsStyle.duotone),
              title: context.l10n.marketplaceCustomerOrdersEmpty,
              subtitle: context.l10n.marketplaceCustomerOrdersSubtitle,
            );
          }
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            itemCount: orders.length,
            itemBuilder: (context, index) =>
                _OrderCard(order: orders[index])
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: index * 60),
                      duration: 300.ms,
                    )
                    .slideY(begin: 0.05, end: 0),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final DeliveryOrder order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (order.status) {
      DeliveryOrderStatus.pending => AppColors.warning,
      DeliveryOrderStatus.delivered ||
      DeliveryOrderStatus.completed => AppColors.success,
      DeliveryOrderStatus.cancelled => AppColors.error,
      _ => AppColors.primary,
    };

    return TactileWrapper(
      onTap: () => context.pushNamed(
        RouteNames.orderTracking,
        pathParameters: {'orderId': order.id},
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Restaurant logo
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    image: order.restaurantLogo != null
                        ? DecorationImage(
                            image: NetworkImage(order.restaurantLogo!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: order.restaurantLogo == null
                      ? Icon(
                          PhosphorIcons.storefront(PhosphorIconsStyle.duotone),
                          color: AppColors.grey400,
                          size: 22,
                        )
                      : null,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.restaurantName ??
                            context
                                .l10n
                                .marketplaceCustomerOrdersDefaultRestaurant,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (order.orderNumber != null)
                        Text(
                          context.l10n.marketplaceOrderTrackingOrderNumber(
                            order.orderNumber!.toString(),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grey500,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    order.status.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
              child: Divider(height: 1, color: AppColors.grey100),
            ),
              // Items summary
              ...order.items
                  .take(3)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '${item.quantity}x ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (order.items.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    context.l10n.marketplaceCustomerOrdersMoreItems(
                      order.items.length - 3,
                    ),
                    style: TextStyle(fontSize: 12, color: AppColors.grey400),
                  ),
                ),
              const SizedBox(height: AppTheme.spacingSm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(order.createdAt),
                    style: TextStyle(fontSize: 12, color: AppColors.grey400),
                  ),
                  Text(
                    '€${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
