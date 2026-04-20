import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/auth/app_permission.dart';
import '../../../../../core/auth/permission_guard.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../core/widgets/lome_empty_state.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/employee_entity.dart';
import '../../domain/entities/invitation_entity.dart';
import '../providers/invitation_provider.dart';

/// Pantalla de gestiÃ³n de empleados del restaurante.
///
/// Muestra dos pestaÃ±as:
/// - **Equipo**: empleados activos con avatar, nombre, rol, acciones
/// - **Invitaciones**: invitaciones pendientes/enviadas con estado y acciones
///
/// Las acciones de gestiÃ³n (cambiar rol, eliminar, cancelar) se muestran
/// solo si el usuario tiene el permiso [AppPermission.manageEmployees].
class EmployeesPage extends ConsumerStatefulWidget {
  const EmployeesPage({super.key});

  @override
  ConsumerState<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends ConsumerState<EmployeesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Cargar invitaciones al iniciar
    Future.microtask(
      () => ref.read(invitationNotifierProvider.notifier).loadInvitations(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar mensajes del invitation provider
    ref.listen<InvitationState>(invitationNotifierProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
        ref.read(invitationNotifierProvider.notifier).clearMessages();
      }
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
        ref.read(invitationNotifierProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(
        title: context.l10n.employeesTitle,
        actions: [
          PermissionGuard(
            permission: AppPermission.manageEmployees,
            child: TactileWrapper(
              onTap: () => context.push(RoutePaths.invitationTemplate),
              child: Tooltip(
                message: context.l10n.invTemplTitle,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(PhosphorIcons.envelope(PhosphorIconsStyle.duotone), color: AppColors.white),
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey400,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(text: context.l10n.employeesTabTeam),
            Tab(text: context.l10n.employeesTabInvitations),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_EmployeesTab(), _InvitationsTab()],
      ),
      floatingActionButton: PermissionGuard(
        permission: AppPermission.manageEmployees,
        child: TactileWrapper(
          onTap: () => context.push(RoutePaths.inviteEmployee),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.userPlus(PhosphorIconsStyle.duotone), color: AppColors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  context.l10n.employeesInviteButton,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.3, end: 0, delay: 400.ms, duration: 400.ms),
        ),
      ),
    );
  }
}

// =============================================================================
// PestaÃ±a: Equipo (empleados activos)
// =============================================================================

class _EmployeesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);

    return employeesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.warningCircle(PhosphorIconsStyle.duotone),
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                context.l10n.employeesLoadError,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey700),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                err.toString(),
                style: const TextStyle(fontSize: 12, color: AppColors.grey500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              TextButton.icon(
                onPressed: () => ref.invalidate(employeesProvider),
                icon: Icon(PhosphorIcons.arrowClockwise(PhosphorIconsStyle.duotone), size: 18),
                label: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      ),
      data: (employees) {
        if (employees.isEmpty) {
          return LomeEmptyState(
            icon: PhosphorIcons.users(PhosphorIconsStyle.duotone),
            title: context.l10n.employeesEmptyTitle,
            subtitle: context.l10n.employeesEmptySubtitle,
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(employeesProvider),
          child: ListView.builder(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            itemCount: employees.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                  child: _TeamSummaryCard(employees: employees)
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.05, end: 0, duration: 500.ms),
                );
              }
              final i = index - 1;
              final employee = employees[i];
              return Padding(
                padding: EdgeInsets.only(top: i > 0 ? AppTheme.spacingSm : 0),
                child: _EmployeeCard(employee: employee).animate().fadeIn(
                  delay: Duration(milliseconds: i * 60),
                  duration: 400.ms,
                ).slideX(
                  begin: 0.03,
                  end: 0,
                  delay: Duration(milliseconds: i * 60),
                  duration: 400.ms,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// =============================================================================
// Hero card resumen del equipo
// =============================================================================

class _TeamSummaryCard extends StatelessWidget {
  final List<EmployeeEntity> employees;

  const _TeamSummaryCard({required this.employees});

  @override
  Widget build(BuildContext context) {
    final roleCounts = <String, int>{};
    for (final e in employees) {
      roleCounts[e.role] = (roleCounts[e.role] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(
                  PhosphorIcons.usersThree(PhosphorIconsStyle.duotone),
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${employees.length}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey900,
                    ),
                  ),
                  Text(
                    context.l10n.employeesTabTeam,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (roleCounts.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMd),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: roleCounts.entries.map((entry) {
                final info = _roleVisual(entry.key, context.l10n);
                return _RoleBadge(
                  label: '${info.label} (${entry.value})',
                  color: info.color,
                  icon: info.icon,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Card de empleado
// =============================================================================

class _EmployeeCard extends ConsumerWidget {
  final EmployeeEntity employee;

  const _EmployeeCard({required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleInfo = _roleVisual(employee.role, context.l10n);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppShadows.card,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 3, color: roleInfo.color),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppTheme.spacingMd + 3,
              AppTheme.spacingMd,
              AppTheme.spacingMd,
              AppTheme.spacingMd,
            ),
            child: Row(
              children: [
                // Avatar
                _buildAvatar(employee.avatarUrl, employee.fullName, roleInfo.color),
                const SizedBox(width: AppTheme.spacingMd),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.fullName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(PhosphorIcons.envelope(PhosphorIconsStyle.duotone), size: 12, color: AppColors.grey500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              employee.email,
                              style: const TextStyle(fontSize: 12, color: AppColors.grey500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _RoleBadge(
                        label: employee.roleLabel,
                        color: roleInfo.color,
                        icon: roleInfo.icon,
                      ),
                    ],
                  ),
                ),

                // Acciones (solo con permiso)
                PermissionGuard(
                  permission: AppPermission.manageEmployees,
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      PhosphorIcons.dotsThreeVertical(PhosphorIconsStyle.duotone),
                      color: AppColors.grey400,
                      size: 22,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    onSelected: (action) => _handleAction(action, context, ref),
                    itemBuilder: (_) => [
                      if (employee.role != 'owner') ...[
                        PopupMenuItem(
                          value: 'change_role',
                          child: ListTile(
                            dense: true,
                            leading: Icon(PhosphorIcons.arrowsLeftRight(PhosphorIconsStyle.duotone), size: 20),
                            title: Text(context.l10n.employeesChangeRole),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              PhosphorIcons.userMinus(PhosphorIconsStyle.duotone),
                              size: 20,
                              color: AppColors.error,
                            ),
                            title: Text(
                              context.l10n.delete,
                              style: TextStyle(color: AppColors.error),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? url, String name, Color roleColor) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: roleColor.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.grey200),
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, _) => Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: roleColor,
                      fontSize: 16,
                    ),
                  ),
                ),
                errorWidget: (_, _, _) => Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: roleColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: roleColor,
                    fontSize: 16,
                  ),
                ),
              ),
      ),
    );
  }

  void _handleAction(String action, BuildContext context, WidgetRef ref) {
    switch (action) {
      case 'change_role':
        _showChangeRoleDialog(context, ref);
        break;
      case 'remove':
        _showRemoveDialog(context, ref);
        break;
    }
  }

  void _showChangeRoleDialog(BuildContext context, WidgetRef ref) {
    String selectedRole = employee.role;
    final roles = ['manager', 'waiter', 'kitchen', 'viewer'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(context.l10n.employeesChangeRoleDialogTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: roles.map((role) {
                  final info = _roleVisual(role, context.l10n);
                  final isSelected = selectedRole == role;
                  return ListTile(
                    leading: Icon(info.icon, size: 20, color: info.color),
                    title: Text(info.label),
                    trailing: Icon(
                      isSelected
                          ? PhosphorIcons.radioButton(PhosphorIconsStyle.fill)
                          : PhosphorIcons.circle(PhosphorIconsStyle.duotone),
                      color: isSelected ? info.color : AppColors.grey300,
                    ),
                    onTap: () => setDialogState(() => selectedRole = role),
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(context.l10n.cancel),
                ),
                FilledButton(
                  onPressed: selectedRole != employee.role
                      ? () async {
                          Navigator.pop(ctx);
                          final success = await ref
                              .read(invitationNotifierProvider.notifier)
                              .updateEmployeeRole(
                                membershipId: employee.id,
                                newRole: selectedRole,
                              );
                          if (success) {
                            ref.invalidate(employeesProvider);
                          }
                        }
                      : null,
                  child: Text(context.l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRemoveDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                PhosphorIcons.warning(PhosphorIconsStyle.duotone),
                color: AppColors.error,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(context.l10n.employeesRemoveTitle),
            ],
          ),
          content: Text(context.l10n.employeesRemoveConfirm(employee.fullName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await ref
                    .read(invitationNotifierProvider.notifier)
                    .removeEmployee(employee.id);
                if (success) {
                  ref.invalidate(employeesProvider);
                }
              },
              child: Text(context.l10n.delete),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// PestaÃ±a: Invitaciones
// =============================================================================

class _InvitationsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invState = ref.watch(invitationNotifierProvider);

    if (invState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final invitations = invState.invitations;

    if (invitations.isEmpty) {
      return LomeEmptyState(
        icon: PhosphorIcons.envelope(PhosphorIconsStyle.duotone),
        title: context.l10n.invitationsEmptyTitle,
        subtitle: context.l10n.invitationsEmptySubtitle,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () =>
          ref.read(invitationNotifierProvider.notifier).loadInvitations(),
      child: ListView.separated(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        itemCount: invitations.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spacingSm),
        itemBuilder: (context, index) {
          final invitation = invitations[index];
          return _InvitationCard(invitation: invitation).animate().fadeIn(
            delay: Duration(milliseconds: index * 60),
            duration: 400.ms,
          ).slideY(
            begin: 0.05,
            end: 0,
            delay: Duration(milliseconds: index * 60),
            duration: 400.ms,
          );
        },
      ),
    );
  }
}

// =============================================================================
// Card de invitaciÃ³n
// =============================================================================

class _InvitationCard extends ConsumerWidget {
  final InvitationEntity invitation;

  const _InvitationCard({required this.invitation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusInfo = _statusVisual(
      invitation.status,
      invitation.isExpired,
      context.l10n,
    );
    final roleInfo = _roleVisual(invitation.role, context.l10n);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: email + status badge
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.grey100,
                ),
                child: Icon(
                  PhosphorIcons.envelope(PhosphorIconsStyle.duotone),
                  size: 20,
                  color: AppColors.grey400,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.email,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _RoleBadge(
                          label: roleInfo.label,
                          color: roleInfo.color,
                          icon: roleInfo.icon,
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(
                          label: statusInfo.label,
                          color: statusInfo.color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Info de tiempo
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingSm, left: 56),
            child: Text(
              _timeInfo(context.l10n),
              style: const TextStyle(
                color: AppColors.grey400,
                fontSize: 11,
              ),
            ),
          ),

          // Acciones para invitaciones pendientes
          if (invitation.isPending)
            PermissionGuard(
              permission: AppPermission.manageEmployees,
              child: Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingSm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => ref
                          .read(invitationNotifierProvider.notifier)
                          .resendInvitation(invitation.id),
                      icon: Icon(PhosphorIcons.arrowClockwise(PhosphorIconsStyle.duotone), size: 16),
                      label: Text(context.l10n.invitationsResend),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.info,
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _showCancelDialog(context, ref),
                      icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold), size: 16),
                      label: Text(context.l10n.invitationsCancel),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _timeInfo(AppLocalizations l10n) {
    final created = _formatRelative(invitation.createdAt, l10n);
    if (invitation.isPending) {
      final expires = _formatRelative(invitation.expiresAt, l10n);
      return l10n.invitationSentExpires(created, expires);
    }
    if (invitation.status == InvitationStatus.accepted &&
        invitation.acceptedAt != null) {
      return l10n.invitationAcceptedDate(
        _formatRelative(invitation.acceptedAt!, l10n),
      );
    }
    return l10n.invitationSent(created);
  }

  String _formatRelative(DateTime date, AppLocalizations l10n) {
    final diff = DateTime.now().difference(date);
    if (diff.isNegative) {
      final until = date.difference(DateTime.now());
      if (until.inDays > 0) return l10n.timeInDays(until.inDays);
      if (until.inHours > 0) return l10n.timeInHours(until.inHours);
      return l10n.timeInMinutes(until.inMinutes);
    }
    if (diff.inDays > 0) return l10n.timeAgoDays(diff.inDays);
    if (diff.inHours > 0) return l10n.timeAgoHours(diff.inHours);
    if (diff.inMinutes > 0) return l10n.timeAgoMinutes(diff.inMinutes);
    return l10n.timeNow;
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.invitationsCancelDialogTitle),
        content: Text(context.l10n.invitationsCancelConfirm(invitation.email)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.no),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(invitationNotifierProvider.notifier)
                  .cancelInvitation(invitation.id);
            },
            child: Text(context.l10n.invitationsCancelButton),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Widgets auxiliares
// =============================================================================

class _RoleBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _RoleBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// =============================================================================
// Datos visuales de roles y estados
// =============================================================================

class _RoleVisual {
  final String label;
  final Color color;
  final IconData icon;
  const _RoleVisual(this.label, this.color, this.icon);
}

class _StatusVisual {
  final String label;
  final Color color;
  const _StatusVisual(this.label, this.color);
}

_RoleVisual _roleVisual(String role, AppLocalizations l10n) {
  switch (role) {
    case 'owner':
      return _RoleVisual(
        l10n.roleOwner,
        AppColors.primary,
        PhosphorIcons.star(PhosphorIconsStyle.fill),
      );
    case 'manager':
      return _RoleVisual(
        l10n.roleManager,
        AppColors.info,
        PhosphorIcons.shieldCheck(PhosphorIconsStyle.duotone),
      );
    case 'waiter':
      return _RoleVisual(
        l10n.roleWaiter,
        AppColors.success,
        PhosphorIcons.bellSimple(PhosphorIconsStyle.duotone),
      );
    case 'kitchen':
      return _RoleVisual(
        l10n.roleKitchen,
        AppColors.warning,
        PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
      );
    case 'viewer':
      return _RoleVisual(
        l10n.roleViewer,
        AppColors.grey500,
        PhosphorIcons.eye(PhosphorIconsStyle.duotone),
      );
    default:
      return _RoleVisual(role, AppColors.grey500, PhosphorIcons.user(PhosphorIconsStyle.duotone));
  }
}

_StatusVisual _statusVisual(
  InvitationStatus status,
  bool isExpired,
  AppLocalizations l10n,
) {
  if (isExpired && status == InvitationStatus.pending) {
    return _StatusVisual(l10n.invitationStatusExpired, AppColors.grey400);
  }
  switch (status) {
    case InvitationStatus.pending:
      return _StatusVisual(l10n.invitationStatusPending, AppColors.warning);
    case InvitationStatus.accepted:
      return _StatusVisual(l10n.invitationAccepted, AppColors.success);
    case InvitationStatus.rejected:
      return _StatusVisual(l10n.invitationStatusRejected, AppColors.error);
    case InvitationStatus.expired:
      return _StatusVisual(l10n.invitationStatusExpired, AppColors.grey400);
    case InvitationStatus.cancelled:
      return _StatusVisual(l10n.invitationStatusCancelled, AppColors.grey400);
  }
}
