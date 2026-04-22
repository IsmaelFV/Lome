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
import '../../domain/entities/table_entity.dart';
import '../../domain/entities/table_history_entry.dart';
import '../providers/table_history_provider.dart';
import '../providers/tables_provider.dart';

/// Página de historial de uso de una mesa.
class TableHistoryPage extends ConsumerWidget {
  final String tableId;

  const TableHistoryPage({super.key, required this.tableId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(tablesProvider).valueOrNull ?? [];
    final table = tables.where((t) => t.id == tableId).firstOrNull;
    final historyAsync = ref.watch(tableHistoryProvider(tableId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(
        title: context.l10n.tableHistoryTitle(
          table?.displayName ?? context.l10n.tablesTableSingular,
        ),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIcons.clockCounterClockwise(
                      PhosphorIconsStyle.duotone,
                    ),
                    size: 64,
                    color: AppColors.grey200,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    context.l10n.tableHistoryEmptyTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey400,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    context.l10n.tableHistoryEmptySubtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.grey400,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms);
          }

          return Column(
            children: [
              _SummaryBanner(entries: entries, table: table),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppTheme.spacingSm),
                  itemBuilder: (context, index) =>
                      _HistoryTile(entry: entries[index])
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: 60 * index),
                            duration: AppTheme.durationMedium,
                          )
                          .slideY(
                            begin: 0.03,
                            end: 0,
                            delay: Duration(milliseconds: 60 * index),
                          ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// Banner de resumen
// =============================================================================

class _SummaryBanner extends StatelessWidget {
  final List<TableHistoryEntry> entries;
  final TableEntity? table;

  const _SummaryBanner({required this.entries, this.table});

  @override
  Widget build(BuildContext context) {
    final totalRevenue = entries.fold<double>(0, (sum, e) => sum + e.total);
    final avgDuration = entries.isEmpty
        ? 0
        : entries.fold<int>(0, (sum, e) => sum + e.durationMinutes) ~/
              entries.length;
    final avgTicket = entries.isEmpty ? 0.0 : totalRevenue / entries.length;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _MiniStat(
            label: context.l10n.tableHistorySessions,
            value: '${entries.length}',
            icon: PhosphorIcons.receipt(),
          ),
          _MiniStat(
            label: context.l10n.tableHistoryRevenue,
            value: '${totalRevenue.toStringAsFixed(2)} €',
            icon: PhosphorIcons.currencyEur(),
          ),
          _MiniStat(
            label: context.l10n.tableHistoryAvgTicket,
            value: '${avgTicket.toStringAsFixed(2)} €',
            icon: PhosphorIcons.trendUp(),
          ),
          _MiniStat(
            label: context.l10n.tableHistoryAvgDuration,
            value: '${avgDuration}min',
            icon: PhosphorIcons.timer(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppTheme.durationMedium);
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: Colors.white.withAlpha(200)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Tile de entrada de historial
// =============================================================================

class _HistoryTile extends StatelessWidget {
  final TableHistoryEntry entry;

  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Center(
              child: Text(
                '#${entry.orderNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dateFmt.format(entry.openedAt.toLocal()),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.grey800,
                        ),
                      ),
                    ),
                    Text(
                      '${entry.total.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _InfoChip(
                      icon: PhosphorIcons.users(),
                      text: '${entry.guestsCount}',
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    _InfoChip(
                      icon: PhosphorIcons.timer(),
                      text: entry.durationFormatted,
                    ),
                    if (entry.waiterName != null) ...[
                      const SizedBox(width: AppTheme.spacingSm),
                      _InfoChip(
                        icon: PhosphorIcons.user(),
                        text: entry.waiterName!,
                      ),
                    ],
                    if (entry.paymentMethod != null) ...[
                      const SizedBox(width: AppTheme.spacingSm),
                      _InfoChip(
                        icon: PhosphorIcons.creditCard(),
                        text: entry.paymentMethod!,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.grey400),
        const SizedBox(width: 2),
        Text(
          text,
          style: const TextStyle(color: AppColors.grey500, fontSize: 11),
        ),
      ],
    );
  }
}
