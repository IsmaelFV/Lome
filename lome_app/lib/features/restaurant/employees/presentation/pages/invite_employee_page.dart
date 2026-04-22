import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/utils/validators/form_validators.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../core/widgets/lome_button.dart';
import '../../../../../core/widgets/lome_text_field.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../providers/invitation_provider.dart';

/// Pantalla para invitar empleados al restaurante.
///
/// Permite al admin/owner introducir un email y seleccionar un rol
/// para enviar una invitación.
class InviteEmployeePage extends ConsumerStatefulWidget {
  const InviteEmployeePage({super.key});

  @override
  ConsumerState<InviteEmployeePage> createState() => _InviteEmployeePageState();
}

class _InviteEmployeePageState extends ConsumerState<InviteEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _selectedRole = 'waiter';
  bool _formSubmitted = false;

  List<_RoleOption> _buildRoleOptions(BuildContext context) => [
    _RoleOption(
      value: 'manager',
      label: context.l10n.roleManager,
      description: context.l10n.roleManagerDesc,
      icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.duotone),
      color: AppColors.info,
    ),
    _RoleOption(
      value: 'waiter',
      label: context.l10n.roleWaiter,
      description: context.l10n.roleWaiterDesc,
      icon: PhosphorIcons.bellSimple(PhosphorIconsStyle.duotone),
      color: AppColors.primary,
    ),
    _RoleOption(
      value: 'kitchen',
      label: context.l10n.roleKitchen,
      description: context.l10n.roleKitchenDesc,
      icon: PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
      color: AppColors.warning,
    ),
    _RoleOption(
      value: 'viewer',
      label: context.l10n.roleViewer,
      description: context.l10n.roleViewerDesc,
      icon: PhosphorIcons.eye(PhosphorIconsStyle.duotone),
      color: AppColors.grey500,
    ),
  ];

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    setState(() => _formSubmitted = true);
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final success = await ref
        .read(invitationNotifierProvider.notifier)
        .sendInvitation(
          email: _emailController.text.trim(),
          role: _selectedRole,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.inviteEmployeeSent(_emailController.text.trim()),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      );
      _emailController.clear();
      setState(() => _formSubmitted = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invState = ref.watch(invitationNotifierProvider);
    final theme = Theme.of(context);

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
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(
        title: context.l10n.inviteEmployeeTitle,
        leading: TactileWrapper(
          onTap: () => context.pop(),
          child: Icon(
            PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
            size: 20,
            color: AppColors.grey700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Form(
          key: _formKey,
          autovalidateMode: _formSubmitted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header ilustrativo
              Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        PhosphorIcons.userPlus(PhosphorIconsStyle.duotone),
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: AppTheme.durationFast)
                  .scaleXY(begin: 0.7, end: 1, curve: Curves.easeOutBack),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                context.l10n.inviteEmployeeHeading,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey900,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(
                delay: 100.ms,
                duration: AppTheme.durationFast,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                context.l10n.inviteEmployeeSubheading,
                style: const TextStyle(fontSize: 14, color: AppColors.grey500),
                textAlign: TextAlign.center,
              ).animate().fadeIn(
                delay: 150.ms,
                duration: AppTheme.durationFast,
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // Email
              LomeTextField(
                label: context.l10n.inviteEmployeeEmailLabel,
                hint: context.l10n.inviteEmployeeEmailHint,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                prefixIcon: Icon(
                  PhosphorIcons.envelope(PhosphorIconsStyle.duotone),
                  size: 20,
                ),
                validator: FormValidators.email,
              ).animate().fadeIn(
                delay: 200.ms,
                duration: AppTheme.durationFast,
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // Rol
              Text(
                context.l10n.inviteEmployeeRoleLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey800,
                ),
              ).animate().fadeIn(
                delay: 250.ms,
                duration: AppTheme.durationFast,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              ..._buildRoleOptions(context).asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = _selectedRole == option.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                  child: _buildRoleCard(option, isSelected, theme),
                ).animate().fadeIn(
                  delay: Duration(milliseconds: 300 + index * 80),
                  duration: AppTheme.durationFast,
                );
              }),

              const SizedBox(height: AppTheme.spacingLg),

              // Botón enviar
              LomeButton(
                label: 'Enviar invitación',
                isExpanded: true,
                isLoading: invState.isSending,
                onPressed: _handleSend,
                icon: PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.duotone),
              ).animate().fadeIn(
                delay: 600.ms,
                duration: AppTheme.durationFast,
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // Nota informativa
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      PhosphorIcons.info(PhosphorIconsStyle.duotone),
                      size: 18,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Text(
                        context.l10n.inviteEmployeeInfoNote,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.info,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(
                delay: 700.ms,
                duration: AppTheme.durationFast,
              ),

              const SizedBox(height: AppTheme.spacingLg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(_RoleOption option, bool isSelected, ThemeData theme) {
    return TactileWrapper(
      onTap: () => setState(() => _selectedRole = option.value),
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: isSelected
              ? option.color.withValues(alpha: 0.06)
              : AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected ? option.color : AppColors.grey200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: option.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(option.icon, color: option.color, size: 22),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? option.color : AppColors.grey800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: AppTheme.durationFast,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? option.color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? option.color : AppColors.grey300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                      PhosphorIcons.check(),
                      size: 14,
                      color: AppColors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleOption {
  final String value;
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const _RoleOption({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });
}
