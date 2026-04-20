import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lome_button.dart';
import '../providers/auth_provider.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

/// Pantalla de verificación de email tras el registro.
///
/// Muestra un mensaje indicando que se ha enviado un email de verificación.
/// Permite reenviar el email y proporciona un enlace para ir al login
/// una vez verificada la cuenta.
class EmailVerificationPage extends ConsumerStatefulWidget {
  final String email;

  const EmailVerificationPage({super.key, required this.email});

  @override
  ConsumerState<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState extends ConsumerState<EmailVerificationPage> {
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 1) {
        timer.cancel();
        if (mounted) setState(() => _resendCooldown = 0);
      } else {
        if (mounted) setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _handleResend() async {
    if (_resendCooldown > 0) return;

    final success = await ref
        .read(authActionsProvider.notifier)
        .resendVerification(email: widget.email);

    if (success && mounted) {
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.emailVerificationSnackbar),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authActionsProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: AppTheme.spacingXl),

                  // ─── Icono animado ───
                  Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Icon(
                          PhosphorIcons.envelopeSimpleOpen(
                            PhosphorIconsStyle.duotone,
                          ),
                          size: 48,
                          color: AppColors.primary,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scaleXY(begin: 0.5, end: 1, curve: Curves.easeOutBack)
                      .then()
                      .shimmer(
                        delay: 800.ms,
                        duration: 1200.ms,
                        color: AppColors.primaryLight.withValues(alpha: 0.3),
                      ),

                  const SizedBox(height: AppTheme.spacingLg),

                  // ─── Título ───
                  Text(
                    context.l10n.emailVerificationTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                  const SizedBox(height: AppTheme.spacingMd),

                  // ─── Descripción ───
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.grey500,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: '${context.l10n.emailVerificationSentTo}\n',
                        ),
                        TextSpan(
                          text: widget.email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.grey800,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

                  const SizedBox(height: AppTheme.spacingXl),

                  // ─── Instrucciones ───
                  Container(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildStep(
                              number: '1',
                              text: context.l10n.emailVerificationStep1,
                            ),
                            const SizedBox(height: AppTheme.spacingSm),
                            _buildStep(
                              number: '2',
                              text: context.l10n.emailVerificationStep2,
                            ),
                            const SizedBox(height: AppTheme.spacingSm),
                            _buildStep(
                              number: '3',
                              text: context.l10n.emailVerificationStep3,
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 500.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: AppTheme.spacingXl),

                  // ─── Botón ir al login ───
                  LomeButton(
                    label: context.l10n.emailVerificationConfirm,
                    isExpanded: true,
                    onPressed: () => context.go(RoutePaths.login),
                  ).animate().fadeIn(delay: 500.ms, duration: 500.ms),

                  const SizedBox(height: AppTheme.spacingMd),

                  // ─── Reenviar email ───
                  AbsorbPointer(
                    absorbing: isLoading || _resendCooldown > 0,
                    child: TextButton(
                      onPressed: _handleResend,
                      child: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _resendCooldown > 0
                                  ? context.l10n
                                        .emailVerificationResendCountdown(
                                          _resendCooldown,
                                        )
                                  : context.l10n.emailVerificationNotReceived,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _resendCooldown > 0
                                    ? AppColors.grey400
                                    : AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                  const SizedBox(height: AppTheme.spacingMd),

                  // ─── Nota de spam ───
                  Text(
                    context.l10n.emailVerificationSpamNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.grey400,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 700.ms, duration: 400.ms),

                  const SizedBox(height: AppTheme.spacingXl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep({required String number, required String text}) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.grey600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
