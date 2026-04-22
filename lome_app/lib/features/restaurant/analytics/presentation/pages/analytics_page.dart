import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../core/widgets/lome_empty_state.dart';
import '../../../../../core/widgets/lome_loading.dart';
import '../../../../../core/widgets/lome_section_header.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../../orders/presentation/providers/order_metrics_provider.dart';

/// Página de analíticas del restaurante con datos reales.
class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(orderMetricsProvider);
    final topAsync = ref.watch(topDishesProvider);
    final hourlyAsync = ref.watch(ordersByHourProvider);
    final filter = ref.watch(metricsFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(
        title: context.l10n.restaurantAnalyticsTitle,
        actions: [
          TactileWrapper(
            onTap: () {
              ref.invalidate(orderMetricsProvider);
              ref.invalidate(topDishesProvider);
              ref.invalidate(ordersByHourProvider);
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
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(orderMetricsProvider);
          ref.invalidate(topDishesProvider);
          ref.invalidate(ordersByHourProvider);
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Selector de período ──
              _PeriodSelector(current: filter.period),
              const SizedBox(height: AppTheme.spacingMd),

              // ── Hero + Stats grid ──
              metricsAsync.when(
                loading: () =>
                    const SizedBox(height: 200, child: LomeLoading()),
                error: (e, _) => Center(
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.grey700,
                    ),
                  ),
                ),
                data: (m) => Column(
                  children: [
                    // Hero revenue card (Revolut/Nubank style)
                    _HeroRevenueCard(
                      revenue: m.totalRevenue,
                      completedOrders: m.completedOrders,
                      totalOrders: m.totalOrders,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),

                    // Stats grid (without revenue — now in hero)
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _AnalyticsStatCard(
                          title: context.l10n.restaurantAnalyticsOrders,
                          value: '${m.totalOrders}',
                          subtitle: context.l10n.restaurantAnalyticsCancelled(
                            m.cancelledOrders,
                          ),
                          icon: PhosphorIcons.receipt(
                            PhosphorIconsStyle.duotone,
                          ),
                          iconColor: AppColors.info,
                          delay: 80,
                        ),
                        _AnalyticsStatCard(
                          title: context.l10n.restaurantAnalyticsAvgTicket,
                          value: '€${m.avgTicket.toStringAsFixed(2)}',
                          icon: PhosphorIcons.trendUp(
                            PhosphorIconsStyle.duotone,
                          ),
                          iconColor: AppColors.warning,
                          delay: 160,
                        ),
                        _AnalyticsStatCard(
                          title: context.l10n.restaurantAnalyticsPrepTime,
                          value:
                              '${m.avgPrepTimeMinutes.toStringAsFixed(0)} min',
                          icon: PhosphorIcons.timer(PhosphorIconsStyle.duotone),
                          iconColor: AppColors.primary,
                          delay: 240,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // ── Pedidos por hora ──
              LomeSectionHeader(
                title: context.l10n.restaurantAnalyticsOrdersByHour,
                icon: PhosphorIcons.chartBar(PhosphorIconsStyle.duotone),
                animationDelay: 200,
              ),
              const SizedBox(height: AppTheme.spacingMd),

              hourlyAsync.when(
                loading: () =>
                    const SizedBox(height: 180, child: LomeLoading()),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: AppShadows.card,
                  ),
                  child: Center(
                    child: Text(
                      'Error: $e',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.grey700,
                      ),
                    ),
                  ),
                ),
                data: (hours) => hours.isEmpty
                    ? LomeEmptyState(
                        icon: PhosphorIcons.chartBar(
                          PhosphorIconsStyle.duotone,
                        ),
                        title: context.l10n.restaurantAnalyticsNoData,
                      )
                    : _HourlyChart(data: hours)
                          .animate(delay: 260.ms)
                          .fadeIn(duration: AppTheme.durationFast)
                          .slideY(begin: 0.04, end: 0),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // ── Top platos ──
              LomeSectionHeader(
                title: context.l10n.restaurantAnalyticsTopDishes,
                icon: PhosphorIcons.trophy(PhosphorIconsStyle.duotone),
                animationDelay: 320,
              ),
              const SizedBox(height: AppTheme.spacingMd),

              topAsync.when(
                loading: () =>
                    const SizedBox(height: 180, child: LomeLoading()),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: AppShadows.card,
                  ),
                  child: Center(
                    child: Text(
                      'Error: $e',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.grey700,
                      ),
                    ),
                  ),
                ),
                data: (dishes) => dishes.isEmpty
                    ? LomeEmptyState(
                        icon: PhosphorIcons.forkKnife(
                          PhosphorIconsStyle.duotone,
                        ),
                        title: context.l10n.restaurantAnalyticsNoData,
                      )
                    : _TopDishesCard(dishes: dishes)
                          .animate(delay: 380.ms)
                          .fadeIn(duration: AppTheme.durationFast)
                          .slideY(begin: 0.04, end: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Hero Revenue Card (Revolut/Nubank gradient style)
// =============================================================================

class _HeroRevenueCard extends StatelessWidget {
  final double revenue;
  final int completedOrders;
  final int totalOrders;

  const _HeroRevenueCard({
    required this.revenue,
    required this.completedOrders,
    required this.totalOrders,
  });

  @override
  Widget build(BuildContext context) {
    final completionRate = totalOrders > 0
        ? (completedOrders / totalOrders * 100)
        : 0.0;

    return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    PhosphorIcons.currencyEur(PhosphorIconsStyle.duotone),
                    color: AppColors.white.withValues(alpha: 0.85),
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.restaurantAnalyticsRevenue,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                '€${revenue.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIcons.trendUp(PhosphorIconsStyle.duotone),
                          size: 14,
                          color: AppColors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${completionRate.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.restaurantAnalyticsCompleted(completedOrders),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: AppTheme.durationFast)
        .slideY(begin: 0.08, end: 0);
  }
}

// =============================================================================
// Period selector
// =============================================================================

class _PeriodSelector extends ConsumerWidget {
  final MetricsPeriod current;

  const _PeriodSelector({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const periods = [
      (MetricsPeriod.today, 'periodToday'),
      (MetricsPeriod.week, 'periodWeek'),
      (MetricsPeriod.month, 'periodMonth'),
      (MetricsPeriod.custom, 'periodCustom'),
    ];

    final periodLabels = {
      'periodToday': context.l10n.periodToday,
      'periodWeek': context.l10n.periodWeek,
      'periodMonth': context.l10n.periodMonth,
      'periodCustom': context.l10n.periodCustom,
    };

    return Row(
      children: periods.map((p) {
        final isActive = p.$1 == current;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: TactileWrapper(
              onTap: () async {
                if (p.$1 == MetricsPeriod.custom) {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now(),
                    locale: const Locale('es'),
                  );
                  if (range != null) {
                    ref
                        .read(metricsFilterProvider.notifier)
                        .state = MetricsFilter(
                      period: MetricsPeriod.custom,
                      customStart: range.start,
                      customEnd: range.end,
                    );
                  }
                } else {
                  ref.read(metricsFilterProvider.notifier).state =
                      MetricsFilter(period: p.$1);
                }
              },
              child: AnimatedContainer(
                duration: AppTheme.durationFast,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(
                    color: isActive ? AppColors.primary : AppColors.grey200,
                  ),
                ),
                child: Center(
                  child: Text(
                    periodLabels[p.$2]!,
                    style: TextStyle(
                      color: isActive ? AppColors.white : AppColors.grey600,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// =============================================================================
// Analytics stat card
// =============================================================================

class _AnalyticsStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final int delay;

  const _AnalyticsStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.subtitle,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.grey400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: AppTheme.durationFast)
        .slideY(begin: 0.1, end: 0);
  }
}

// =============================================================================
// Hourly chart (bar chart with CustomPaint)
// =============================================================================

class _HourlyChart extends StatelessWidget {
  final List<HourlyData> data;

  const _HourlyChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxCount = data.fold<int>(
      0,
      (m, d) => d.orderCount > m ? d.orderCount : m,
    );

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.length, (i) {
                final d = data[i];
                final ratio = maxCount > 0 ? d.orderCount / maxCount : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (d.orderCount > 0)
                          Text(
                            '${d.orderCount}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey700,
                            ),
                          ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                              duration: 400.ms,
                              height: (ratio * 120).clamp(2.0, 120.0),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15 + ratio * 0.7,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                              ),
                            )
                            .animate(
                              delay: Duration(milliseconds: 100 + i * 30),
                            )
                            .scaleY(
                              begin: 0,
                              end: 1,
                              duration: 400.ms,
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.bottomCenter,
                            ),
                        const SizedBox(height: 4),
                        Text(
                          '${d.hour}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Top dishes card
// =============================================================================

class _TopDishesCard extends StatelessWidget {
  final List<TopDish> dishes;

  const _TopDishesCard({required this.dishes});

  @override
  Widget build(BuildContext context) {
    final maxQty = dishes.fold<int>(
      0,
      (m, d) => d.totalQuantity > m ? d.totalQuantity : m,
    );
    final fmt = NumberFormat.currency(locale: 'es', symbol: '€');

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: List.generate(dishes.length, (i) {
          final dish = dishes[i];
          final ratio = maxQty > 0 ? dish.totalQuantity / maxQty : 0.0;

          return Padding(
                padding: EdgeInsets.only(top: i > 0 ? AppTheme.spacingSm : 0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: i < 3 ? AppColors.primary : AppColors.grey400,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dish.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.grey900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: ratio,
                              backgroundColor: AppColors.grey100,
                              color: AppColors.primary.withValues(alpha: 0.6),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          context.l10n.restaurantAnalyticsUnitsSold(
                            dish.totalQuantity,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.grey900,
                          ),
                        ),
                        Text(
                          fmt.format(dish.totalRevenue),
                          style: const TextStyle(
                            color: AppColors.grey500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
              .animate(delay: Duration(milliseconds: 200 + i * 60))
              .fadeIn(duration: AppTheme.durationFast)
              .slideY(begin: 0.04, end: 0);
        }),
      ),
    );
  }
}
