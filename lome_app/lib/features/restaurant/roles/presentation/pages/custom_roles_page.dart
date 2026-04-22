import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/validators/form_validators.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../core/widgets/lome_button.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_text_field.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../providers/custom_roles_provider.dart';

/// Página de gestión de roles personalizados.
class CustomRolesPage extends ConsumerWidget {
  const CustomRolesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesState = ref.watch(customRolesProvider);

    ref.listen<CustomRolesState>(customRolesProvider, (prev, next) {
      if (next.successMessage != null && prev?.successMessage == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.successMessage!),
              backgroundColor: AppColors.success,
            ),
          );
      }
      if (next.errorMessage != null && prev?.errorMessage == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(title: context.l10n.customRolesTitle),
      floatingActionButton: TactileWrapper(
        onTap: () => _showRoleDialog(context, ref),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            PhosphorIcons.plus(PhosphorIconsStyle.bold),
            color: AppColors.white,
          ),
        ),
      ),
      body: rolesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : rolesState.roles.isEmpty
          ? _EmptyState(onCreateFirst: () => _showRoleDialog(context, ref))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () =>
                  ref.read(customRolesProvider.notifier).loadRoles(),
              child: ListView.separated(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                itemCount: rolesState.roles.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppTheme.spacingSm),
                itemBuilder: (context, index) {
                  final role = rolesState.roles[index];
                  return _RoleCard(
                        role: role,
                        onEdit: () => _showRoleDialog(context, ref, role: role),
                        onDelete: () => _confirmDelete(context, ref, role),
                      )
                      .animate(delay: Duration(milliseconds: 50 * index))
                      .fadeIn(duration: AppTheme.durationFast)
                      .slideY(begin: 0.1, end: 0);
                },
              ),
            ),
    );
  }

  void _showRoleDialog(
    BuildContext context,
    WidgetRef ref, {
    CustomRole? role,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _RoleFormSheet(existingRole: role),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CustomRole role) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.customRolesDeleteTitle),
        content: Text(context.l10n.customRolesDeleteConfirm(role.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(customRolesProvider.notifier).deleteRole(role.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Role card
// =============================================================================

class _RoleCard extends StatelessWidget {
  final CustomRole role;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoleCard({
    required this.role,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final permCount = role.permissions.length;
    final roleColor = role.color != null
        ? Color(int.parse('FF${role.color!.replaceFirst('#', '')}', radix: 16))
        : AppColors.primary;

    return TactileWrapper(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                PhosphorIcons.identificationBadge(PhosphorIconsStyle.duotone),
                color: roleColor,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        role.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey800,
                        ),
                      ),
                      if (!role.isActive) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.grey200,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                          ),
                          child: Text(
                            context.l10n.customRolesInactive,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.grey500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (role.description != null)
                    Text(
                      role.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    context.l10n.customRolesPermCount(permCount),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.grey400,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(value: 'edit', child: Text(ctx.l10n.edit)),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    ctx.l10n.delete,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Role form sheet
// =============================================================================

class _RoleFormSheet extends ConsumerStatefulWidget {
  final CustomRole? existingRole;

  const _RoleFormSheet({this.existingRole});

  @override
  ConsumerState<_RoleFormSheet> createState() => _RoleFormSheetState();
}

class _RoleFormSheetState extends ConsumerState<_RoleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late Set<String> _selectedPerms;

  bool get _isEditing => widget.existingRole != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existingRole?.name ?? '');
    _descCtrl = TextEditingController(
      text: widget.existingRole?.description ?? '',
    );
    _selectedPerms = Set<String>.from(widget.existingRole?.permissions ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPerms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.customRolesMinPerm),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final notifier = ref.read(customRolesProvider.notifier);
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final perms = _selectedPerms.toList();

    if (_isEditing) {
      notifier.updateRole(
        roleId: widget.existingRole!.id,
        name: name,
        description: desc.isEmpty ? null : desc,
        permissions: perms,
      );
    } else {
      notifier.createRole(
        name: name,
        description: desc.isEmpty ? null : desc,
        permissions: perms,
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Agrupar permisos
    final grouped = <String, List<CustomPermission>>{};
    for (final p in availablePermissions) {
      grouped.putIfAbsent(p.group, () => []).add(p);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingMd,
          AppTheme.spacingSm,
          AppTheme.spacingMd,
          AppTheme.spacingMd,
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: controller,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                _isEditing
                    ? context.l10n.customRolesEditTitle
                    : context.l10n.customRolesNewTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              LomeTextField(
                label: context.l10n.customRolesNameLabel,
                controller: _nameCtrl,
                hint: context.l10n.customRolesNameHint,
                validator: (v) => FormValidators.required(v, 'El nombre'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppTheme.spacingMd),

              LomeTextField(
                label: context.l10n.customRolesDescLabel,
                controller: _descCtrl,
                hint: context.l10n.customRolesDescHint,
                maxLines: 2,
              ),

              const SizedBox(height: AppTheme.spacingLg),

              Text(
                context.l10n.customRolesPermissions,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),

              ...grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppTheme.spacingSm,
                        bottom: AppTheme.spacingXs,
                      ),
                      child: Text(
                        entry.key,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.grey500,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: AppTheme.spacingSm,
                      runSpacing: AppTheme.spacingXs,
                      children: entry.value.map((perm) {
                        final selected = _selectedPerms.contains(perm.key);
                        return FilterChip(
                          label: Text(perm.label),
                          selected: selected,
                          selectedColor: AppColors.primary.withValues(
                            alpha: 0.15,
                          ),
                          checkmarkColor: AppColors.primary,
                          side: BorderSide(
                            color: selected
                                ? AppColors.primary
                                : AppColors.grey200,
                          ),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedPerms.add(perm.key);
                              } else {
                                _selectedPerms.remove(perm.key);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                );
              }),

              const SizedBox(height: AppTheme.spacingXl),

              LomeButton(
                label: _isEditing
                    ? context.l10n.customRolesSaveButton
                    : context.l10n.customRolesCreateButton,
                isExpanded: true,
                isLoading: ref.watch(customRolesProvider).isSaving,
                onPressed: _submit,
              ),

              const SizedBox(height: AppTheme.spacingMd),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Empty state
// =============================================================================

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateFirst;

  const _EmptyState({required this.onCreateFirst});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child:
            Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.identificationBadge(
                        PhosphorIconsStyle.duotone,
                      ),
                      size: 64,
                      color: AppColors.grey200,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text(
                      context.l10n.customRolesEmptyTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      context.l10n.customRolesEmptySubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.grey500,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    LomeButton(
                      label: context.l10n.customRolesCreateFirst,
                      icon: PhosphorIcons.plus(),
                      onPressed: onCreateFirst,
                    ),
                  ],
                )
                .animate()
                .fadeIn(duration: AppTheme.durationFast)
                .slideY(begin: 0.1, end: 0),
      ),
    );
  }
}
