import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/lome_loading.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../../../../shared/providers/supabase_provider.dart';
import '../../../../marketplace/domain/entities/marketplace_entities.dart';
import '../../../../marketplace/home/presentation/providers/marketplace_provider.dart';
import '../../../../marketplace/menu/presentation/providers/menu_provider.dart'
    as mp;
import '../../domain/entities/menu_design_entity.dart';

// =============================================================================
// Provider público de diseño de carta (por tenantId, sin auth necesaria)
// =============================================================================

final publicMenuDesignProvider = FutureProvider.autoDispose
    .family<MenuDesign?, String>((ref, tenantId) async {
      final client = ref.read(supabaseClientProvider);
      final rows = await client
          .from('menu_designs')
          .select()
          .eq('tenant_id', tenantId)
          .eq('is_published', true)
          .limit(1);
      if (rows.isEmpty) return null;
      return MenuDesign.fromJson(rows.first);
    });

/// Carta digital interactiva del restaurante.
///
/// Esta es la página destino del QR: muestra el menú completo del restaurante
/// con el diseño personalizado (colores, fuentes, animaciones, bloques).
class DigitalMenuPage extends ConsumerWidget {
  final String restaurantId;

  const DigitalMenuPage({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantAsync = ref.watch(restaurantDetailProvider(restaurantId));
    final categoriesAsync = ref.watch(mp.menuCategoriesProvider(restaurantId));
    final dishesAsync = ref.watch(mp.menuDishesProvider(restaurantId));
    final designAsync = ref.watch(publicMenuDesignProvider(restaurantId));

    return restaurantAsync.when(
      loading: () => const Scaffold(body: LomeLoading()),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (restaurant) {
        if (restaurant == null) {
          return const Scaffold(
            body: Center(child: Text('Restaurante no encontrado')),
          );
        }

        final design = designAsync.valueOrNull;
        final categories = categoriesAsync.valueOrNull ?? [];
        final dishes = dishesAsync.valueOrNull ?? [];

        return _DigitalMenuScaffold(
          restaurant: restaurant,
          design: design,
          categories: categories,
          dishes: dishes,
        );
      },
    );
  }
}

class _DigitalMenuScaffold extends StatefulWidget {
  final MarketplaceRestaurant restaurant;
  final MenuDesign? design;
  final List<MenuCategory> categories;
  final List<Dish> dishes;

  const _DigitalMenuScaffold({
    required this.restaurant,
    required this.design,
    required this.categories,
    required this.dishes,
  });

  @override
  State<_DigitalMenuScaffold> createState() => _DigitalMenuScaffoldState();
}

class _DigitalMenuScaffoldState extends State<_DigitalMenuScaffold> {
  String? _activeCategory;

  MenuDesign get _design =>
      widget.design ?? const MenuDesign(id: '', tenantId: '');

  Color _parseColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final bg = _parseColor(_design.backgroundColor);
    final primary = _parseColor(_design.primaryColor);
    final textColor = _parseColor(_design.textColor);
    final cardColor = _parseColor(_design.cardColor);

    final filteredDishes = _activeCategory != null
        ? widget.dishes.where((d) => d.categoryId == _activeCategory).toList()
        : widget.dishes;

    final featuredDishes = widget.dishes.where((d) => d.isFeatured).toList();

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          _buildHeader(primary, textColor),

          // ── Destacados ──
          if (featuredDishes.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionTitle('✨ Destacados', textColor),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 210,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                  ),
                  itemCount: featuredDishes.length,
                  itemBuilder: (context, index) {
                    return _buildFeaturedCard(
                      featuredDishes[index],
                      index,
                      primary,
                      cardColor,
                      textColor,
                    );
                  },
                ),
              ),
            ),
          ],

          // ── Categorías tabs ──
          SliverToBoxAdapter(child: _buildCategoryTabs(primary, textColor)),

          // ── Items del menú ──
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            sliver: _design.itemsLayout == 'grid'
                ? _buildGrid(filteredDishes, cardColor, textColor, primary)
                : _buildList(filteredDishes, cardColor, textColor, primary),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(Color primary, Color textColor) {
    final r = widget.restaurant;
    final headerImg = _design.headerImageUrl ?? r.coverImageUrl;

    return SliverAppBar(
      expandedHeight: _design.headerStyle == 'hero' ? 300 : 220,
      pinned: true,
      backgroundColor: primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (headerImg != null)
              Image.network(
                headerImg,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: primary),
              )
            else
              Container(color: primary),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            if (_design.showRestaurantInfo)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: _logoAlignment,
                  children: [
                    if (r.logoUrl != null && _design.logoPosition != 'hidden')
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        child: Image.network(
                          r.logoUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      r.name,
                      style: TextStyle(
                        fontFamily: _design.headerFontFamily,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (r.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        r.description!,
                        style: TextStyle(
                          fontFamily: _design.fontFamily,
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIcons.star(PhosphorIconsStyle.fill),
                          color: AppColors.warning,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${r.rating.toStringAsFixed(1)} (${r.totalReviews})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        if (r.cuisineType.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(
                            PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              r.cuisineLabel,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
              ),
          ],
        ),
      ),
    );
  }

  CrossAxisAlignment get _logoAlignment {
    switch (_design.logoPosition) {
      case 'left':
        return CrossAxisAlignment.start;
      case 'right':
        return CrossAxisAlignment.end;
      default:
        return CrossAxisAlignment.center;
    }
  }

  // ── Categorías ──────────────────────────────────────────────────────────────

  Widget _buildCategoryTabs(Color primary, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      child: SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          children: [
            _buildCategoryChip(
              null,
              AppLocalizations.of(context).digitalMenuAll,
              primary,
              textColor,
            ),
            ...widget.categories.map(
              (c) => _buildCategoryChip(c.id, c.name, primary, textColor),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }

  Widget _buildCategoryChip(
    String? id,
    String label,
    Color primary,
    Color textColor,
  ) {
    final isActive = _activeCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacingSm),
      child: FilterChip(
        selected: isActive,
        label: Text(label),
        onSelected: (_) => setState(() => _activeCategory = id),
        selectedColor: primary.withValues(alpha: 0.15),
        checkmarkColor: primary,
        labelStyle: TextStyle(
          color: isActive ? primary : textColor.withValues(alpha: 0.7),
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          fontFamily: _design.fontFamily,
        ),
        side: BorderSide(
          color: isActive ? primary : textColor.withValues(alpha: 0.15),
        ),
      ),
    );
  }

  // ── Section Title ───────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingLg,
        AppTheme.spacingMd,
        AppTheme.spacingSm,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: _design.headerFontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }

  // ── Featured Card ───────────────────────────────────────────────────────────

  Widget _buildFeaturedCard(
    Dish dish,
    int index,
    Color primary,
    Color cardColor,
    Color textColor,
  ) {
    return Container(
          width: 170,
          margin: const EdgeInsets.only(right: AppTheme.spacingMd),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusLg),
                ),
                child: dish.imageUrl != null
                    ? Image.network(
                        dish.imageUrl!,
                        height: 110,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 110,
                        color: primary.withValues(alpha: 0.1),
                        child: Icon(
                          PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
                          size: 40,
                          color: primary.withValues(alpha: 0.4),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dish.name,
                      style: TextStyle(
                        fontFamily: _design.fontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '€${dish.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: _design.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 150 + index * 100),
          duration: 400.ms,
        )
        .scaleXY(
          begin: 0.9,
          end: 1,
          delay: Duration(milliseconds: 150 + index * 100),
          duration: 400.ms,
          curve: Curves.easeOutBack,
        );
  }

  // ── List layout ─────────────────────────────────────────────────────────────

  SliverList _buildList(
    List<Dish> dishes,
    Color cardColor,
    Color textColor,
    Color primary,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final dish = dishes[index];
        return _DishListTile(
          dish: dish,
          design: _design,
          cardColor: cardColor,
          textColor: textColor,
          primary: primary,
          index: index,
        );
      }, childCount: dishes.length),
    );
  }

  // ── Grid layout ─────────────────────────────────────────────────────────────

  SliverGrid _buildGrid(
    List<Dish> dishes,
    Color cardColor,
    Color textColor,
    Color primary,
  ) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppTheme.spacingSm,
        crossAxisSpacing: AppTheme.spacingSm,
        childAspectRatio: 0.75,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final dish = dishes[index];
        return _DishGridCard(
          dish: dish,
          design: _design,
          cardColor: cardColor,
          textColor: textColor,
          primary: primary,
          index: index,
        );
      }, childCount: dishes.length),
    );
  }
}

// =============================================================================
// Dish List Tile
// =============================================================================

class _DishListTile extends StatelessWidget {
  final Dish dish;
  final MenuDesign design;
  final Color cardColor;
  final Color textColor;
  final Color primary;
  final int index;

  const _DishListTile({
    required this.dish,
    required this.design,
    required this.cardColor,
    required this.textColor,
    required this.primary,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: TactileWrapper(
        onTap: () => _showDishDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dish.isFeatured)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '🔥 Destacado',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                        ),
                      ),
                    Text(
                      dish.name,
                      style: TextStyle(
                        fontFamily: design.fontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: design.fontSizeBase.toDouble(),
                        color: textColor,
                      ),
                    ),
                    if (design.showDescriptions &&
                        dish.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        dish.description!,
                        style: TextStyle(
                          fontFamily: design.fontFamily,
                          fontSize: design.fontSizeBase - 2,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (design.showTags && dish.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: dish.tags.map((t) {
                          return _TagBadge(tag: t, primary: primary);
                        }).toList(),
                      ),
                    ],
                    if (design.showAllergens && dish.allergens.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            PhosphorIcons.warning(PhosphorIconsStyle.duotone),
                            size: 12,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dish.allergens.join(', '),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '€${dish.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontFamily: design.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: design.fontSizeBase + 2,
                            color: primary,
                          ),
                        ),
                        if (design.showPrepTime &&
                            dish.preparationTimeMin != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            PhosphorIcons.clock(),
                            size: 14,
                            color: textColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${dish.preparationTimeMin} min',
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                        if (design.showCalories && dish.calories != null) ...[
                          const SizedBox(width: 12),
                          Text(
                            '${dish.calories} kcal',
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (design.showImages && dish.imageUrl != null) ...[
                const SizedBox(width: AppTheme.spacingMd),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Image.network(
                    dish.imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: index * 60),
      duration: 300.ms,
    );
  }

  void _showDishDetail(BuildContext context) {
    final textC = textColor;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            if (dish.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: Image.network(
                  dish.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              dish.name,
              style: TextStyle(
                fontFamily: design.headerFontFamily,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: textC,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '€${dish.price.toStringAsFixed(2)}',
              style: TextStyle(
                fontFamily: design.fontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
            if (dish.description != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                dish.description!,
                style: TextStyle(
                  fontFamily: design.fontFamily,
                  fontSize: 15,
                  color: textC.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ],
            if (dish.tags.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: dish.tags
                    .map((t) => _TagBadge(tag: t, primary: primary))
                    .toList(),
              ),
            ],
            if (dish.allergens.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Row(
                children: [
                  Icon(
                    PhosphorIcons.warning(PhosphorIconsStyle.duotone),
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Alérgenos: ${dish.allergens.join(', ')}',
                    style: TextStyle(fontSize: 13, color: AppColors.warning),
                  ),
                ],
              ),
            ],
            if (dish.preparationTimeMin != null || dish.calories != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Row(
                children: [
                  if (dish.preparationTimeMin != null) ...[
                    Icon(
                      PhosphorIcons.clock(PhosphorIconsStyle.duotone),
                      size: 16,
                      color: textC.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${dish.preparationTimeMin} min',
                      style: TextStyle(
                        fontSize: 13,
                        color: textC.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (dish.calories != null) ...[
                    Icon(
                      PhosphorIcons.fire(PhosphorIconsStyle.fill),
                      size: 16,
                      color: textC.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${dish.calories} kcal',
                      style: TextStyle(
                        fontSize: 13,
                        color: textC.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Dish Grid Card
// =============================================================================

class _DishGridCard extends StatelessWidget {
  final Dish dish;
  final MenuDesign design;
  final Color cardColor;
  final Color textColor;
  final Color primary;
  final int index;

  const _DishGridCard({
    required this.dish,
    required this.design,
    required this.cardColor,
    required this.textColor,
    required this.primary,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusLg),
                  ),
                  child: dish.imageUrl != null
                      ? Image.network(
                          dish.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: primary.withValues(alpha: 0.08),
                          child: Icon(
                            PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
                            size: 36,
                            color: primary.withValues(alpha: 0.3),
                          ),
                        ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dish.name,
                        style: TextStyle(
                          fontFamily: design.fontFamily,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '€${dish.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontFamily: design.fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: index * 80),
          duration: 350.ms,
        )
        .slideY(
          begin: 0.05,
          delay: Duration(milliseconds: index * 80),
          duration: 350.ms,
        );
  }
}

// =============================================================================
// Tag Badge
// =============================================================================

class _TagBadge extends StatelessWidget {
  final String tag;
  final Color primary;

  const _TagBadge({required this.tag, required this.primary});

  static const _tagIcons = {
    'vegetarian': '🥬',
    'vegan': '🌱',
    'gluten_free': 'GF',
    'spicy': '🌶️',
    'organic': '🌿',
    'new': '🆕',
  };

  @override
  Widget build(BuildContext context) {
    final icon = _tagIcons[tag];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        icon != null ? '$icon $tag' : tag,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: primary,
        ),
      ),
    );
  }
}
