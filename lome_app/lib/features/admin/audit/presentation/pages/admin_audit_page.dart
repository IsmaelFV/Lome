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
import '../providers/admin_audit_provider.dart';

class AdminAuditPage extends ConsumerWidget {
  const AdminAuditPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(auditSummaryProvider);
    final logsAsync = ref.watch(auditLogsProvider);
    final periodHours = ref.watch(auditPeriodHoursProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(context.l10n.adminAuditScreenTitle),
        actions: [
          TactileWrapper(
            onTap: () {
              ref.invalidate(auditSummaryProvider);
              ref.invalidate(auditLogsProvider);
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
      body: Column(
        children: [
          // Period selector
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingMd,
              AppTheme.spacingMd,
              AppTheme.spacingMd,
              0,
            ),
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
                        color: periodHours == option.value ? AppColors.primary : AppColors.grey600,
                        fontWeight: periodHours == option.value ? FontWeight.w600 : FontWeight.w400,
                      ),
                      onSelected: (_) => ref
                          .read(auditPeriodHoursProvider.notifier)
                          .state = option.value,
                    ),
                  ),
              ],
            ),
          ),

          // Summary cards
          summaryAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              child: LomeLoading(),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Text('Error: $e'),
            ),
            data: (summary) => Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: LomeStatCard(
                          icon: PhosphorIcons.listBullets(
                              PhosphorIconsStyle.fill),
                          iconColor: AppColors.primary,
                          title: context.l10n.adminAuditTotalEvents,
                          value: '${summary.totalEvents}',
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: LomeStatCard(
                          icon: PhosphorIcons.usersThree(
                              PhosphorIconsStyle.fill),
                          iconColor: AppColors.info,
                          title: context.l10n.adminAuditActiveUsers,
                          value: '${summary.topUsers.length}',
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms),

                  // Action breakdown
                  if (summary.actions.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingMd),
                    LomeCard(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.adminAuditByAction,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.grey900),
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          Wrap(
                            spacing: AppTheme.spacingSm,
                            runSpacing: AppTheme.spacingSm,
                            children: summary.actions.entries
                                .map((e) => _ActionChip(
                                      label: _actionLabel(context, e.key),
                                      count: e.value,
                                      color: _actionColor(e.key),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                  ],

                  // Entity breakdown
                  if (summary.entities.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingMd),
                    LomeCard(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.adminAuditByEntity,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.grey900),
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          Wrap(
                            spacing: AppTheme.spacingSm,
                            runSpacing: AppTheme.spacingSm,
                            children: summary.entities.entries
                                .map((e) => _ActionChip(
                                      label: e.key,
                                      count: e.value,
                                      color: AppColors.info,
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                  ],
                ],
              ),
            ),
          ),

          // Filters row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            child: Row(
              children: [
                Text(
                  context.l10n.adminAuditEventLog,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.grey900),
                ),
                const Spacer(),
                _FilterDropdown(
                  hint: context.l10n.adminAuditActionLabel,
                  value: ref.watch(auditActionFilterProvider),
                  items: const [
                    null,
                    'INSERT',
                    'UPDATE',
                    'DELETE',
                    'login',
                    'logout',
                    'admin_access',
                  ],
                  onChanged: (v) =>
                      ref.read(auditActionFilterProvider.notifier).state = v,
                ),
              ],
            ),
          ),

          // Logs list
          Expanded(
            child: logsAsync.when(
              loading: () => const LomeLoading(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (logs) {
                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIcons.clipboardText(PhosphorIconsStyle.duotone),
                            size: 64,
                            color: AppColors.grey300),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(context.l10n.adminAuditNoEvents,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.grey500)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async =>
                      ref.invalidate(auditLogsProvider),
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      return _AuditLogTile(entry: logs[index])
                          .animate()
                          .fadeIn(delay: (index * 50).ms, duration: 250.ms);
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

  static String _actionLabel(BuildContext context, String action) {
    switch (action) {
      case 'INSERT':
        return context.l10n.adminAuditCreation;
      case 'UPDATE':
        return context.l10n.adminAuditUpdate;
      case 'DELETE':
        return context.l10n.adminAuditDeletion;
      default:
        return action;
    }
  }

  static Color _actionColor(String action) {
    switch (action) {
      case 'INSERT':
        return AppColors.success;
      case 'UPDATE':
        return AppColors.info;
      case 'DELETE':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }
}

// ─── Action chip with count ──────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter dropdown ─────────────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String hint;
  final String? value;
  final List<String?> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String?>(
      value: value,
      hint: Text(hint, style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
      underline: const SizedBox.shrink(),
      isDense: true,
      items: items
          .map((item) => DropdownMenuItem<String?>(
                value: item,
                child: Text(
                  item ?? context.l10n.adminAuditAllFilter,
                  style: const TextStyle(fontSize: 12, color: AppColors.grey500),
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ─── Audit log tile ──────────────────────────────────────────────────────────

class _AuditLogTile extends StatelessWidget {
  const _AuditLogTile({required this.entry});

  final AuditLogEntry entry;

  IconData get _actionIcon {
    switch (entry.action) {
      case 'INSERT':
        return PhosphorIcons.plus(PhosphorIconsStyle.duotone);
      case 'UPDATE':
        return PhosphorIcons.pencilSimple(PhosphorIconsStyle.duotone);
      case 'DELETE':
        return PhosphorIcons.trash(PhosphorIconsStyle.duotone);
      case 'login':
        return PhosphorIcons.signIn(PhosphorIconsStyle.duotone);
      case 'logout':
        return PhosphorIcons.signOut(PhosphorIconsStyle.duotone);
      case 'admin_access':
        return PhosphorIcons.shieldStar(PhosphorIconsStyle.duotone);
      default:
        return PhosphorIcons.notepad(PhosphorIconsStyle.duotone);
    }
  }

  Color get _actionColor {
    switch (entry.action) {
      case 'INSERT':
        return AppColors.success;
      case 'UPDATE':
        return AppColors.info;
      case 'DELETE':
        return AppColors.error;
      case 'login':
        return AppColors.primary;
      case 'logout':
        return AppColors.grey500;
      case 'admin_access':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = DateFormat('dd/MM HH:mm:ss').format(entry.createdAt);

    return LomeCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _actionColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_actionIcon, size: 18, color: _actionColor),
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
                        color: _actionColor.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Text(
                        entry.action,
                        style: TextStyle(
                              fontSize: 10,
                              color: _actionColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Text(
                        entry.entityType,
                        style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.info,
                            ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      ts,
                      style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.grey400,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  entry.userName ?? entry.userId ?? context.l10n.adminAuditSystemLabel,
                  style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey500,
                      ),
                ),
                if (entry.entityId != null)
                  Text(
                    'ID: ${entry.entityId}',
                    style: const TextStyle(
                          fontSize: 11,
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
