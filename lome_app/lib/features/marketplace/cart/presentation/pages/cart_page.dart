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
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../providers/cart_provider.dart';

/// Página del carrito de compra.
class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: LomeAppBar(
        title: context.l10n.marketplaceCartTitle,
        showBack: false,
        actions: [
          if (!cart.isEmpty)
            TactileWrapper(
              onTap: () => _confirmClear(context, ref),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                child: Icon(PhosphorIcons.trash(PhosphorIconsStyle.duotone), color: AppColors.grey700),
              ),
            ),
        ],
      ),
      body: cart.isEmpty
          ? LomeEmptyState(
              icon: PhosphorIcons.shoppingBag(PhosphorIconsStyle.duotone),
              title: context.l10n.marketplaceCartEmpty,
              subtitle: context.l10n.marketplaceCartEmptySubtitle,
            )
          : Column(
              children: [
                // Restaurant info banner
                if (cart.restaurantName != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(
                      AppTheme.spacingMd,
                      AppTheme.spacingSm,
                      AppTheme.spacingMd,
                      0,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingSm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: Icon(
                            PhosphorIcons.storefront(PhosphorIconsStyle.duotone),
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Text(
                          cart.restaurantName!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Items list
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final item = cart.items[i];
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: AppTheme.spacingMd),
                          margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          ),
                          child: Icon(
                            PhosphorIcons.trash(PhosphorIconsStyle.duotone),
                            color: AppColors.error,
                          ),
                        ),
                        confirmDismiss: (_) async {
                          ref.read(cartProvider.notifier).removeItem(item.id);
                          return false;
                        },
                        child: _CartItemCard(item: item),
                      ).animate().fadeIn(duration: 200.ms, delay: (50 * i).ms)
                          .slideX(begin: 0.05, end: 0);
                    },
                  ),
                ),

                // Summary & checkout
                _CartSummary(cart: cart),
              ],
            ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.marketplaceCartClearAll),
        content: Text(context.l10n.marketplaceCartClearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clear();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(context.l10n.marketplaceCartClearButton),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Cart item card
// =============================================================================

class _CartItemCard extends ConsumerWidget {
  final CartItem item;

  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: item.imageUrl != null
                ? Image.network(
                    item.imageUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(
                      PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
                      color: AppColors.grey300,
                      size: 26,
                    ),
                  ),
          ),
          const SizedBox(width: AppTheme.spacingMd),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (item.notes != null && item.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.grey500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  '€${item.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          Container(
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QtyButton(
                  icon: item.quantity > 1
                      ? PhosphorIcons.minus(PhosphorIconsStyle.duotone)
                      : PhosphorIcons.trash(PhosphorIconsStyle.duotone),
                  onTap: () {
                    if (item.quantity > 1) {
                      ref
                          .read(cartProvider.notifier)
                          .updateQuantity(item.id, item.quantity - 1);
                    } else {
                      ref.read(cartProvider.notifier).removeItem(item.id);
                    }
                  },
                  isDestructive: item.quantity <= 1,
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                _QtyButton(
                  icon: PhosphorIcons.plus(PhosphorIconsStyle.duotone),
                  onTap: () => ref
                      .read(cartProvider.notifier)
                      .updateQuantity(item.id, item.quantity + 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const _QtyButton({
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return TactileWrapper(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.error.withValues(alpha: 0.1)
              : AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDestructive ? AppColors.error : AppColors.primary,
        ),
      ),
    );
  }
}

// =============================================================================
// Cart summary footer
// =============================================================================

class _CartSummary extends StatelessWidget {
  final CartState cart;

  const _CartSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: AppShadows.navigation,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.marketplaceCartItemCount(cart.totalItems),
                  style: TextStyle(color: AppColors.grey500, fontSize: 14),
                ),
                Text(
                  context.l10n.marketplaceCartSubtotalAmount(
                    cart.subtotal.toStringAsFixed(2),
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            SizedBox(
              width: double.infinity,
              child: TactileWrapper(
                onTap: () => context.pushNamed(RouteNames.checkout),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    context.l10n.marketplaceCartCheckout,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
