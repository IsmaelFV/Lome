import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_button.dart';
import '../../../../../core/widgets/lome_card.dart';
import '../../../../../core/widgets/lome_loading.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../../domain/entities/admin_entities.dart';
import '../providers/admin_restaurants_provider.dart';

class AdminRestaurantDetailPage extends ConsumerWidget {
  const AdminRestaurantDetailPage({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(adminRestaurantDetailProvider(restaurantId));
    final statsAsync = ref.watch(adminRestaurantStatsProvider(restaurantId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(context.l10n.adminRestaurantDetailTitle),
        actions: [
          TactileWrapper(
            onTap: () {
              ref.invalidate(adminRestaurantDetailProvider(restaurantId));
              ref.invalidate(adminRestaurantStatsProvider(restaurantId));
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
      body: detailAsync.when(
        loading: () => const LomeLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (restaurant) {
          if (restaurant == null) {
            return Center(
              child: Text(context.l10n.adminRestaurantDetailNotFound),
            );
          }
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderSection(restaurant: restaurant, ref: ref),
                const SizedBox(height: AppTheme.spacingLg),
                _StatsSection(statsAsync: statsAsync),
                const SizedBox(height: AppTheme.spacingLg),
                _InfoSection(restaurant: restaurant),
                const SizedBox(height: AppTheme.spacingLg),
                _ActionsSection(restaurant: restaurant, ref: ref),
                const SizedBox(height: AppTheme.spacingXl),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Header Section ──────────────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.restaurant, required this.ref});

  final AdminRestaurant restaurant;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(restaurant.status);
    final dateStr = DateFormat('d MMM yyyy', 'es').format(restaurant.createdAt);

    return LomeCard(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primaryLight.withOpacity(0.2),
            backgroundImage: restaurant.logoUrl != null
                ? NetworkImage(restaurant.logoUrl!)
                : null,
            child: restaurant.logoUrl == null
                ? Text(
                    restaurant.name.isNotEmpty ? restaurant.name[0] : '?',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            restaurant.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.grey900,
            ),
            textAlign: TextAlign.center,
          ),
          if (restaurant.city != null) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
                  size: 16,
                  color: AppColors.grey500,
                ),
                const SizedBox(width: 4),
                Text(
                  restaurant.city!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  _statusLabel(context, restaurant.status),
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (restaurant.subscriptionPlan != null) ...[
                const SizedBox(width: AppTheme.spacingSm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    restaurant.subscriptionPlan!.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            context.l10n.adminRestaurantDetailRegistered(dateStr),
            style: const TextStyle(fontSize: 12, color: AppColors.grey400),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (restaurant.rating > 0) ...[
                Icon(
                  PhosphorIcons.star(PhosphorIconsStyle.fill),
                  size: 18,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  '${restaurant.rating.toStringAsFixed(1)} (${restaurant.totalReviews})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  static String _statusLabel(BuildContext context, String status) {
    switch (status) {
      case 'active':
        return context.l10n.active;
      case 'pending':
        return context.l10n.statusPending;
      case 'suspended':
        return context.l10n.statusSuspended;
      default:
        return status;
    }
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'suspended':
        return AppColors.error;
      default:
        return AppColors.grey500;
    }
  }
}

// ─── Stats Section ───────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.statsAsync});

  final AsyncValue<AdminRestaurantStats> statsAsync;

  @override
  Widget build(BuildContext context) {
    return statsAsync.when(
      loading: () => const LomeLoading(),
      error: (e, _) => Text(context.l10n.adminRestaurantDetailStatsError),
      data: (stats) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.adminRestaurantDetailStatistics,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppTheme.spacingMd,
            crossAxisSpacing: AppTheme.spacingMd,
            childAspectRatio: 1.4,
            children: [
              LomeStatCard(
                icon: PhosphorIcons.receipt(PhosphorIconsStyle.fill),
                iconColor: AppColors.primary,
                title: context.l10n.adminRestaurantDetailTotalOrders,
                value: '${stats.totalOrders}',
                subtitle: context.l10n.adminStatThisMonth(
                  '${stats.monthOrders}',
                ),
              ),
              LomeStatCard(
                icon: PhosphorIcons.currencyEur(PhosphorIconsStyle.fill),
                iconColor: AppColors.success,
                title: context.l10n.adminAnalyticsTotalRevenue,
                value: _formatCurrency(stats.totalRevenue),
                subtitle: context.l10n.adminStatThisMonth(
                  _formatCurrency(stats.monthRevenue),
                ),
              ),
              LomeStatCard(
                icon: PhosphorIcons.users(PhosphorIconsStyle.fill),
                iconColor: AppColors.info,
                title: context.l10n.adminRestaurantDetailEmployees,
                value: '${stats.totalEmployees}',
                subtitle: context.l10n.adminRestaurantDetailMenuItems(
                  stats.totalMenuItems,
                ),
              ),
              LomeStatCard(
                icon: PhosphorIcons.star(PhosphorIconsStyle.fill),
                iconColor: AppColors.warning,
                title: context.l10n.adminRestaurantDetailRating,
                value: stats.avgRating.toStringAsFixed(1),
                subtitle: context.l10n.adminRestaurantDetailReviewCount(
                  stats.totalReviews,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          if (stats.openIncidents > 0) ...[
            const SizedBox(height: AppTheme.spacingMd),
            LomeCard(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.warning(PhosphorIconsStyle.fill),
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    context.l10n.adminRestaurantDetailOpenIncidents(
                      stats.openIncidents,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatCurrency(double amount) {
    if (amount >= 1000) {
      return '€${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '€${amount.toStringAsFixed(0)}';
  }
}

// ─── Info Section ────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.restaurant});

  final AdminRestaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.adminRestaurantDetailTabInfo,
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
              if (restaurant.email != null)
                _InfoRow(
                  icon: PhosphorIcons.envelope(PhosphorIconsStyle.duotone),
                  label: context.l10n.adminRestaurantDetailEmail,
                  value: restaurant.email!,
                ),
              if (restaurant.phone != null) ...[
                const Divider(),
                _InfoRow(
                  icon: PhosphorIcons.phone(PhosphorIconsStyle.duotone),
                  label: context.l10n.adminRestaurantDetailPhone,
                  value: restaurant.phone!,
                ),
              ],
              if (restaurant.cuisineType.isNotEmpty) ...[
                const Divider(),
                _InfoRow(
                  icon: PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
                  label: context.l10n.adminRestaurantDetailCuisine,
                  value: restaurant.cuisineType.join(', '),
                ),
              ],
              if (restaurant.description != null) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingSm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        PhosphorIcons.textAa(PhosphorIconsStyle.duotone),
                        size: 18,
                        color: AppColors.grey500,
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: Text(
                          restaurant.description!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.grey600,
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
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.grey500),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.grey400,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Actions Section ─────────────────────────────────────────────────────────

class _ActionsSection extends StatelessWidget {
  const _ActionsSection({required this.restaurant, required this.ref});

  final AdminRestaurant restaurant;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.actions,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.grey900,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        if (restaurant.status == 'pending')
          LomeButton(
            label: context.l10n.adminRestaurantDetailApproveRestaurant,
            variant: LomeButtonVariant.primary,
            onPressed: () => _toggleStatus(context, 'active'),
            icon: PhosphorIcons.check(PhosphorIconsStyle.duotone),
            isExpanded: true,
          ),
        if (restaurant.status == 'active') ...[
          LomeButton(
            label: context.l10n.adminRestaurantDetailSuspendRestaurant,
            variant: LomeButtonVariant.danger,
            onPressed: () => _toggleStatus(context, 'suspended'),
            icon: PhosphorIcons.prohibit(PhosphorIconsStyle.duotone),
            isExpanded: true,
          ),
        ],
        if (restaurant.status == 'suspended') ...[
          LomeButton(
            label: context.l10n.adminRestaurantDetailReactivateRestaurant,
            variant: LomeButtonVariant.primary,
            onPressed: () => _toggleStatus(context, 'active'),
            icon: PhosphorIcons.arrowClockwise(PhosphorIconsStyle.duotone),
            isExpanded: true,
          ),
        ],
      ],
    );
  }

  void _toggleStatus(BuildContext context, String newStatus) {
    ref.read(
      toggleRestaurantStatusProvider((id: restaurant.id, newStatus: newStatus)),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.adminRestaurantDetailStatusUpdated(newStatus),
        ),
      ),
    );
  }
}
