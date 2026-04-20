import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_loading.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../../domain/entities/marketplace_entities.dart';
import '../../../domain/entities/review_entities.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../home/presentation/providers/marketplace_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../promotions/presentation/providers/promotions_provider.dart';
import '../../../reviews/presentation/providers/review_provider.dart';
import '../providers/menu_provider.dart';

/// Página de detalle del restaurante con su menú completo.
class RestaurantMenuPage extends ConsumerWidget {
  final String restaurantId;

  const RestaurantMenuPage({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(restaurantDetailProvider(restaurantId));
    final categoriesAsync = ref.watch(menuCategoriesProvider(restaurantId));
    final dishesAsync = ref.watch(menuDishesProvider(restaurantId));

    return detailAsync.when(
      loading: () => const Scaffold(body: LomeLoading()),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (restaurant) {
        if (restaurant == null) {
          return Scaffold(
            body: Center(
              child: Text(context.l10n.marketplaceRestaurantNotFound),
            ),
          );
        }
        return _RestaurantMenuScaffold(
          restaurant: restaurant,
          categoriesAsync: categoriesAsync,
          dishesAsync: dishesAsync,
        );
      },
    );
  }
}

class _RestaurantMenuScaffold extends ConsumerStatefulWidget {
  final MarketplaceRestaurant restaurant;
  final AsyncValue<List<MenuCategory>> categoriesAsync;
  final AsyncValue<List<Dish>> dishesAsync;

  const _RestaurantMenuScaffold({
    required this.restaurant,
    required this.categoriesAsync,
    required this.dishesAsync,
  });

  @override
  ConsumerState<_RestaurantMenuScaffold> createState() =>
      _RestaurantMenuScaffoldState();
}

class _RestaurantMenuScaffoldState
    extends ConsumerState<_RestaurantMenuScaffold> {
  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;
    final activeCategory = ref.watch(activeCategoryProvider);
    final cart = ref.watch(cartProvider);
    final cartItemCount = cart.totalItems;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.grey700,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                r.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.white,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (r.coverImageUrl != null)
                    Image.network(r.coverImageUrl!, fit: BoxFit.cover)
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.heroGradient,
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // Rating + cuisine overlay
                  Positioned(
                    bottom: 48,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                PhosphorIcons.star(PhosphorIconsStyle.fill),
                                size: 13,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                r.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                          ),
                          child: Text(
                            r.cuisineLabel,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Favorite toggle
              _FavoriteButton(restaurantId: r.id),
              if (cartItemCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TactileWrapper(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Badge(
                        label: Text('$cartItemCount'),
                        backgroundColor: AppColors.accent,
                        child: Icon(
                          PhosphorIcons.shoppingBag(PhosphorIconsStyle.fill),
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ── Info del restaurante ──
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(AppTheme.spacingMd),
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
                      if (r.logoUrl != null)
                        Container(
                          width: 48,
                          height: 48,
                          margin: const EdgeInsets.only(
                            right: AppTheme.spacingSm,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            border: Border.all(
                              color: AppColors.grey100,
                              width: 2,
                            ),
                            image: DecorationImage(
                              image: NetworkImage(r.logoUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.cuisineLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.grey500,
                              ),
                            ),
                            if (r.description != null)
                              Text(
                                r.description!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey400,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Row(
                    children: [
                      // Rating pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.star(PhosphorIconsStyle.fill),
                              size: 14,
                              color: AppColors.accentDark,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${r.rating.toStringAsFixed(1)} (${r.totalReviews})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AppColors.accentDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Delivery time pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.clock(PhosphorIconsStyle.duotone),
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              r.deliveryTimeLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (r.minimumOrderAmount != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          context.l10n.marketplaceRestaurantMenuMinOrder(
                            r.minimumOrderAmount!.toStringAsFixed(2),
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.03, end: 0),
          ),

          // ── Promociones del restaurante ──
          SliverToBoxAdapter(child: _RestaurantPromotions(restaurantId: r.id)),

          // ── Valoraciones del restaurante ──
          SliverToBoxAdapter(child: _RestaurantReviews(restaurantId: r.id)),

          // ── Tabs de categorías ──
          widget.categoriesAsync.when(
            loading: () => const SliverToBoxAdapter(child: LomeLoading()),
            error: (e, _) =>
                SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
            data: (categories) {
              if (categories.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      context.l10n.marketplaceRestaurantMenuUnavailable,
                    ),
                  ),
                );
              }

              // Si no hay categoría activa, seleccionamos la primera
              final effectiveActive = activeCategory ?? categories.first.id;

              return SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (ctx, i) {
                      final cat = categories[i];
                      final isActive = cat.id == effectiveActive;
                      return Padding(
                        padding: const EdgeInsets.only(
                          right: AppTheme.spacingSm,
                        ),
                        child: TactileWrapper(
                          onTap: () =>
                              ref.read(activeCategoryProvider.notifier).state =
                                  cat.id,
                          child: AnimatedContainer(
                            duration: AppTheme.durationFast,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusFull,
                              ),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.primary
                                    : AppColors.grey200,
                              ),
                              boxShadow: isActive ? AppShadows.card : null,
                            ),
                            child: Text(
                              cat.name,
                              style: TextStyle(
                                color: isActive
                                    ? AppColors.white
                                    : AppColors.grey600,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacingMd)),

          // ── Lista de platos ──
          widget.dishesAsync.when(
            loading: () => const SliverFillRemaining(child: LomeLoading()),
            error: (e, _) =>
                SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (dishes) {
              final effectiveActive =
                  activeCategory ??
                  (widget.categoriesAsync.valueOrNull?.isNotEmpty == true
                      ? widget.categoriesAsync.value!.first.id
                      : null);

              final filtered = effectiveActive != null
                  ? dishes
                        .where((d) => d.categoryId == effectiveActive)
                        .toList()
                  : dishes;

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      context.l10n.marketplaceRestaurantMenuCategoryEmpty,
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) =>
                        _DishCard(
                              dish: filtered[i],
                              restaurantId: widget.restaurant.id,
                              restaurantName: widget.restaurant.name,
                            )
                            .animate()
                            .fadeIn(
                              delay: Duration(milliseconds: i * 50),
                              duration: 300.ms,
                            )
                            .slideY(begin: 0.03, end: 0),
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // ── Cart bar fijo ──
      bottomNavigationBar: cartItemCount > 0
          ? Container(
              padding: EdgeInsets.fromLTRB(
                AppTheme.spacingMd,
                12,
                AppTheme.spacingMd,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: TactileWrapper(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Badge(
                        label: Text(
                          '$cartItemCount',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        backgroundColor: AppColors.accent,
                        child: Icon(
                          PhosphorIcons.shoppingBag(PhosphorIconsStyle.duotone),
                          color: AppColors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.l10n.marketplaceRestaurantMenuViewCart(
                            cartItemCount,
                          ),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Text(
                        '€${cart.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                        color: AppColors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            )
                .animate()
                .slideY(
                  begin: 1,
                  end: 0,
                  duration: 350.ms,
                  curve: Curves.easeOutCubic,
                )
          : null,
    );
  }
}

// =============================================================================
// Dish card
// =============================================================================

class _DishCard extends ConsumerWidget {
  final Dish dish;
  final String restaurantId;
  final String restaurantName;

  const _DishCard({
    required this.dish,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TactileWrapper(
      onTap: () => _showDishDetail(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppShadows.card,
        ),
        child: Row(
            children: [
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dish.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (dish.isFeatured)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              PhosphorIcons.fire(PhosphorIconsStyle.fill),
                              size: 14,
                              color: AppColors.accent,
                            ),
                          ),
                      ],
                    ),
                    if (dish.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        dish.description!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '€${dish.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (dish.tags.isNotEmpty)
                          ...dish.tags
                              .take(3)
                              .map(
                                (t) => Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: _TagChip(tag: t),
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),

              // Image + add button
              SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      child: dish.imageUrl != null
                          ? Image.network(
                              dish.imageUrl!,
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 88,
                              height: 88,
                              color: AppColors.grey100,
                              child: Icon(
                                PhosphorIcons.forkKnife(
                                  PhosphorIconsStyle.duotone,
                                ),
                                color: AppColors.grey300,
                                size: 32,
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: -6,
                      right: -6,
                      child: TactileWrapper(
                        onTap: () {
                          ref.read(cartProvider.notifier).addItem(
                            dish: dish,
                            restaurantId: restaurantId,
                            restaurantName: restaurantName,
                            quantity: 1,
                          );
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            gradient: AppColors.heroGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            PhosphorIcons.plus(PhosphorIconsStyle.bold),
                            size: 14,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  void _showDishDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      builder: (_) => _DishDetailSheet(
        dish: dish,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;

  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (tag) {
      'vegetarian' => ('🥬', AppColors.success),
      'vegan' => ('🌱', AppColors.success),
      'gluten_free' => ('GF', AppColors.info),
      'spicy' => ('🌶️', AppColors.error),
      _ => (tag, AppColors.grey400),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// =============================================================================
// Dish detail bottom sheet
// =============================================================================

class _DishDetailSheet extends ConsumerStatefulWidget {
  final Dish dish;
  final String restaurantId;
  final String restaurantName;

  const _DishDetailSheet({
    required this.dish,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  ConsumerState<_DishDetailSheet> createState() => _DishDetailSheetState();
}

class _DishDetailSheetState extends ConsumerState<_DishDetailSheet> {
  int _qty = 1;
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dish = widget.dish;

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
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
              ),
            ),

            // Image
            if (dish.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: Image.network(
                  dish.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: AppTheme.spacingMd),

            // Name + price
            Row(
              children: [
                Expanded(
                  child: Text(
                    dish.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    '€${dish.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),

            if (dish.description != null) ...[
              const SizedBox(height: 4),
              Text(
                dish.description!,
                style: const TextStyle(color: AppColors.grey500, fontSize: 14),
              ),
            ],

            // Tags row
            if (dish.tags.isNotEmpty || dish.allergens.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingSm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...dish.tags.map((t) => _TagChip(tag: t)),
                  ...dish.allergens.map(
                    (a) => Chip(
                      label: Text(a, style: const TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],

            const Divider(height: AppTheme.spacingLg, color: AppColors.grey100),

            // Notes
            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                hintText: context.l10n.marketplaceRestaurantMenuNotesHint,
                hintStyle: const TextStyle(
                  color: AppColors.grey400,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppColors.grey50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Quantity + Add button
            Row(
              children: [
                // Qty selector
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TactileWrapper(
                        onTap: _qty > 1
                            ? () => setState(() => _qty--)
                            : null,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            PhosphorIcons.minus(PhosphorIconsStyle.duotone),
                            size: 16,
                            color: _qty > 1
                                ? AppColors.grey700
                                : AppColors.grey300,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '$_qty',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      TactileWrapper(
                        onTap: () => setState(() => _qty++),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            PhosphorIcons.plus(PhosphorIconsStyle.duotone),
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),

                // Add to cart
                Expanded(
                  child: TactileWrapper(
                    onTap: () {
                      ref
                          .read(cartProvider.notifier)
                          .addItem(
                            dish: dish,
                            restaurantId: widget.restaurantId,
                            restaurantName: widget.restaurantName,
                            quantity: _qty,
                            notes: _notesCtrl.text.isNotEmpty
                                ? _notesCtrl.text
                                : null,
                          );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.l10n.marketplaceRestaurantMenuAddedToCart(
                              dish.name,
                            ),
                          ),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          context.l10n.marketplaceRestaurantMenuAddPriceButton(
                            (dish.price * _qty).toStringAsFixed(2),
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Favorite button (AppBar)
// =============================================================================

class _FavoriteButton extends ConsumerWidget {
  final String restaurantId;

  const _FavoriteButton({required this.restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(isFavoriteProvider(restaurantId));

    return TactileWrapper(
      onTap: () => ref.read(toggleFavoriteProvider(restaurantId)),
      child: Container(
        margin: const EdgeInsets.all(8),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFav
              ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
              : PhosphorIcons.heart(PhosphorIconsStyle.duotone),
          color: isFav ? AppColors.error : AppColors.white,
          size: 22,
        ),
      ),
    );
  }
}

// =============================================================================
// Restaurant promotions
// =============================================================================

class _RestaurantPromotions extends ConsumerWidget {
  final String restaurantId;

  const _RestaurantPromotions({required this.restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promosAsync = ref.watch(restaurantPromotionsProvider(restaurantId));

    return promosAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (promos) {
        if (promos.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      PhosphorIcons.tag(PhosphorIconsStyle.duotone),
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.marketplaceRestaurantMenuOffers,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              ...promos.map(
                (p) => Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                  padding: const EdgeInsets.all(AppTheme.spacingSm + 2),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                        ),
                        child: Text(
                          p.discountLabel,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (p.minimumOrderAmount != null)
                              Text(
                                context.l10n.marketplaceHomeMinOrder(
                                  '€${p.minimumOrderAmount!.toStringAsFixed(2)}',
                                ),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.grey500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (p.type == PromotionType.timeLimited &&
                          p.endDate != null)
                        Text(
                          context.l10n.marketplaceRestaurantMenuPromotionUntil(
                            '${p.endDate!.day}/${p.endDate!.month}',
                          ),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.grey400,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const Divider(height: AppTheme.spacingMd, color: AppColors.grey100),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// Restaurant reviews
// =============================================================================

class _RestaurantReviews extends ConsumerWidget {
  final String restaurantId;

  const _RestaurantReviews({required this.restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(restaurantReviewsProvider(restaurantId));

    return reviewsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (reviews) {
        if (reviews.isEmpty) return const SizedBox.shrink();
        final shown = reviews.take(5).toList();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      PhosphorIcons.chatCircleDots(PhosphorIconsStyle.duotone),
                      size: 16,
                      color: AppColors.accentDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.marketplaceRestaurantMenuReviewsCount(
                      reviews.length,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              ...shown.map((r) => _ReviewTile(review: r)),
              const Divider(height: AppTheme.spacingMd, color: AppColors.grey100),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (review.userName ?? '?')[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      review.userName ?? context.l10n.marketplaceProfileUser,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < review.rating
                            ? PhosphorIcons.star(PhosphorIconsStyle.fill)
                            : PhosphorIcons.star(PhosphorIconsStyle.duotone),
                        size: 12,
                        color: i < review.rating
                            ? AppColors.accentDark
                            : AppColors.grey300,
                      ),
                    ),
                  ],
                ),
                if (review.comment != null && review.comment!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    review.comment!,
                    style: TextStyle(fontSize: 12, color: AppColors.grey600),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (review.reply != null && review.reply!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          PhosphorIcons.storefront(PhosphorIconsStyle.duotone),
                          size: 12,
                          color: AppColors.grey500,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            review.reply!,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.grey600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
