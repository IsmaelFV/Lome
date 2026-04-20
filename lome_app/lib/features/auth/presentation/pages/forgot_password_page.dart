import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators/form_validators.dart';
import '../../../../core/widgets/lome_button.dart';
import '../../../../core/widgets/lome_text_field.dart';
import '../providers/auth_provider.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

/// Pantalla de recuperación de contraseña.
///
/// Flujo:
/// 1. El usuario introduce su email
/// 2. Flutter llama a Supabase Auth resetPasswordForEmail
/// 3. Supabase envía un correo con enlace para restablecer la contraseña
/// 4. Se muestra confirmación al usuario
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;
  bool _formSubmitted = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authActionsProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleResetPassword() async {
    setState(() => _formSubmitted = true);
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final success = await ref
        .read(authActionsProvider.notifier)
        .resetPassword(email: _emailController.text.trim());

    if (success && mounted) {
      _startCooldown();
      setState(() => _emailSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authActionsProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _emailSent
                  ? _buildSuccessState(theme)
                  : _buildForm(theme, authState, isLoading),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Estado: formulario para ingresar email
  // ---------------------------------------------------------------------------

  Widget _buildForm(
    ThemeData theme,
    AsyncValue<void> authState,
    bool isLoading,
  ) {
    return Form(
      key: _formKey,
      autovalidateMode: _formSubmitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Header ───
          Row(
            children: [
              if (GoRouter.of(context).canPop())
                IconButton(
                  icon: Icon(
                    PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
                    size: 20,
                  ),
                  onPressed: () => GoRouter.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.grey100,
                    fixedSize: const Size(40, 40),
                  ),
                ),
            ],
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: AppTheme.spacingXl),

          // ─── Icono ───
          Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    PhosphorIcons.lockKey(PhosphorIconsStyle.duotone),
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: 100.ms, duration: 500.ms)
              .scaleXY(begin: 0.8, end: 1, curve: Curves.easeOutBack),

          const SizedBox(height: AppTheme.spacingLg),

          // ─── Título ───
          Text(
            context.l10n.forgotPasswordTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

          const SizedBox(height: AppTheme.spacingSm),

          Text(
            context.l10n.forgotPasswordSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.grey500,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 250.ms, duration: 500.ms),

          const SizedBox(height: AppTheme.spacingXl),

          // ─── Campo Email ───
          LomeTextField(
            label: context.l10n.email,
            hint: context.l10n.forgotPasswordEmailHint,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            prefixIcon: Icon(PhosphorIcons.envelope(), size: 20),
            validator: FormValidators.email,
          ).animate().fadeIn(delay: 350.ms, duration: 500.ms),

          const SizedBox(height: AppTheme.spacingLg),

          // ─── Error ───
          if (authState.hasError)
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.warningCircle(),
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      authState.error.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

          // ─── Botón enviar ───
          AbsorbPointer(
            absorbing: isLoading,
            child: LomeButton(
              label: context.l10n.forgotPasswordSendButton,
              isExpanded: true,
              isLoading: isLoading,
              onPressed: _handleResetPassword,
            ),
          ).animate().fadeIn(delay: 450.ms, duration: 500.ms),

          const SizedBox(height: AppTheme.spacingLg),

          // ─── Volver al login ───
          Center(
            child: TextButton(
              onPressed: () => GoRouter.of(context).pop(),
              child: Text(
                context.l10n.forgotPasswordBackToLogin,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey500,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 550.ms, duration: 400.ms),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Estado: email enviado correctamente
  // ---------------------------------------------------------------------------

  Widget _buildSuccessState(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppTheme.spacingXxl),

        // ─── Icono de éxito ───
        Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                PhosphorIcons.envelopeOpen(PhosphorIconsStyle.duotone),
                size: 44,
                color: AppColors.success,
              ),
            )
            .animate()
            .fadeIn(duration: 500.ms)
            .scaleXY(begin: 0.5, end: 1, curve: Curves.easeOutBack),

        const SizedBox(height: AppTheme.spacingLg),

        Text(
          context.l10n.forgotPasswordSentTitle,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

        const SizedBox(height: AppTheme.spacingSm),

        Text(
          context.l10n.forgotPasswordSentDesc,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.grey500),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

        const SizedBox(height: AppTheme.spacingXs),

        Text(
          _emailController.text.trim(),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 350.ms, duration: 500.ms),

        const SizedBox(height: AppTheme.spacingSm),

        Text(
          context.l10n.forgotPasswordSentInstructions,
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.grey500),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

        const SizedBox(height: AppTheme.spacingXl),

        LomeButton(
          label: context.l10n.forgotPasswordBackToLogin,
          isExpanded: true,
          onPressed: () => GoRouter.of(context).pop(),
        ).animate().fadeIn(delay: 500.ms, duration: 500.ms),

        const SizedBox(height: AppTheme.spacingMd),

        TextButton(
          onPressed: _cooldownSeconds > 0
              ? null
              : () {
                  setState(() => _emailSent = false);
                  ref.read(authActionsProvider.notifier).clearError();
                },
          child: Text(
            _cooldownSeconds > 0
                ? '${context.l10n.forgotPasswordResendWait} (${_cooldownSeconds}s)'
                : context.l10n.forgotPasswordResend,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
      ],
    );
  }
}
