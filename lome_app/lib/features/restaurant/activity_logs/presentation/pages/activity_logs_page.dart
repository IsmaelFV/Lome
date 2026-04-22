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
import '../providers/activity_logs_provider.dart';

/// Filtros de entidad para los logs.
const _entityFilterKeys = <String>[
  'order',
  'menu_item',
  'inventory',
  'table',
  'employee',
  'settings',
];

String _entityFilterLabel(BuildContext context, String key) {
  final l10n = context.l10n;
  return switch (key) {
    'order' => l10n.activityLogsFilterOrders,
    'menu_item' => l10n.activityLogsFilterMenu,
    'inventory' => l10n.activityLogsFilterInventory,
    'table' => l10n.activityLogsFilterTables,
    'employee' => l10n.activityLogsFilterTeam,
    'settings' => l10n.activityLogsFilterSettings,
    _ => key,
  };
}

/// Página de logs de actividad del restaurante.
class ActivityLogsPage extends ConsumerWidget {
  const ActivityLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsState = ref.watch(activityLogsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(title: context.l10n.activityLogsTitle),
      body: Column(
        children: [
          // Filter pills
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacingSm),
                  child: _FilterPill(
                    label: context.l10n.activityLogsFilterAll,
                    isSelected: logsState.filterEntity == null,
                    onTap: () =>
                        ref.read(activityLogsProvider.notifier).setFilter(null),
                  ),
                ),
                ..._entityFilterKeys.map((key) {
                  final selected = logsState.filterEntity == key;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppTheme.spacingSm),
                    child: _FilterPill(
                      label: _entityFilterLabel(context, key),
                      isSelected: selected,
                      onTap: () => ref
                          .read(activityLogsProvider.notifier)
                          .setFilter(selected ? null : key),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingXs),

          Expanded(
            child: logsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : logsState.logs.isEmpty
                ? _EmptyLogs()
                : NotificationListener<ScrollNotification>(
                    onNotification: (scroll) {
                      if (scroll.metrics.pixels >=
                          scroll.metrics.maxScrollExtent - 200) {
                        ref.read(activityLogsProvider.notifier).loadMore();
                      }
                      return false;
                    },
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () =>
                          ref.read(activityLogsProvider.notifier).loadLogs(),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMd,
                        ),
                        itemCount:
                            logsState.logs.length +
                            (logsState.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= logsState.logs.length) {
                            return const Padding(
                              padding: EdgeInsets.all(AppTheme.spacingMd),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final log = logsState.logs[index];
                          final showDate =
                              index == 0 ||
                              !_sameDay(
                                logsState.logs[index - 1].createdAt,
                                log.createdAt,
                              );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showDate)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppTheme.spacingMd,
                                    bottom: AppTheme.spacingSm,
                                  ),
                                  child: Text(
                                    _formatDate(context, log.createdAt),
                                    style: const TextStyle(
                                      color: AppColors.grey500,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              _LogTile(log: log).animate().fadeIn(
                                delay: Duration(
                                  milliseconds: 40 * (index % 10),
                                ),
                                duration: 200.ms,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(BuildContext context, DateTime d) {
    final now = DateTime.now();
    if (_sameDay(d, now)) return context.l10n.today;
    if (_sameDay(d, now.subtract(const Duration(days: 1))))
      return context.l10n.yesterday;
    return '${d.day}/${d.month}/${d.year}';
  }
}

// =============================================================================
// Filter pill
// =============================================================================

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TactileWrapper(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: isSelected ? null : Border.all(color: AppColors.grey200),
          boxShadow: isSelected ? AppShadows.card : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.grey600,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Log tile
// =============================================================================

class _LogTile extends StatelessWidget {
  final ActivityLog log;

  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final color = _colorForEntity(log.entityType);
    final icon = _iconForEntity(log.entityType);
    final time =
        '${log.createdAt.hour.toString().padLeft(2, '0')}:${log.createdAt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingSm),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.actionLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.grey800,
                    ),
                  ),
                  Row(
                    children: [
                      if (log.userName != null) ...[
                        Text(
                          log.userName!,
                          style: const TextStyle(
                            color: AppColors.grey500,
                            fontSize: 12,
                          ),
                        ),
                        const Text(
                          ' · ',
                          style: TextStyle(
                            color: AppColors.grey300,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      Text(
                        log.entityLabel,
                        style: const TextStyle(
                          color: AppColors.grey400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: const TextStyle(color: AppColors.grey400, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForEntity(String entity) {
    return switch (entity) {
      'order' => PhosphorIcons.receipt(PhosphorIconsStyle.duotone),
      'menu_item' => PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
      'inventory' => PhosphorIcons.package(PhosphorIconsStyle.duotone),
      'table' => PhosphorIcons.table(PhosphorIconsStyle.duotone),
      'employee' => PhosphorIcons.users(PhosphorIconsStyle.duotone),
      'role' => PhosphorIcons.identificationBadge(PhosphorIconsStyle.duotone),
      'settings' => PhosphorIcons.gear(PhosphorIconsStyle.duotone),
      'hours' => PhosphorIcons.clock(PhosphorIconsStyle.duotone),
      _ => PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.duotone),
    };
  }

  Color _colorForEntity(String entity) {
    return switch (entity) {
      'order' => AppColors.info,
      'menu_item' => AppColors.primary,
      'inventory' => AppColors.warning,
      'table' => AppColors.success,
      'employee' => AppColors.primaryDark,
      _ => AppColors.grey600,
    };
  }
}

// =============================================================================
// Empty
// =============================================================================

class _EmptyLogs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.duotone),
            size: 48,
            color: AppColors.grey200,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            context.l10n.activityLogsEmpty,
            style: const TextStyle(fontSize: 14, color: AppColors.grey400),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
