import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_card.dart';
import '../../../../../core/widgets/lome_loading.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../../domain/entities/admin_entities.dart';
import '../providers/admin_incidents_provider.dart';

class AdminIncidentsPage extends ConsumerStatefulWidget {
  const AdminIncidentsPage({super.key});

  @override
  ConsumerState<AdminIncidentsPage> createState() =>
      _AdminIncidentsPageState();
}

class _AdminIncidentsPageState extends ConsumerState<AdminIncidentsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _statuses = ['open', 'in_progress', 'resolved', 'closed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      ref.read(incidentStatusFilterProvider.notifier).state =
          _statuses[_tabController.index];
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incidentsAsync = ref.watch(adminIncidentsProvider);
    final priorityCounts = ref.watch(incidentPriorityCountsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(context.l10n.adminIncidentsTitle),
        actions: [
          TactileWrapper(
            onTap: () => ref.invalidate(adminIncidentsProvider),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              child: Icon(
                PhosphorIcons.arrowClockwise(PhosphorIconsStyle.duotone),
                color: AppColors.grey700,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.l10n.adminIncidentsFilterOpen),
            Tab(text: context.l10n.adminIncidentsFilterInProgress),
            Tab(text: context.l10n.adminIncidentsFilterResolved),
            Tab(text: context.l10n.adminIncidentsFilterClosed),
          ],
        ),
      ),
      body: Column(
        children: [
          // Resumen de prioridades
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Row(
              children: [
                _PriorityBadge(
                  label: context.l10n.adminIncidentsPriorityCritical,
                  count: priorityCounts['critical'] ?? 0,
                  color: AppColors.error,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                _PriorityBadge(
                  label: context.l10n.adminIncidentsPriorityHigh,
                  count: priorityCounts['high'] ?? 0,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                _PriorityBadge(
                  label: context.l10n.adminIncidentsPriorityMedium,
                  count: priorityCounts['medium'] ?? 0,
                  color: AppColors.info,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                _PriorityBadge(
                  label: context.l10n.adminIncidentsPriorityLow,
                  count: priorityCounts['low'] ?? 0,
                  color: AppColors.grey500,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          // Lista de incidencias
          Expanded(
            child: incidentsAsync.when(
              loading: () => const LomeLoading(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (incidents) {
                if (incidents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.duotone),
                            size: 64, color: AppColors.grey300),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(context.l10n.adminIncidentsEmpty,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.grey500)),
                        const SizedBox(height: AppTheme.spacingSm),
                        Text(
                          context.l10n.adminIncidentsEmptySubtitle,
                          style: const TextStyle(fontSize: 12, color: AppColors.grey400),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async =>
                      ref.invalidate(adminIncidentsProvider),
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd),
                    itemCount: incidents.length,
                    itemBuilder: (context, index) {
                      return _IncidentTile(incident: incidents[index])
                          .animate()
                          .fadeIn(
                              delay: (index * 80).ms, duration: 300.ms)
                          .slideX(begin: 0.05);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Priority Badge ──────────────────────────────────────────────────────────

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSm,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Incident Tile ───────────────────────────────────────────────────────────

class _IncidentTile extends StatelessWidget {
  const _IncidentTile({required this.incident});

  final Incident incident;

  Color get _priorityColor {
    switch (incident.priority) {
      case 'critical':
        return AppColors.error;
      case 'high':
        return AppColors.warning;
      case 'medium':
        return AppColors.info;
      default:
        return AppColors.grey500;
    }
  }

  String _priorityLabel(BuildContext context) {
    switch (incident.priority) {
      case 'critical':
        return context.l10n.adminIncidentDetailPriorityCritical.toUpperCase();
      case 'high':
        return context.l10n.adminIncidentDetailPriorityHigh.toUpperCase();
      case 'medium':
        return context.l10n.adminIncidentDetailPriorityMedium.toUpperCase();
      default:
        return context.l10n.adminIncidentDetailPriorityLow.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeAgo = DateFormat('dd/MM/yyyy HH:mm').format(incident.createdAt);

    return LomeCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      onTap: () {
        context.pushNamed(
          RouteNames.adminIncidentDetail,
          pathParameters: {'id': incident.id},
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: _priorityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _priorityColor.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: Text(
                            _priorityLabel(context),
                            style: TextStyle(
                                  fontSize: 10,
                                  color: _priorityColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        if (incident.category != null) ...[
                          const SizedBox(width: AppTheme.spacingSm),
                          Text(
                            incident.category!,
                            style: const TextStyle(fontSize: 11, color: AppColors.grey500),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          timeAgo,
                          style: const TextStyle(fontSize: 12, color: AppColors.grey400),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      incident.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              incident.description,
              style: const TextStyle(fontSize: 12, color: AppColors.grey600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                if (incident.tenantName != null) ...[
                  Icon(PhosphorIcons.storefront(PhosphorIconsStyle.duotone),
                      size: 14, color: AppColors.grey500),
                  const SizedBox(width: 4),
                  Text(
                    incident.tenantName!,
                    style: const TextStyle(fontSize: 12, color: AppColors.grey500),
                  ),
                ],
                if (incident.assigneeName != null) ...[
                  const SizedBox(width: AppTheme.spacingMd),
                  Icon(PhosphorIcons.user(PhosphorIconsStyle.duotone),
                      size: 14, color: AppColors.grey500),
                  const SizedBox(width: 4),
                  Text(
                    incident.assigneeName!,
                    style: const TextStyle(fontSize: 12, color: AppColors.grey500),
                  ),
                ],
                const Spacer(),
                Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.duotone),
                    size: 16, color: AppColors.grey400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
