import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/lome_empty_state.dart';
import '../../../../../core/widgets/lome_loading.dart';
import '../../../../../core/widgets/lome_section_header.dart';
import '../../../../../core/widgets/lome_text_field.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../domain/entities/marketplace_entities.dart';
import '../../../domain/entities/review_entities.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../promotions/presentation/providers/promotions_provider.dart';
import '../../../recommendations/presentation/providers/recommendations_provider.dart';
import '../providers/marketplace_provider.dart';

/// Página principal del marketplace.
///
/// Muestra restaurantes destacados, categorías dinámicas y barra de búsqueda.
class MarketplaceHomePage extends ConsumerStatefulWidget {
  const MarketplaceHomePage({super.key});

  @override
  ConsumerState<MarketplaceHomePage> createState() =>
      _MarketplaceHomePageState();
}

class _MarketplaceHomePageState extends ConsumerState<MarketplaceHomePage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(marketplaceRestaurantsProvider);
    final cuisinesAsync = ref.watch(cuisineTypesProvider);
    final filter = ref.watch(restaurantFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Sticky header: búsqueda Wolt-style ──
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            backgroundColor: AppColors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingMd,
                    AppTheme.spacingXs,
                    AppTheme.spacingMd,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                            context.l10n.marketplaceHomeSearchHint,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.grey900,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: -0.05, end: 0),
                      const SizedBox(height: AppTheme.spacingSm),
                      LomeSearchField(
                        hint: context.l10n.marketplaceSearchHint,
                        controller: _searchCtrl,
                        onChanged: (v) =>
                            ref
                                .read(restaurantFilterProvider.notifier)
                                .state = filter.copyWith(
                              searchQuery: v,
                              clearSearch: v.isEmpty,
                            ),
                      ).animate().fadeIn(delay: 150.ms, duration: 350.ms),
                    ],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppColors.grey100),
            ),
          ),

          // ── Categorías dinámicas (Wolt/Grab circles) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                0,
                AppTheme.spacingMd,
                0,
                AppTheme.spacingXs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                    ),
                    child: LomeSectionHeader(
                      icon: PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
                      title: context.l10n.marketplaceHomeCategories,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  SizedBox(
                    height: 108,
                    child: cuisinesAsync.when(
                      loading: () => const Center(child: LomeLoading()),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (cuisines) => ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMd,
                        ),
                        itemCount: cuisines.length,
                        itemBuilder: (ctx, i) {
                          final name = cuisines[i];
                          final isActive = filter.cuisineType == name;
                          return _CategoryChip(
                                icon: _cuisineIcon(name),
                                label: name,
                                isActive: isActive,
                                onTap: () {
                                  ref
                                      .read(restaurantFilterProvider.notifier)
                                      .state = isActive
                                      ? filter.copyWith(clearCuisine: true)
                                      : filter.copyWith(cuisineType: name);
                                },
                              )
                              .animate()
                              .fadeIn(
                                delay: Duration(milliseconds: i * 60),
                                duration: 300.ms,
                              )
                              .slideY(begin: 0.15, end: 0);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Chips de filtro rápidos ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
              ),
              child: Row(
                children: [
                  _QuickFilterChip(
                    label: context.l10n.marketplaceHomeDelivery,
                    icon: PhosphorIcons.moped(PhosphorIconsStyle.duotone),
                    isActive: filter.onlyDelivery,
                    onTap: () =>
                        ref.read(restaurantFilterProvider.notifier).state =
                            filter.copyWith(onlyDelivery: !filter.onlyDelivery),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  _QuickFilterChip(
                    label: context.l10n.marketplaceHomeFeatured,
                    icon: PhosphorIcons.star(PhosphorIconsStyle.duotone),
                    isActive: filter.onlyFeatured,
                    onTap: () =>
                        ref.read(restaurantFilterProvider.notifier).state =
                            filter.copyWith(onlyFeatured: !filter.onlyFeatured),
                  ),
                  const Spacer(),
                  if (filter.hasFilters)
                    TactileWrapper(
                      onTap: () =>
                          ref.read(restaurantFilterProvider.notifier).state =
                              const RestaurantFilter(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIcons.x(PhosphorIconsStyle.duotone),
                            size: 14,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.marketplaceHomeClearFilters,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Promociones activas ──
          SliverToBoxAdapter(child: _PromotionsBanner()),

          // ── Recomendados para ti ──
          SliverToBoxAdapter(child: _RecommendationsSection()),

          // ── Título sección restaurantes ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingMd,
                AppTheme.spacingLg,
                AppTheme.spacingMd,
                AppTheme.spacingSm,
              ),
              child: LomeSectionHeader(
                icon: PhosphorIcons.storefront(PhosphorIconsStyle.duotone),
                title: filter.hasFilters
                    ? context.l10n.marketplaceHomeResults
                    : context.l10n.restaurants,
              ),
            ),
          ),

          // ── Lista de restaurantes ──
          restaurantsAsync.when(
            loading: () => const SliverFillRemaining(child: LomeLoading()),
            error: (e, _) =>
                SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (restaurants) {
              if (restaurants.isEmpty) {
                return SliverFillRemaining(
                  child: LomeEmptyState(
                    icon: PhosphorIcons.storefront(PhosphorIconsStyle.duotone),
                    title: context.l10n.marketplaceHomeNoRestaurants,
                    subtitle: context.l10n.marketplaceHomeNoRestaurantsSubtitle,
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacingMd,
                      ),
                      child: _RestaurantCard(restaurant: restaurants[index])
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: index * 60),
                            duration: 350.ms,
                          )
                          .slideY(begin: 0.04, end: 0),
                    ),
                    childCount: restaurants.length,
                  ),
                ),
              );
            },
          ),

          // Espaciado inferior
          const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacingXl)),
        ],
      ),
    );
  }
}

// =============================================================================
// Category chip
// =============================================================================

IconData _cuisineIcon(String cuisine) {
  final lower = cuisine.toLowerCase();
  if (lower.contains('pizza'))
    return PhosphorIcons.pizza(PhosphorIconsStyle.duotone);
  if (lower.contains('sushi') || lower.contains('japon'))
    return PhosphorIcons.fish(PhosphorIconsStyle.duotone);
  if (lower.contains('burger') || lower.contains('hambur'))
    return PhosphorIcons.hamburger(PhosphorIconsStyle.duotone);
  if (lower.contains('asia') ||
      lower.contains('china') ||
      lower.contains('thai')) {
    return PhosphorIcons.bowlFood(PhosphorIconsStyle.duotone);
  }
  if (lower.contains('café') || lower.contains('cafe'))
    return PhosphorIcons.coffee(PhosphorIconsStyle.duotone);
  if (lower.contains('panad') || lower.contains('baker'))
    return PhosphorIcons.bread(PhosphorIconsStyle.duotone);
  if (lower.contains('mexi'))
    return PhosphorIcons.fire(PhosphorIconsStyle.duotone);
  if (lower.contains('indi'))
    return PhosphorIcons.bowlSteam(PhosphorIconsStyle.duotone);
  if (lower.contains('mediterr') || lower.contains('español'))
    return PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone);
  return PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone);
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacingSm),
      child: TactileWrapper(
        onTap: onTap,
        child: SizedBox(
          width: 76,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  border: Border.all(
                    color: isActive ? AppColors.primary : AppColors.grey100,
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isActive ? AppColors.white : AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppColors.primary : AppColors.grey600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Quick filter chip
// =============================================================================

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _QuickFilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TactileWrapper(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.grey200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppColors.white : AppColors.grey500,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.white : AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Restaurant card con datos reales
// =============================================================================

class _RestaurantCard extends ConsumerWidget {
  final MarketplaceRestaurant restaurant;

  const _RestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(isFavoriteProvider(restaurant.id));

    return TactileWrapper(
      onTap: () => context.pushNamed(
        RouteNames.restaurantDetail,
        pathParameters: {'id': restaurant.id},
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image with overlays
            SizedBox(
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusLg),
                    ),
                    child: restaurant.coverImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: restaurant.coverImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppColors.grey100,
                              child: Center(
                                child: Icon(
                                  PhosphorIcons.image(
                                    PhosphorIconsStyle.duotone,
                                  ),
                                  size: 32,
                                  color: AppColors.grey300,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.grey100,
                              child: Center(
                                child: Icon(
                                  PhosphorIcons.forkKnife(
                                    PhosphorIconsStyle.duotone,
                                  ),
                                  size: 48,
                                  color: AppColors.grey400,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.grey200,
                            child: Center(
                              child: Icon(
                                PhosphorIcons.forkKnife(
                                  PhosphorIconsStyle.duotone,
                                ),
                                size: 48,
                                color: AppColors.grey400,
                              ),
                            ),
                          ),
                  ),
                  // Bottom gradient for text legibility
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Favorite button
                  Positioned(
                    top: AppTheme.spacingSm,
                    right: AppTheme.spacingSm,
                    child: TactileWrapper(
                      onTap: () =>
                          ref.read(toggleFavoriteProvider(restaurant.id)),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          isFav
                              ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
                              : PhosphorIcons.heart(PhosphorIconsStyle.duotone),
                          size: 18,
                          color: isFav ? AppColors.error : AppColors.grey400,
                        ),
                      ),
                    ),
                  ),
                  // Featured badge
                  if (restaurant.isFeatured)
                    Positioned(
                      top: AppTheme.spacingSm,
                      left: AppTheme.spacingSm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.star(PhosphorIconsStyle.fill),
                              size: 12,
                              color: AppColors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.l10n.marketplaceHomeFeatured,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Delivery time badge (Wolt-style bottom-right)
                  Positioned(
                    bottom: AppTheme.spacingSm,
                    right: AppTheme.spacingSm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIcons.clock(PhosphorIconsStyle.fill),
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            restaurant.deliveryTimeLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Social proof badge
                  if (restaurant.totalReviews > 50)
                    Positioned(
                      bottom: AppTheme.spacingSm,
                      left: AppTheme.spacingSm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.fire(PhosphorIconsStyle.fill),
                              size: 12,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Popular',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info section
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Logo
                      if (restaurant.logoUrl != null) ...[
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.grey100,
                              width: 2,
                            ),
                            image: DecorationImage(
                              image: NetworkImage(restaurant.logoUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              restaurant.cuisineLabel,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.grey500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  // Metadata row
                  Row(
                    children: [
                      // Rating
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
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
                              restaurant.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.accentDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${restaurant.totalReviews})',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.grey400,
                        ),
                      ),
                      const Spacer(),
                      if (restaurant.deliveryEnabled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                PhosphorIcons.moped(PhosphorIconsStyle.fill),
                                size: 13,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                context.l10n.marketplaceHomeDelivery,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Promotions banner carousel
// =============================================================================

class _PromotionsBanner extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PromotionsBanner> createState() => _PromotionsBannerState();
}

class _PromotionsBannerState extends ConsumerState<_PromotionsBanner> {
  final _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promosAsync = ref.watch(activePromotionsProvider);

    return promosAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (promos) {
        if (promos.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, AppTheme.spacingMd, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                ),
                child: LomeSectionHeader(
                  icon: PhosphorIcons.megaphone(PhosphorIconsStyle.duotone),
                  title: context.l10n.marketplaceHomePromotions,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              SizedBox(
                height: 180,
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: promos.length,
                  itemBuilder: (ctx, i) =>
                      Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: _PromotionCard(promo: promos[i]),
                          )
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: i * 80),
                            duration: 300.ms,
                          )
                          .slideX(begin: 0.1, end: 0),
                ),
              ),
              if (promos.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spacingSm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      promos.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentPage == i ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.primary
                              : AppColors.grey200,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PromotionCard extends StatelessWidget {
  final Promotion promo;

  const _PromotionCard({required this.promo});

  @override
  Widget build(BuildContext context) {
    final isTimeLimited = promo.type == PromotionType.timeLimited;

    return TactileWrapper(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          gradient: isTimeLimited
              ? LinearGradient(
                  colors: [
                    AppColors.error,
                    AppColors.error.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF22C55E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: (isTimeLimited ? AppColors.error : AppColors.primary)
                  .withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    promo.discountLabel,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Spacer(),
                if (isTimeLimited)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIcons.timer(PhosphorIconsStyle.fill),
                      size: 16,
                      color: AppColors.white,
                    ),
                  ),
              ],
            ),
            Text(
              promo.title,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                if (promo.restaurantName != null) ...[
                  Icon(
                    PhosphorIcons.storefront(PhosphorIconsStyle.fill),
                    size: 13,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      promo.restaurantName!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (promo.minimumOrderAmount != null)
                  Text(
                    'Min. €${promo.minimumOrderAmount!.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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
// Recommendations section
// =============================================================================

class _RecommendationsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recsAsync = ref.watch(recommendedRestaurantsProvider);

    return recsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (restaurants) {
        if (restaurants.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, AppTheme.spacingMd, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                ),
                child: LomeSectionHeader(
                  icon: PhosphorIcons.sparkle(PhosphorIconsStyle.duotone),
                  title: context.l10n.marketplaceHomeRecommended,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                  ),
                  itemCount: restaurants.length,
                  itemBuilder: (ctx, i) =>
                      _RecommendationCard(restaurant: restaurants[i])
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: i * 70),
                            duration: 300.ms,
                          )
                          .slideX(begin: 0.08, end: 0),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final MarketplaceRestaurant restaurant;

  const _RecommendationCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return TactileWrapper(
      onTap: () => context.pushNamed(
        RouteNames.restaurantDetail,
        pathParameters: {'id': restaurant.id},
      ),
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: AppTheme.spacingSm),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusLg),
                ),
                image: restaurant.coverImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(restaurant.coverImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: restaurant.coverImageUrl == null
                  ? Center(
                      child: Icon(
                        PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
                        size: 32,
                        color: AppColors.grey400,
                      ),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    restaurant.cuisineLabel,
                    style: TextStyle(fontSize: 12, color: AppColors.grey500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
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
                              size: 11,
                              color: AppColors.accentDark,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              restaurant.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        PhosphorIcons.clock(PhosphorIconsStyle.duotone),
                        size: 12,
                        color: AppColors.grey400,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        restaurant.deliveryTimeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.grey400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
