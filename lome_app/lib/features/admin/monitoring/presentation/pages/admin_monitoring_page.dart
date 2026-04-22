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
import '../providers/admin_monitoring_provider.dart';

class AdminMonitoringPage extends ConsumerWidget {
  const AdminMonitoringPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(monitoringDashboardProvider);
    final periodHours = ref.watch(monitoringPeriodHoursProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(context.l10n.adminMonitoringScreenTitle),
        actions: [
          TactileWrapper(
            onTap: () {
              ref.invalidate(monitoringDashboardProvider);
              ref.invalidate(errorLogsProvider);
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
      body: dashAsync.when(
        loading: () => const LomeLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (dash) => _DashboardBody(dash: dash, periodHours: periodHours),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.dash, required this.periodHours});

  final MonitoringDashboard dash;
  final int periodHours;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorLogsAsync = ref.watch(errorLogsProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final option in [
                  (label: '1h', value: 1),
                  (label: '6h', value: 6),
                  (label: '24h', value: 24),
                  (label: '7d', value: 168),
                  (label: '30d', value: 720),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: AppTheme.spacingSm),
                    child: ChoiceChip(
                      label: Text(option.label),
                      selected: periodHours == option.value,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: periodHours == option.value
                            ? AppColors.primary
                            : AppColors.grey600,
                        fontWeight: periodHours == option.value
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      onSelected: (_) =>
                          ref
                                  .read(monitoringPeriodHoursProvider.notifier)
                                  .state =
                              option.value,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // ── Error KPIs ─────────────────────────────────────────────────
          Text(
            context.l10n.adminMonitoringErrors,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: [
              Expanded(
                child: _KpiTile(
                  label: context.l10n.adminMonitoringTotalLabel,
                  value: '${dash.errors.total}',
                  color: AppColors.info,
                  icon: PhosphorIcons.bug(PhosphorIconsStyle.fill),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: _KpiTile(
                  label: context.l10n.adminMonitoringCriticalLabel,
                  value: '${dash.errors.critical}',
                  color: AppColors.error,
                  icon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: _KpiTile(
                  label: context.l10n.adminMonitoringErrorsKpi,
                  value: '${dash.errors.error}',
                  color: AppColors.warning,
                  icon: PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: _KpiTile(
                  label: context.l10n.adminMonitoringWarningsLabel,
                  value: '${dash.errors.warning}',
                  color: AppColors.grey500,
                  icon: PhosphorIcons.info(PhosphorIconsStyle.fill),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms),

          // Error by source
          if (dash.errors.bySource.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMd),
            LomeCard(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.adminMonitoringErrorsBySource,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  ...dash.errors.bySource.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacingXs,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.key,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.grey500,
                              ),
                            ),
                          ),
                          Text(
                            '${e.value}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
          ],

          const SizedBox(height: AppTheme.spacingXl),

          // ── API KPIs ───────────────────────────────────────────────────
          Text(
            context.l10n.adminMonitoringApiPerformance,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppTheme.spacingSm,
            crossAxisSpacing: AppTheme.spacingSm,
            childAspectRatio: 1.6,
            children: [
              LomeStatCard(
                icon: PhosphorIcons.lightning(PhosphorIconsStyle.fill),
                iconColor: AppColors.primary,
                title: context.l10n.adminMonitoringRequests,
                value: '${dash.apiUsage.totalRequests}',
              ),
              LomeStatCard(
                icon: PhosphorIcons.timer(PhosphorIconsStyle.fill),
                iconColor: AppColors.success,
                title: context.l10n.adminMonitoringAvgResponse,
                value:
                    '${dash.apiUsage.avgResponseTimeMs.toStringAsFixed(0)} ms',
              ),
              LomeStatCard(
                icon: PhosphorIcons.chartLine(PhosphorIconsStyle.fill),
                iconColor: AppColors.warning,
                title: context.l10n.adminMonitoringP95Response,
                value:
                    '${dash.apiUsage.p95ResponseTimeMs.toStringAsFixed(0)} ms',
              ),
              LomeStatCard(
                icon: PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
                iconColor: dash.apiUsage.errorRatePercent > 5
                    ? AppColors.error
                    : AppColors.success,
                title: context.l10n.adminMonitoringErrorRate,
                value: '${dash.apiUsage.errorRatePercent.toStringAsFixed(1)}%',
              ),
            ],
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

          // Top endpoints
          if (dash.apiUsage.topEndpoints.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMd),
            LomeCard(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.adminMonitoringTopEndpoints,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  ...dash.apiUsage.topEndpoints.map(
                    (ep) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacingXs,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              ep.endpoint,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.grey500,
                              ),
                            ),
                          ),
                          Text(
                            context.l10n.adminMonitoringHitsCount('${ep.hits}'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
          ],

          // Slow endpoints
          if (dash.apiUsage.slowEndpoints.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMd),
            LomeCard(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        PhosphorIcons.warning(PhosphorIconsStyle.duotone),
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.adminMonitoringSlowEndpoints,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  ...dash.apiUsage.slowEndpoints.map(
                    (ep) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacingXs,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              ep.endpoint,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.grey500,
                              ),
                            ),
                          ),
                          Text(
                            '${ep.avgMs.toStringAsFixed(0)} ms',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 350.ms, duration: 300.ms),
          ],

          const SizedBox(height: AppTheme.spacingXl),

          // ── Recent Critical Errors ─────────────────────────────────────
          Text(
            context.l10n.adminMonitoringRecentCritical,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),

          if (dash.recentCriticalErrors.isEmpty)
            LomeCard(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      PhosphorIcons.checkCircle(PhosphorIconsStyle.duotone),
                      size: 48,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      context.l10n.adminMonitoringNoCritical,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...dash.recentCriticalErrors.asMap().entries.map(
              (entry) => _ErrorTile(
                error: entry.value,
              ).animate().fadeIn(delay: (entry.key * 50).ms, duration: 250.ms),
            ),

          const SizedBox(height: AppTheme.spacingXl),

          // ── Error Log Table ────────────────────────────────────────────
          Row(
            children: [
              Text(
                context.l10n.adminMonitoringErrorLog,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey900,
                ),
              ),
              const Spacer(),
              _SeverityFilter(ref: ref),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          errorLogsAsync.when(
            loading: () => const LomeLoading(),
            error: (e, _) => Text('Error: $e'),
            data: (logs) {
              if (logs.isEmpty) {
                return LomeCard(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Center(
                    child: Text(
                      context.l10n.adminMonitoringNoErrors,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.grey500,
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: logs
                    .asMap()
                    .entries
                    .map(
                      (entry) => _ErrorTile(error: entry.value)
                          .animate()
                          .fadeIn(delay: (entry.key * 40).ms, duration: 200.ms),
                    )
                    .toList(),
              );
            },
          ),

          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }
}

// ─── KPI tile ────────────────────────────────────────────────────────────────

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return LomeCard(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColors.grey500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Severity filter ─────────────────────────────────────────────────────────

class _SeverityFilter extends StatelessWidget {
  const _SeverityFilter({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final severity = ref.watch(errorSeverityFilterProvider);
    return DropdownButton<String?>(
      value: severity,
      hint: Text(
        context.l10n.adminMonitoringSeverity,
        style: const TextStyle(fontSize: 12, color: AppColors.grey500),
      ),
      underline: const SizedBox.shrink(),
      isDense: true,
      items: [null, 'critical', 'error', 'warning', 'info', 'debug']
          .map(
            (s) => DropdownMenuItem<String?>(
              value: s,
              child: Text(
                s ?? context.l10n.adminMonitoringAllSeverities,
                style: const TextStyle(fontSize: 12, color: AppColors.grey500),
              ),
            ),
          )
          .toList(),
      onChanged: (v) =>
          ref.read(errorSeverityFilterProvider.notifier).state = v,
    );
  }
}

// ─── Error tile ──────────────────────────────────────────────────────────────

class _ErrorTile extends StatelessWidget {
  const _ErrorTile({required this.error});

  final ErrorLogEntry error;

  Color get _severityColor {
    switch (error.severity) {
      case 'critical':
        return AppColors.error;
      case 'error':
        return AppColors.warning;
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'info':
        return AppColors.info;
      default:
        return AppColors.grey500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = DateFormat('dd/MM HH:mm:ss').format(error.createdAt);

    return LomeCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _severityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  error.severity.toUpperCase(),
                  style: TextStyle(
                    color: _severityColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  error.source,
                  style: const TextStyle(color: AppColors.info, fontSize: 10),
                ),
              ),
              const Spacer(),
              Text(
                ts,
                style: const TextStyle(color: AppColors.grey400, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            error.message,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.grey500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (error.appVersion != null)
            Text(
              'v${error.appVersion}',
              style: const TextStyle(color: AppColors.grey400, fontSize: 11),
            ),
        ],
      ),
    );
  }
}
