import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_card.dart';
import '../../../../../core/widgets/lome_loading.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../../domain/entities/admin_entities.dart';
import '../providers/admin_analytics_provider.dart';

class AdminAnalyticsPage extends ConsumerWidget {
  const AdminAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminAnalyticsStatsProvider);
    final topAsync = ref.watch(adminTopRestaurantsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(context.l10n.adminAnalyticsTitle),
        actions: [
          TactileWrapper(
            onTap: () {
              ref.invalidate(adminAnalyticsStatsProvider);
              ref.invalidate(adminTopRestaurantsProvider);
            },
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              child: Icon(
                PhosphorIcons.arrowClockwise(PhosphorIconsStyle.duotone),
                color: AppColors.grey700,
              ),
            ),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const LomeLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPIs principales
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppTheme.spacingMd,
                crossAxisSpacing: AppTheme.spacingMd,
                childAspectRatio: 1.4,
                children: [
                  LomeStatCard(
                    icon: PhosphorIcons.currencyEur(PhosphorIconsStyle.fill),
                    iconColor: AppColors.success,
                    title: context.l10n.adminAnalyticsMonthRevenue,
                    value: _formatCurrency(stats.monthRevenue),
                    subtitle: context.l10n.adminStatToday(
                      _formatCurrency(stats.todayRevenue),
                    ),
                  ),
                  LomeStatCard(
                    icon: PhosphorIcons.receipt(PhosphorIconsStyle.fill),
                    iconColor: AppColors.primary,
                    title: context.l10n.adminAnalyticsMonthOrders,
                    value: _formatNumber(stats.monthOrders),
                    subtitle: context.l10n.adminStatToday(
                      _formatNumber(stats.todayOrders),
                    ),
                  ),
                  LomeStatCard(
                    icon: PhosphorIcons.storefront(PhosphorIconsStyle.fill),
                    iconColor: AppColors.info,
                    title: context.l10n.restaurants,
                    value: '${stats.activeTenants}',
                    subtitle: context.l10n.adminStatTotal(
                      '${stats.totalTenants}',
                    ),
                  ),
                  LomeStatCard(
                    icon: PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
                    iconColor: AppColors.warning,
                    title: context.l10n.adminAnalyticsActiveUsers,
                    value: _formatNumber(stats.totalUsers),
                    subtitle: context.l10n.adminAnalyticsAvgRating(
                      stats.avgPlatformRating.toStringAsFixed(1),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),

              const SizedBox(height: AppTheme.spacingXl),

              // Métricas de rendimiento
              Text(
                context.l10n.adminAnalyticsPlatformMetrics,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              LomeCard(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  children: [
                    _MetricRow(
                      label: context.l10n.adminAnalyticsOpenIncidents,
                      value: '${stats.openIncidents}',
                      icon: PhosphorIcons.warning(PhosphorIconsStyle.duotone),
                      color: stats.openIncidents > 5
                          ? AppColors.error
                          : AppColors.warning,
                    ),
                    const Divider(),
                    _MetricRow(
                      label: context.l10n.adminAnalyticsIncidentsInProgress,
                      value: '${stats.inProgressIncidents}',
                      icon: PhosphorIcons.spinner(PhosphorIconsStyle.duotone),
                      color: AppColors.info,
                    ),
                    const Divider(),
                    _MetricRow(
                      label: context.l10n.adminAnalyticsFlaggedReviews,
                      value: '${stats.flaggedReviews}',
                      icon: PhosphorIcons.flag(PhosphorIconsStyle.duotone),
                      color: AppColors.warning,
                    ),
                    const Divider(),
                    _MetricRow(
                      label: context.l10n.adminAnalyticsPendingRestaurants,
                      value: '${stats.pendingTenants}',
                      icon: PhosphorIcons.clock(PhosphorIconsStyle.duotone),
                      color: AppColors.warning,
                    ),
                    const Divider(),
                    _MetricRow(
                      label: context.l10n.adminAnalyticsSuspendedRestaurants,
                      value: '${stats.suspendedTenants}',
                      icon: PhosphorIcons.prohibit(PhosphorIconsStyle.duotone),
                      color: AppColors.error,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // Top restaurantes
              Text(
                context.l10n.adminAnalyticsTopRestaurants,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              topAsync.when(
                loading: () => const LomeLoading(),
                error: (e, _) => Text('Error: $e'),
                data: (restaurants) {
                  if (restaurants.isEmpty) {
                    return LomeCard(
                      padding: const EdgeInsets.all(AppTheme.spacingLg),
                      child: Center(
                        child: Text(
                          context.l10n.adminAnalyticsNoRestaurantData,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.grey500,
                          ),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: restaurants
                        .asMap()
                        .entries
                        .map(
                          (entry) => _TopRestaurantTile(
                            rank: entry.key + 1,
                            restaurant: entry.value,
                          ),
                        )
                        .toList(),
                  );
                },
              ),

              const SizedBox(height: AppTheme.spacingXl),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatNumber(int n) {
    if (n >= 1000) {
      return NumberFormat.compact(locale: 'es').format(n);
    }
    return n.toString();
  }

  static String _formatCurrency(double amount) {
    if (amount >= 1000) {
      return '€${NumberFormat.compact(locale: 'es').format(amount)}';
    }
    return '€${amount.toStringAsFixed(0)}';
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.grey600),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopRestaurantTile extends StatelessWidget {
  const _TopRestaurantTile({required this.rank, required this.restaurant});

  final int rank;
  final TopRestaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return LomeCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? AppColors.primaryLight.withOpacity(0.2)
                  : AppColors.grey100,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? AppColors.primary : AppColors.grey600,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
                  ),
                ),
                if (restaurant.city != null)
                  Text(
                    restaurant.city!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey500,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '€${restaurant.totalRevenue.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIcons.star(PhosphorIconsStyle.fill),
                    size: 12,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    restaurant.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.adminRestaurantsOrderCount(
                      restaurant.totalOrders,
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
