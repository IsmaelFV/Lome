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
import '../../../domain/entities/marketplace_entities.dart';
import '../providers/favorites_provider.dart';

/// Página de restaurantes favoritos del cliente.
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favAsync = ref.watch(favoriteRestaurantsProvider);

    return Scaffold(
      appBar: LomeAppBar(
        title: context.l10n.marketplaceFavoritesTitle,
        showBack: true,
      ),
      body: favAsync.when(
        loading: () => const LomeLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (restaurants) {
          if (restaurants.isEmpty) {
            return LomeEmptyState(
              icon: PhosphorIcons.heart(PhosphorIconsStyle.duotone),
              title: context.l10n.marketplaceFavoritesEmpty,
              subtitle: context.l10n.marketplaceFavoritesEmptySubtitle,
            );
          }
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            itemCount: restaurants.length,
            itemBuilder: (context, index) =>
                _FavoriteCard(restaurant: restaurants[index])
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: index * 60),
                      duration: 300.ms,
                    )
                    .slideX(begin: -0.05, end: 0),
          );
        },
      ),
    );
  }
}

class _FavoriteCard extends ConsumerWidget {
  final MarketplaceRestaurant restaurant;

  const _FavoriteCard({required this.restaurant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TactileWrapper(
      onTap: () => context.pushNamed(
        RouteNames.restaurantDetail,
        pathParameters: {'id': restaurant.id},
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                image: restaurant.logoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(restaurant.logoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: restaurant.logoUrl == null
                  ? Icon(
                      PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
                      color: AppColors.grey400,
                      size: 28,
                    )
                  : null,
            ),
            const SizedBox(width: AppTheme.spacingMd),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    restaurant.cuisineLabel,
                    style: TextStyle(fontSize: 12, color: AppColors.grey500),
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
                              size: 12,
                              color: AppColors.accentDark,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              restaurant.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        PhosphorIcons.clock(PhosphorIconsStyle.duotone),
                        size: 13,
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

            // Remove favorite
            TactileWrapper(
              onTap: () => ref.read(toggleFavoriteProvider(restaurant.id)),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIcons.heart(PhosphorIconsStyle.fill),
                  color: AppColors.error,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
