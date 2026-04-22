import 'dart:async';

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
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_empty_state.dart';
import '../../../../../core/widgets/lome_loading.dart';
import '../../../../../core/widgets/lome_section_header.dart';
import '../../../../../core/widgets/lome_text_field.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../../domain/entities/marketplace_entities.dart';
import '../../../home/presentation/providers/marketplace_provider.dart';
import '../providers/search_provider.dart';

/// Página de búsqueda del marketplace.
///
/// Busca restaurantes y platos simultáneamente con debounce,
/// muestra búsquedas recientes y quick filters por tipo de cocina.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(searchQueryProvider.notifier).state = value;
      if (value.trim().length >= 2) {
        ref.read(recentSearchesProvider.notifier).add(value.trim());
      }
    });
  }

  void _applySearch(String query) {
    _searchCtrl.text = query;
    _searchCtrl.selection = TextSelection.collapsed(offset: query.length);
    ref.read(searchQueryProvider.notifier).state = query;
    ref.read(recentSearchesProvider.notifier).add(query);
  }

  void _clearSearch() {
    _searchCtrl.clear();
    ref.read(searchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final hasQuery = query.trim().length >= 2;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search bar ──
            _SearchBar(
              controller: _searchCtrl,
              focusNode: _focusNode,
              onChanged: _onQueryChanged,
              onClear: _clearSearch,
            ),

            // ── Content ──
            Expanded(
              child: hasQuery
                  ? const _SearchResultsView()
                  : _IdleView(
                      onRecentTap: _applySearch,
                      onCuisineTap: _applySearch,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Search Bar
// =============================================================================

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingMd,
        AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LomeSearchField(
        controller: controller,
        focusNode: focusNode,
        hint: context.l10n.marketplaceSearchPageHint,
        onChanged: onChanged,
        onClear: onClear,
      ),
    );
  }
}

// =============================================================================
// Idle View (sin búsqueda activa)
// =============================================================================

class _IdleView extends ConsumerWidget {
  final ValueChanged<String> onRecentTap;
  final ValueChanged<String> onCuisineTap;

  const _IdleView({required this.onRecentTap, required this.onCuisineTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentSearches = ref.watch(recentSearchesProvider);
    final cuisineTypesAsync = ref.watch(cuisineTypesProvider);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppTheme.spacingXl),
      children: [
        // ── Búsquedas recientes ──
        if (recentSearches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingMd,
              AppTheme.spacingMd,
              AppTheme.spacingSm,
              0,
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.clockCounterClockwise(
                    PhosphorIconsStyle.duotone,
                  ),
                  size: 18,
                  color: AppColors.grey500,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    context.l10n.marketplaceSearchRecent,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(recentSearchesProvider.notifier).clear(),
                  child: Text(
                    context.l10n.marketplaceHomeClearFilters,
                    style: TextStyle(fontSize: 12, color: AppColors.grey400),
                  ),
                ),
              ],
            ),
          ),
          ...recentSearches.asMap().entries.map(
            (entry) =>
                _RecentSearchTile(
                      query: entry.value,
                      onTap: () => onRecentTap(entry.value),
                      onRemove: () => ref
                          .read(recentSearchesProvider.notifier)
                          .remove(entry.value),
                    )
                    .animate()
                    .fadeIn(duration: 250.ms, delay: (40 * entry.key).ms)
                    .slideX(
                      begin: -0.03,
                      end: 0,
                      duration: 250.ms,
                      delay: (40 * entry.key).ms,
                    ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
        ],

        // ── Categorías de cocina ──
        cuisineTypesAsync.when(
          data: (types) {
            if (types.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LomeSectionHeader(
                  title: context.l10n.marketplaceHomeCategories,
                  icon: PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
                  animationDelay: 100,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                  ),
                  child: Wrap(
                    spacing: AppTheme.spacingSm,
                    runSpacing: AppTheme.spacingSm,
                    children: types
                        .asMap()
                        .entries
                        .map(
                          (entry) =>
                              _CuisineChip(
                                    label: entry.value,
                                    onTap: () => onCuisineTap(entry.value),
                                  )
                                  .animate()
                                  .fadeIn(
                                    duration: 300.ms,
                                    delay: (50 * entry.key).ms,
                                  )
                                  .scale(
                                    begin: const Offset(0.9, 0.9),
                                    end: const Offset(1, 1),
                                    duration: 300.ms,
                                    delay: (50 * entry.key).ms,
                                  ),
                        )
                        .toList(),
                  ),
                ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.only(top: AppTheme.spacingXl),
            child: LomeLoading(size: 32),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // ── Prompt decorativo ──
        if (recentSearches.isEmpty)
          Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingXxl),
                child: Column(
                  children: [
                    Icon(
                      PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.duotone),
                      size: 56,
                      color: AppColors.grey200,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text(
                      context.l10n.marketplaceSearchPrompt,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.grey400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
                duration: 500.ms,
              ),
      ],
    );
  }
}

// =============================================================================
// Búsqueda reciente tile
// =============================================================================

class _RecentSearchTile extends StatelessWidget {
  final String query;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentSearchTile({
    required this.query,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return TactileWrapper(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.light),
              size: 18,
              color: AppColors.grey400,
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Text(
                query,
                style: const TextStyle(fontSize: 14, color: AppColors.grey700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TactileWrapper(
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  PhosphorIcons.x(PhosphorIconsStyle.bold),
                  size: 14,
                  color: AppColors.grey300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Cuisine chip
// =============================================================================

class _CuisineChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CuisineChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TactileWrapper(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: AppColors.grey200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_cuisineIcon(label), size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _cuisineIcon(String cuisine) {
    final lower = cuisine.toLowerCase();
    if (lower.contains('pizza') || lower.contains('italian')) {
      return PhosphorIcons.pizza(PhosphorIconsStyle.duotone);
    }
    if (lower.contains('burger') || lower.contains('american')) {
      return PhosphorIcons.hamburger(PhosphorIconsStyle.duotone);
    }
    if (lower.contains('sushi') || lower.contains('japon')) {
      return PhosphorIcons.fish(PhosphorIconsStyle.duotone);
    }
    if (lower.contains('coffee') ||
        lower.contains('café') ||
        lower.contains('cafe')) {
      return PhosphorIcons.coffee(PhosphorIconsStyle.duotone);
    }
    if (lower.contains('panadería') ||
        lower.contains('bakery') ||
        lower.contains('pastel')) {
      return PhosphorIcons.bread(PhosphorIconsStyle.duotone);
    }
    if (lower.contains('healthy') ||
        lower.contains('salud') ||
        lower.contains('ensalad')) {
      return PhosphorIcons.leaf(PhosphorIconsStyle.duotone);
    }
    if (lower.contains('beer') ||
        lower.contains('cervez') ||
        lower.contains('bar')) {
      return PhosphorIcons.beerBottle(PhosphorIconsStyle.duotone);
    }
    if (lower.contains('china') ||
        lower.contains('asian') ||
        lower.contains('thai')) {
      return PhosphorIcons.bowlFood(PhosphorIconsStyle.duotone);
    }
    if (lower.contains('mexic') || lower.contains('taco')) {
      return PhosphorIcons.pepper(PhosphorIconsStyle.duotone);
    }
    return PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone);
  }
}

// =============================================================================
// Search Results View
// =============================================================================

class _SearchResultsView extends ConsumerWidget {
  const _SearchResultsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchResultsProvider);

    return resultsAsync.when(
      loading: () => const Center(child: LomeLoading()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Text('Error: $e', style: TextStyle(color: AppColors.error)),
        ),
      ),
      data: (results) {
        if (results.isEmpty) {
          return LomeEmptyState(
            icon: PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.duotone),
            title: context.l10n.marketplaceSearchEmpty,
            subtitle: context.l10n.marketplaceHomeNoRestaurantsSubtitle,
          ).animate().fadeIn(duration: 300.ms);
        }

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppTheme.spacingXl),
          children: [
            // ── Restaurantes ──
            if (results.restaurants.isNotEmpty) ...[
              LomeSectionHeader(
                title: context.l10n.marketplaceSearchRestaurantsSection(
                  results.restaurants.length,
                ),
                icon: PhosphorIcons.storefront(PhosphorIconsStyle.duotone),
              ),
              ...results.restaurants.asMap().entries.map(
                (entry) => _RestaurantResultCard(restaurant: entry.value)
                    .animate()
                    .fadeIn(duration: 300.ms, delay: (50 * entry.key).ms)
                    .slideY(
                      begin: 0.03,
                      end: 0,
                      duration: 300.ms,
                      delay: (50 * entry.key).ms,
                    ),
              ),
            ],

            // ── Platos ──
            if (results.dishes.isNotEmpty) ...[
              if (results.restaurants.isNotEmpty)
                const SizedBox(height: AppTheme.spacingSm),
              LomeSectionHeader(
                title: context.l10n.marketplaceSearchDishesSection(
                  results.dishes.length,
                ),
                icon: PhosphorIcons.bowlFood(PhosphorIconsStyle.duotone),
              ),
              ...results.dishes.asMap().entries.map(
                (entry) => _DishResultCard(result: entry.value)
                    .animate()
                    .fadeIn(duration: 300.ms, delay: (50 * entry.key).ms)
                    .slideY(
                      begin: 0.03,
                      end: 0,
                      duration: 300.ms,
                      delay: (50 * entry.key).ms,
                    ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// =============================================================================
// Restaurant Result Card (compact)
// =============================================================================

class _RestaurantResultCard extends StatelessWidget {
  final MarketplaceRestaurant restaurant;

  const _RestaurantResultCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingXs,
      ),
      child: TactileWrapper(
        onTap: () => context.pushNamed(
          RouteNames.restaurantDetail,
          pathParameters: {'id': restaurant.id},
        ),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              // Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child:
                      restaurant.coverImageUrl != null ||
                          restaurant.logoUrl != null
                      ? CachedNetworkImage(
                          imageUrl:
                              restaurant.coverImageUrl ?? restaurant.logoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _placeholder(),
                          errorWidget: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (restaurant.isFeatured)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusFull,
                              ),
                            ),
                            child: Icon(
                              PhosphorIcons.star(PhosphorIconsStyle.fill),
                              size: 10,
                              color: AppColors.white,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      restaurant.cuisineLabel,
                      style: TextStyle(fontSize: 12, color: AppColors.grey500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (restaurant.rating > 0) ...[
                          Icon(
                            PhosphorIcons.star(PhosphorIconsStyle.fill),
                            size: 12,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            restaurant.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.grey700,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingSm),
                        ],
                        Icon(
                          PhosphorIcons.clock(PhosphorIconsStyle.duotone),
                          size: 12,
                          color: AppColors.grey400,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          restaurant.deliveryTimeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                size: 16,
                color: AppColors.grey300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.grey100,
      child: Center(
        child: Icon(
          PhosphorIcons.storefront(PhosphorIconsStyle.duotone),
          size: 24,
          color: AppColors.grey300,
        ),
      ),
    );
  }
}

// =============================================================================
// Dish Result Card
// =============================================================================

class _DishResultCard extends StatelessWidget {
  final DishSearchResult result;

  const _DishResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final dish = result.dish;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingXs,
      ),
      child: TactileWrapper(
        onTap: () => context.pushNamed(
          RouteNames.restaurantDetail,
          pathParameters: {'id': result.restaurantId},
        ),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              // Dish image
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: dish.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: dish.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _dishPlaceholder(),
                          errorWidget: (_, __, ___) => _dishPlaceholder(),
                        )
                      : _dishPlaceholder(),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dish.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Restaurant name
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.storefront(PhosphorIconsStyle.light),
                          size: 12,
                          color: AppColors.grey400,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            result.restaurantName,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.grey500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Price
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.12),
                                AppColors.primary.withValues(alpha: 0.04),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                          ),
                          child: Text(
                            '€${dish.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        // Tags
                        if (dish.tags.isNotEmpty) ...[
                          const SizedBox(width: AppTheme.spacingSm),
                          ...dish.tags
                              .take(2)
                              .map(
                                (tag) => Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.grey100,
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusFull,
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.grey500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                size: 16,
                color: AppColors.grey300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dishPlaceholder() {
    return Container(
      color: AppColors.primarySoft,
      child: Center(
        child: Icon(
          PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
          size: 24,
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
