import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../domain/entities/table_occupancy_stat.dart';
import '../providers/table_stats_provider.dart';

/// Página de estadísticas de ocupación de mesas.
class TableStatsPage extends ConsumerWidget {
  const TableStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(tableOccupancyStatsProvider);
    final period = ref.watch(statsPeriodProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(title: context.l10n.tableStatsTitle),
      body: Column(
        children: [
          // Period filter pills
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              children: StatsPeriod.values.map((p) {
                final isSelected = p == period;
                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacingSm),
                  child: TactileWrapper(
                    onTap: () =>
                        ref.read(statsPeriodProvider.notifier).state = p,
                    child: AnimatedContainer(
                      duration: AppTheme.durationFast,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.white,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                        border: isSelected
                            ? null
                            : Border.all(color: AppColors.grey200),
                        boxShadow: isSelected ? AppShadows.card : null,
                      ),
                      child: Text(
                        p.label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.grey600,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (stats) {
                if (stats.isEmpty) {
                  return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.chartBar(
                                PhosphorIconsStyle.duotone,
                              ),
                              size: 64,
                              color: AppColors.grey200,
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            Text(
                              context.l10n.tableStatsNoData,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey400,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1, 1),
                      );
                }

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  children: [
                    _GlobalSummary(stats: stats),
                    const SizedBox(height: AppTheme.spacingLg),
                    Text(
                      context.l10n.tableStatsRanking,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey800,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    ...stats.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppTheme.spacingSm,
                        ),
                        child:
                            _TableStatTile(
                                  stat: entry.value,
                                  maxRevenue: stats.first.totalRevenue,
                                )
                                .animate()
                                .fadeIn(
                                  delay: Duration(
                                    milliseconds: 100 + entry.key * 60,
                                  ),
                                  duration: AppTheme.durationMedium,
                                )
                                .slideY(
                                  begin: 0.03,
                                  end: 0,
                                  delay: Duration(
                                    milliseconds: 100 + entry.key * 60,
                                  ),
                                ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Resumen global
// =============================================================================

class _GlobalSummary extends StatelessWidget {
  final List<TableOccupancyStat> stats;

  const _GlobalSummary({required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalRev = stats.fold<double>(0, (sum, s) => sum + s.totalRevenue);
    final totalSessions = stats.fold<int>(0, (sum, s) => sum + s.totalSessions);
    final totalOrders = stats.fold<int>(0, (sum, s) => sum + s.totalOrders);
    final avgTicket = totalOrders > 0 ? totalRev / totalOrders : 0.0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          title: context.l10n.tableStatsTotalRevenue,
          value: '${totalRev.toStringAsFixed(2)} €',
          icon: PhosphorIcons.currencyEur(PhosphorIconsStyle.duotone),
          iconColor: AppColors.success,
          delay: 0,
        ),
        _StatCard(
          title: context.l10n.tableStatsSessions,
          value: '$totalSessions',
          icon: PhosphorIcons.table(PhosphorIconsStyle.duotone),
          iconColor: AppColors.info,
          delay: 60,
        ),
        _StatCard(
          title: context.l10n.tableStatsOrders,
          value: '$totalOrders',
          icon: PhosphorIcons.receipt(PhosphorIconsStyle.duotone),
          iconColor: AppColors.warning,
          delay: 120,
        ),
        _StatCard(
          title: context.l10n.tableStatsAvgTicket,
          value: '${avgTicket.toStringAsFixed(2)} €',
          icon: PhosphorIcons.trendUp(PhosphorIconsStyle.duotone),
          iconColor: AppColors.primary,
          delay: 180,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final int delay;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
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
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
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
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.grey800,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: delay),
          duration: AppTheme.durationMedium,
        )
        .slideY(begin: 0.05, end: 0, delay: Duration(milliseconds: delay));
  }
}

// =============================================================================
// Tile de estadística por mesa
// =============================================================================

class _TableStatTile extends StatelessWidget {
  final TableOccupancyStat stat;
  final double maxRevenue;

  const _TableStatTile({required this.stat, required this.maxRevenue});

  @override
  Widget build(BuildContext context) {
    final revenueRatio = maxRevenue > 0 ? stat.totalRevenue / maxRevenue : 0.0;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  stat.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.grey800,
                  ),
                ),
              ),
              Text(
                '${stat.totalRevenue.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),

          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: revenueRatio,
              minHeight: 6,
              backgroundColor: AppColors.grey100,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),

          Row(
            children: [
              _StatDetail(
                icon: PhosphorIcons.receipt(),
                label: context.l10n.tableStatsOrderCount(stat.totalOrders),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              _StatDetail(
                icon: PhosphorIcons.timer(),
                label: stat.avgDurationFormatted,
              ),
              const SizedBox(width: AppTheme.spacingMd),
              _StatDetail(
                icon: PhosphorIcons.users(),
                label: context.l10n.tableStatsAvgGuests(
                  stat.avgGuests.toStringAsFixed(1),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              _StatDetail(
                icon: PhosphorIcons.tag(),
                label: context.l10n.tableStatsTicketAvg(
                  stat.avgTicket.toStringAsFixed(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatDetail extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatDetail({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.grey400),
        const SizedBox(width: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.grey500, fontSize: 11),
        ),
      ],
    );
  }
}
