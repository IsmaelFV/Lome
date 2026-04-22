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
import '../providers/admin_incidents_provider.dart';

class AdminIncidentDetailPage extends ConsumerWidget {
  const AdminIncidentDetailPage({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(adminIncidentDetailProvider(incidentId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(context.l10n.adminIncidentDetailTitle),
        actions: [
          TactileWrapper(
            onTap: () =>
                ref.invalidate(adminIncidentDetailProvider(incidentId)),
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
        data: (incident) {
          if (incident == null) {
            return Center(
              child: Text(context.l10n.adminIncidentDetailNotFound),
            );
          }
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderCard(incident: incident),
                const SizedBox(height: AppTheme.spacingLg),
                _DetailsCard(incident: incident),
                const SizedBox(height: AppTheme.spacingLg),
                if (incident.resolution != null)
                  _ResolutionCard(incident: incident),
                if (incident.resolution != null)
                  const SizedBox(height: AppTheme.spacingLg),
                _ActionsSection(incident: incident, ref: ref),
                const SizedBox(height: AppTheme.spacingXl),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Header Card ─────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(incident.priority);
    final statusColor = _statusColor(incident.status);
    final dateStr = DateFormat(
      'd MMM yyyy HH:mm',
      'es',
    ).format(incident.createdAt);

    return LomeCard(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  _priorityLabel(context, incident.priority),
                  style: TextStyle(
                    fontSize: 11,
                    color: priorityColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  _statusLabel(context, incident.status),
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            incident.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            dateStr,
            style: const TextStyle(fontSize: 12, color: AppColors.grey400),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  static Color _priorityColor(String priority) {
    switch (priority) {
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

  static String _priorityLabel(BuildContext context, String priority) {
    switch (priority) {
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

  static Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return AppColors.error;
      case 'in_progress':
        return AppColors.warning;
      case 'resolved':
        return AppColors.success;
      default:
        return AppColors.grey500;
    }
  }

  static String _statusLabel(BuildContext context, String status) {
    switch (status) {
      case 'open':
        return context.l10n.adminIncidentDetailStatusOpen;
      case 'in_progress':
        return context.l10n.adminIncidentDetailStatusInProgress;
      case 'resolved':
        return context.l10n.adminIncidentDetailStatusResolved;
      case 'closed':
        return context.l10n.adminIncidentDetailStatusClosed;
      default:
        return status;
    }
  }
}

// ─── Details Card ────────────────────────────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.adminIncidentDetailDescription,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                incident.description,
                style: const TextStyle(fontSize: 14, color: AppColors.grey700),
              ),
              const Divider(height: AppTheme.spacingLg),
              if (incident.tenantName != null)
                _DetailRow(
                  icon: PhosphorIcons.storefront(PhosphorIconsStyle.duotone),
                  label: context.l10n.adminIncidentDetailRestaurant,
                  value: incident.tenantName!,
                ),
              if (incident.reporterName != null) ...[
                const SizedBox(height: AppTheme.spacingSm),
                _DetailRow(
                  icon: PhosphorIcons.user(PhosphorIconsStyle.duotone),
                  label: context.l10n.adminIncidentDetailReporter,
                  value: incident.reporterName!,
                ),
              ],
              if (incident.assigneeName != null) ...[
                const SizedBox(height: AppTheme.spacingSm),
                _DetailRow(
                  icon: PhosphorIcons.userCircle(PhosphorIconsStyle.duotone),
                  label: context.l10n.adminIncidentDetailAssignedTo,
                  value: incident.assigneeName!,
                ),
              ],
              if (incident.category != null) ...[
                const SizedBox(height: AppTheme.spacingSm),
                _DetailRow(
                  icon: PhosphorIcons.tag(PhosphorIconsStyle.duotone),
                  label: context.l10n.adminIncidentDetailCategory,
                  value: incident.category!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grey500),
        const SizedBox(width: AppTheme.spacingSm),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: AppColors.grey500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.grey500,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Resolution Card ─────────────────────────────────────────────────────────

class _ResolutionCard extends StatelessWidget {
  const _ResolutionCard({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.adminIncidentDetailResolution,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    context.l10n.adminIncidentDetailStatusResolved,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (incident.resolvedAt != null) ...[
                    const Spacer(),
                    Text(
                      DateFormat(
                        'd MMM yyyy',
                        'es',
                      ).format(incident.resolvedAt!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey400,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                incident.resolution!,
                style: const TextStyle(fontSize: 14, color: AppColors.grey700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Actions Section ─────────────────────────────────────────────────────────

class _ActionsSection extends StatelessWidget {
  const _ActionsSection({required this.incident, required this.ref});

  final Incident incident;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (incident.status == 'closed' || incident.status == 'resolved') {
      return const SizedBox.shrink();
    }

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
        if (incident.status == 'open')
          LomeButton(
            label: context.l10n.adminIncidentDetailMarkInProgress,
            variant: LomeButtonVariant.primary,
            onPressed: () {
              ref.read(
                updateIncidentStatusProvider((
                  id: incident.id,
                  newStatus: 'in_progress',
                )),
              );
            },
            icon: PhosphorIcons.play(PhosphorIconsStyle.duotone),
            isExpanded: true,
          ),
        if (incident.status == 'in_progress') ...[
          LomeButton(
            label: context.l10n.adminIncidentDetailResolveIncident,
            variant: LomeButtonVariant.primary,
            onPressed: () => _showResolveDialog(context),
            icon: PhosphorIcons.check(PhosphorIconsStyle.duotone),
            isExpanded: true,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          LomeButton(
            label: context.l10n.adminIncidentDetailCloseWithoutResolve,
            variant: LomeButtonVariant.outlined,
            onPressed: () {
              ref.read(
                updateIncidentStatusProvider((
                  id: incident.id,
                  newStatus: 'closed',
                )),
              );
            },
            icon: PhosphorIcons.x(PhosphorIconsStyle.duotone),
            isExpanded: true,
          ),
        ],
      ],
    );
  }

  void _showResolveDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.adminIncidentDetailResolveIncident),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: context.l10n.adminIncidentDetailResolveHint,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(
                  resolveIncidentProvider((
                    id: incident.id,
                    resolution: controller.text.trim(),
                  )),
                );
                Navigator.pop(ctx);
              }
            },
            child: Text(context.l10n.adminIncidentDetailResolve),
          ),
        ],
      ),
    );
  }
}
