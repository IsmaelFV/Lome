import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/auth/permission_guard.dart';
import '../../../../../core/auth/app_permission.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/animated_counter.dart';
import '../../../../../core/widgets/lome_loading.dart';
import '../../../../../core/widgets/lome_section_header.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../../presentation/providers/restaurant_status_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../notifications/presentation/widgets/notifications_panel.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../providers/dashboard_provider.dart';

/// Dashboard principal del restaurante.
///
/// Primera pantalla que ve el administrador o empleado al entrar.
/// Diseño inspirado en Nubank (hero card + datos limpios),
/// BMW (accesos rápidos grid), Revolut (contadores animados).
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashState = ref.watch(dashboardProvider);
    final stats = dashState.stats;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: dashState.isLoading
          ? LomeSkeleton.kpiGrid()
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(dashboardProvider.notifier).loadStats(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // ── App Bar minimalista ──
                  SliverAppBar(
                    expandedHeight: 0,
                    floating: true,
                    pinned: true,
                    elevation: 0,
                    scrolledUnderElevation: 0.5,
                    backgroundColor: AppColors.backgroundLight,
                    leading: IconButton(
                      icon: Icon(
                        PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
                        size: 20,
                        color: AppColors.grey700,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    title: Text(
                      context.l10n.restaurantDashboardTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey900,
                      ),
                    ),
                    actions: [
                      Consumer(
                        builder: (context, ref, _) {
                          final unread = ref.watch(
                            unreadNotificationsCountProvider,
                          );
                          return Stack(
                            children: [
                              TactileWrapper(
                                onTap: () => NotificationsPanel.show(context),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    AppTheme.spacingSm,
                                  ),
                                  child: Icon(
                                    PhosphorIcons.bell(
                                      PhosphorIconsStyle.duotone,
                                    ),
                                    color: AppColors.grey600,
                                  ),
                                ),
                              ),
                              if (unread > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.backgroundLight,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        unread > 9 ? '9+' : '$unread',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      TactileWrapper(
                        onTap: () =>
                            ref.read(dashboardProvider.notifier).loadStats(),
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingSm),
                          child: Icon(
                            PhosphorIcons.arrowClockwise(
                              PhosphorIconsStyle.duotone,
                            ),
                            color: AppColors.grey600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Error ──
                  if (dashState.errorMessage != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMd,
                        ),
                        child: _ErrorBanner(message: dashState.errorMessage!)
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .shakeX(hz: 3, amount: 4, duration: 400.ms),
                      ),
                    ),

                  // ── Hero Revenue Card (Nubank-style) ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spacingMd,
                        AppTheme.spacingSm,
                        AppTheme.spacingMd,
                        AppTheme.spacingMd,
                      ),
                      child: _HeroRevenueCard(stats: stats)
                          .animate()
                          .fadeIn(duration: AppTheme.durationMedium)
                          .slideY(
                            begin: 0.04,
                            end: 0,
                            curve: AppTheme.curveSlideIn,
                          ),
                    ),
                  ),

                  // ── KPI Cards (grid 2×2) ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                      ),
                      child: _buildKpiGrid(context, stats),
                    ),
                  ),

                  // ── Alertas ──
                  if (stats.alerts.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: LomeSectionHeader(
                        title: context.l10n.dashboardAlerts,
                        icon: PhosphorIcons.warning(PhosphorIconsStyle.duotone),
                        animationDelay: 300,
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                        vertical: AppTheme.spacingXs,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTheme.spacingSm,
                            ),
                            child: _AlertCard(alert: stats.alerts[index])
                                .animate()
                                .fadeIn(
                                  delay: Duration(
                                    milliseconds: 350 + index * 60,
                                  ),
                                  duration: AppTheme.durationMedium,
                                )
                                .slideX(
                                  begin: 0.03,
                                  end: 0,
                                  delay: Duration(
                                    milliseconds: 350 + index * 60,
                                  ),
                                ),
                          ),
                          childCount: stats.alerts.length,
                        ),
                      ),
                    ),
                  ],

                  // ── Platos más vendidos ──
                  if (stats.topSelling.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LomeSectionHeader(
                            title: context.l10n.dashboardTopSellingToday,
                            icon: PhosphorIcons.fire(
                              PhosphorIconsStyle.duotone,
                            ),
                            animationDelay: 450,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingMd,
                            ),
                            child: _TopSellingList(items: stats.topSelling)
                                .animate()
                                .fadeIn(
                                  delay: 500.ms,
                                  duration: AppTheme.durationMedium,
                                ),
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                        ],
                      ),
                    ),

                  // ── Stock bajo (solo con permiso de inventario) ──
                  if (stats.lowStockItems.isNotEmpty)
                    SliverToBoxAdapter(
                      child: PermissionGuard(
                        permission: AppPermission.viewInventory,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LomeSectionHeader(
                              title: context.l10n.dashboardLowStock,
                              icon: PhosphorIcons.package(
                                PhosphorIconsStyle.duotone,
                              ),
                              animationDelay: 600,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingMd,
                              ),
                              child: _LowStockList(items: stats.lowStockItems)
                                  .animate()
                                  .fadeIn(
                                    delay: 650.ms,
                                    duration: AppTheme.durationMedium,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Accesos rápidos (BMW-style grid) ──
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppTheme.spacingSm),
                        LomeSectionHeader(
                          title: context.l10n.restaurantDashboardQuickActions,
                          icon: PhosphorIcons.lightning(
                            PhosphorIconsStyle.duotone,
                          ),
                          animationDelay: 750,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMd,
                          ),
                          child: _QuickActionsGrid().animate().fadeIn(
                            delay: 800.ms,
                            duration: AppTheme.durationMedium,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXxl),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, DashboardStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppTheme.spacingSm,
      crossAxisSpacing: AppTheme.spacingSm,
      childAspectRatio: 1.55,
      children: [
        _KpiCard(
          title: context.l10n.restaurantDashboardActiveOrders,
          value: stats.activeOrders.toString(),
          icon: PhosphorIcons.receipt(PhosphorIconsStyle.duotone),
          color: AppColors.info,
          subtitle: context.l10n.dashboardPendingCount(stats.pendingOrders),
          delay: 100,
        ),
        _KpiCard(
          title: context.l10n.restaurantDashboardOccupiedTables,
          value: '${stats.occupiedTables}/${stats.totalTables}',
          icon: PhosphorIcons.gridFour(PhosphorIconsStyle.duotone),
          color: AppColors.warning,
          subtitle: context.l10n.dashboardOccupancyPercent(
            stats.occupancyRate.toStringAsFixed(0),
          ),
          delay: 180,
        ),
        _KpiCard(
          title: context.l10n.dashboardLowStock,
          value: stats.lowStockItems.length.toString(),
          icon: PhosphorIcons.package(PhosphorIconsStyle.duotone),
          color: stats.lowStockItems.isNotEmpty
              ? AppColors.error
              : AppColors.success,
          subtitle: stats.lowStockItems.isEmpty
              ? context.l10n.dashboardAllOk
              : context.l10n.dashboardIngredients,
          delay: 260,
        ),
        _KpiCard(
          title: context.l10n.dashboardTopSellingToday,
          value: stats.topSelling.isNotEmpty
              ? stats.topSelling.first.name
              : '—',
          icon: PhosphorIcons.fire(PhosphorIconsStyle.duotone),
          color: AppColors.accent,
          isText: true,
          delay: 340,
        ),
      ],
    );
  }
}

// =============================================================================
// Hero Revenue Card — Nubank/Revolut-style hero con revenue grande
// =============================================================================

class _HeroRevenueCard extends ConsumerWidget {
  final DashboardStats stats;

  const _HeroRevenueCard({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusState = ref.watch(restaurantStatusProvider);
    final status = statusState.status;

    final (Color statusColor, IconData statusIcon) = switch (status) {
      OperationalStatus.open => (
        AppColors.primaryLight,
        PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
      ),
      OperationalStatus.closed => (
        AppColors.grey300,
        PhosphorIcons.prohibit(PhosphorIconsStyle.fill),
      ),
      OperationalStatus.temporarilyClosed => (
        AppColors.warning,
        PhosphorIcons.pauseCircle(PhosphorIconsStyle.fill),
      ),
    };

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status pill + refresh
          Row(
            children: [
              TactileWrapper(
                onTap: () => _showStatusMenu(context, ref, status),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        status.label,
                        style: AppTypography.badge(color: AppColors.white),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        PhosphorIcons.caretDown(),
                        size: 12,
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // Revenue label
          Text(
            context.l10n.restaurantDashboardTodayRevenue,
            style: AppTypography.sectionLabel(
              color: AppColors.white.withValues(alpha: 0.8),
            ),
          ),

          const SizedBox(height: AppTheme.spacingXs),

          // Revenue big number (Revolut-style animated counter)
          AnimatedCounter(
            end: stats.salesToday,
            formatter: (v) => '€${v.toStringAsFixed(2)}',
            style: AppTypography.stat(size: 36, color: AppColors.white),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Quick stats row at bottom
          Row(
            children: [
              _HeroMiniStat(
                icon: PhosphorIcons.receipt(),
                label: '${stats.activeOrders}',
                sublabel: context.l10n.orders,
              ),
              const SizedBox(width: AppTheme.spacingLg),
              _HeroMiniStat(
                icon: PhosphorIcons.gridFour(),
                label: '${stats.occupiedTables}/${stats.totalTables}',
                sublabel: context.l10n.tables,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStatusMenu(
    BuildContext context,
    WidgetRef ref,
    OperationalStatus currentStatus,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppTheme.spacingSm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ...OperationalStatus.values.map((s) {
              final isSelected = s == currentStatus;
              final itemIcon = switch (s) {
                OperationalStatus.open => PhosphorIcons.checkCircle(
                  PhosphorIconsStyle.fill,
                ),
                OperationalStatus.closed => PhosphorIcons.prohibit(
                  PhosphorIconsStyle.fill,
                ),
                OperationalStatus.temporarilyClosed =>
                  PhosphorIcons.pauseCircle(PhosphorIconsStyle.fill),
              };
              return ListTile(
                leading: Icon(
                  itemIcon,
                  color: isSelected ? AppColors.primary : AppColors.grey400,
                ),
                title: Text(
                  s.label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.primary : AppColors.grey700,
                  ),
                ),
                trailing: isSelected
                    ? Icon(PhosphorIcons.check(), color: AppColors.primary)
                    : null,
                onTap: () {
                  ref.read(restaurantStatusProvider.notifier).setStatus(s);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: AppTheme.spacingMd),
          ],
        ),
      ),
    );
  }
}

class _HeroMiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;

  const _HeroMiniStat({
    required this.icon,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.white.withValues(alpha: 0.8)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          sublabel,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// KPI Card — Mejorado con counter animation y shadow system
// =============================================================================

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final int delay;
  final bool isText;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.delay = 0,
    this.isText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppShadows.card,
            border: Border.all(color: AppColors.grey100, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.grey500,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (isText)
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              else
                AnimatedSwitcher(
                  duration: AppTheme.durationMedium,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Text(
                    value,
                    key: ValueKey(value),
                    style: AppTypography.stat(size: 22),
                  ),
                ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: delay),
          duration: AppTheme.durationSlow,
        )
        .slideY(
          begin: 0.06,
          end: 0,
          delay: Duration(milliseconds: delay),
          curve: AppTheme.curveSlideIn,
        );
  }
}

// =============================================================================
// Alert card — Mas limpio con icono y borde sutil
// =============================================================================

class _AlertCard extends StatelessWidget {
  final RecentAlert alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.type) {
      AlertType.error => AppColors.error,
      AlertType.warning => AppColors.warning,
      AlertType.info => AppColors.info,
    };
    final icon = switch (alert.type) {
      AlertType.error => PhosphorIcons.warningCircle(
        PhosphorIconsStyle.duotone,
      ),
      AlertType.warning => PhosphorIcons.warning(PhosphorIconsStyle.duotone),
      AlertType.info => PhosphorIcons.info(PhosphorIconsStyle.duotone),
    };

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey600,
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

// =============================================================================
// Top selling list — Mejorado con ranking visual
// =============================================================================

class _TopSellingList extends StatelessWidget {
  final List<TopSellingItem> items;

  const _TopSellingList({required this.items});

  @override
  Widget build(BuildContext context) {
    final maxQty = items.isNotEmpty ? items.first.quantity : 1;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final progress = maxQty > 0 ? item.quantity / maxQty : 0.0;
          final isTop3 = index < 3;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index < items.length - 1 ? AppTheme.spacingSm + 2 : 0,
            ),
            child: Row(
              children: [
                // Ranking badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isTop3
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isTop3 ? AppColors.primary : AppColors.grey400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.grey900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.grey100,
                          color: AppColors.primary.withValues(
                            alpha: 1.0 - (index * 0.12).clamp(0.0, 0.6),
                          ),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text('${item.quantity}', style: AppTypography.stat(size: 16)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// Low stock list — Mejorado con indicador de urgencia
// =============================================================================

class _LowStockList extends StatelessWidget {
  final List<LowStockItem> items;

  const _LowStockList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final pct = item.stockPercentage.clamp(0, 100);
          final color = pct < 25
              ? AppColors.error
              : pct < 50
              ? AppColors.warning
              : AppColors.success;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index < items.length - 1 ? AppTheme.spacingSm + 2 : 0,
            ),
            child: Row(
              children: [
                // Status dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${item.currentStock.toStringAsFixed(1)}/${item.minimumStock.toStringAsFixed(1)} ${item.unit}',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// Quick actions — BMW-style grid con iconos redondos
// =============================================================================

class _QuickActionsGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: AppTheme.spacingMd,
      runSpacing: AppTheme.spacingMd,
      children: [
        _QuickActionButton(
          label: context.l10n.dashboardEmployees,
          icon: PhosphorIcons.users(PhosphorIconsStyle.duotone),
          color: AppColors.info,
          onTap: () => context.push(RoutePaths.employees),
          delay: 0,
        ),
        PermissionGuard(
          permission: AppPermission.viewAnalytics,
          child: _QuickActionButton(
            label: context.l10n.analytics,
            icon: PhosphorIcons.chartBar(PhosphorIconsStyle.duotone),
            color: AppColors.success,
            onTap: () => context.push(RoutePaths.analytics),
            delay: 60,
          ),
        ),
        PermissionGuard(
          permission: AppPermission.manageSettings,
          child: _QuickActionButton(
            label: context.l10n.settings,
            icon: PhosphorIcons.gear(PhosphorIconsStyle.duotone),
            color: AppColors.grey500,
            onTap: () => context.push(RoutePaths.settings),
            delay: 120,
          ),
        ),
        PermissionGuard(
          permission: AppPermission.manageEmployees,
          child: _QuickActionButton(
            label: context.l10n.dashboardInvite,
            icon: PhosphorIcons.userPlus(PhosphorIconsStyle.duotone),
            color: AppColors.primary,
            onTap: () => context.push(RoutePaths.inviteEmployee),
            delay: 180,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TactileWrapper(
          onTap: onTap,
          child: SizedBox(
            width: 72,
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 800 + delay),
          duration: AppTheme.durationMedium,
        )
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          delay: Duration(milliseconds: 800 + delay),
          curve: AppTheme.curveSpring,
        );
  }
}

// =============================================================================
// Error banner
// =============================================================================

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border(left: BorderSide(color: AppColors.error, width: 3)),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.warningCircle(PhosphorIconsStyle.duotone),
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
