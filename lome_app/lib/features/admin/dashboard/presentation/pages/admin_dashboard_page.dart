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
import '../providers/admin_dashboard_provider.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminPlatformStatsProvider);
    final recentAsync = ref.watch(adminRecentRestaurantsProvider);
    final alerts = ref.watch(adminSystemAlertsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(context.l10n.adminDashboardTitle),
        actions: [
          TactileWrapper(
            onTap: () {
              ref.invalidate(adminPlatformStatsProvider);
              ref.invalidate(adminRecentRestaurantsProvider);
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
              Text(
                context.l10n.adminDashboardGeneralSummary,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                context.l10n.adminDashboardPlatformStatus,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.grey500,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // Stats principales
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppTheme.spacingMd,
                crossAxisSpacing: AppTheme.spacingMd,
                childAspectRatio: 1.4,
                children: [
                  LomeStatCard(
                    icon: PhosphorIcons.storefront(PhosphorIconsStyle.fill),
                    iconColor: AppColors.primary,
                    title: context.l10n.restaurants,
                    value: '${stats.activeTenants}',
                    subtitle: context.l10n.adminDashboardPendingCount(stats.pendingTenants),
                  ),
                  LomeStatCard(
                    icon: PhosphorIcons.users(PhosphorIconsStyle.fill),
                    iconColor: AppColors.info,
                    title: context.l10n.adminDashboardUsers,
                    value: _formatNumber(stats.totalUsers),
                    subtitle: context.l10n.adminDashboardActiveRegistered,
                  ),
                  LomeStatCard(
                    icon: PhosphorIcons.receipt(PhosphorIconsStyle.fill),
                    iconColor: AppColors.warning,
                    title: context.l10n.adminDashboardTodayOrders,
                    value: _formatNumber(stats.todayOrders),
                    subtitle: context.l10n.adminStatThisMonth(_formatNumber(stats.monthOrders)),
                  ),
                  LomeStatCard(
                    icon: PhosphorIcons.currencyEur(PhosphorIconsStyle.fill),
                    iconColor: AppColors.success,
                    title: context.l10n.adminDashboardMonthVolume,
                    value: _formatCurrency(stats.monthRevenue),
                    subtitle: context.l10n.adminStatToday(_formatCurrency(stats.todayRevenue)),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: AppTheme.spacingXl),

              // Restaurantes recientes
              Text(
                context.l10n.adminDashboardRecentRestaurants,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              recentAsync.when(
                loading: () => const LomeLoading(),
                error: (e, _) => Text('Error: $e'),
                data: (restaurants) => Column(
                  children: restaurants
                      .map((r) => _RecentRestaurantTile(restaurant: r))
                      .toList(),
                ),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // Alertas del sistema
              Text(
                context.l10n.adminDashboardSystemAlerts,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              ...alerts.map((alert) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppTheme.spacingSm),
                    child: _AlertCard(
                      icon: _alertIcon(alert.type),
                      color: _alertColor(alert.type),
                      title: alert.title,
                      subtitle: alert.subtitle,
                    ),
                  )),

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

  static IconData _alertIcon(String type) {
    switch (type) {
      case 'error':
        return PhosphorIcons.warningCircle(PhosphorIconsStyle.fill);
      case 'warning':
        return PhosphorIcons.warning(PhosphorIconsStyle.fill);
      case 'info':
        return PhosphorIcons.info(PhosphorIconsStyle.fill);
      default:
        return PhosphorIcons.checkCircle(PhosphorIconsStyle.fill);
    }
  }

  static Color _alertColor(String type) {
    switch (type) {
      case 'error':
        return AppColors.error;
      case 'warning':
        return AppColors.warning;
      case 'info':
        return AppColors.info;
      default:
        return AppColors.success;
    }
  }
}

class _RecentRestaurantTile extends StatelessWidget {
  const _RecentRestaurantTile({required this.restaurant});

  final AdminRestaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final statusLabel = _statusLabel(context, restaurant.status);
    final statusColor = _statusColor(restaurant.status);
    final dateStr = DateFormat('d MMM yyyy', 'es').format(restaurant.createdAt);

    return LomeCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryLight.withOpacity(0.2),
            child: Icon(
              PhosphorIcons.storefront(PhosphorIconsStyle.fill),
              color: AppColors.primary,
              size: 20,
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
                const SizedBox(height: 2),
                Text(
                  context.l10n.adminDashboardRegisteredInfo(dateStr, restaurant.totalOrders),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 11,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return LomeCard(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
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
