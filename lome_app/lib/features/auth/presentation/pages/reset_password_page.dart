import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators/form_validators.dart';
import '../../../../core/widgets/lome_button.dart';
import '../../../../core/widgets/lome_text_field.dart';
import '../providers/auth_provider.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

/// Pantalla para establecer una nueva contraseña.
///
/// El usuario llega aquí tras abrir el enlace de recuperación que
/// Supabase envió a su email. En ese momento la sesión ya contiene
/// un access_token temporal de tipo «recovery» —generado por el flujo
/// PKCE— que autoriza la operación `updateUser(password)`.
///
/// Flujo completo:
/// 1. El usuario pidió recuperar contraseña → Supabase envió un email.
/// 2. El link del email redirige a la app (deep link / web redirect).
/// 3. Supabase Flutter detecta el callback y dispara
///    `AuthChangeEvent.passwordRecovery`.
/// 4. Nuestro `DeepLinkHandler` captura ese evento y navega aquí.
/// 5. El usuario introduce una nueva contraseña.
/// 6. Se llama a `auth.updateUser(UserAttributes(password: ...))`.
/// 7. Si la operación tiene éxito → se muestra confirmación → login.
///
/// El enlace caduca automáticamente según la configuración de Supabase
/// (por defecto 1 hora). Si el token ya expiró, `updateUser` devuelve
/// un error que se muestra al usuario.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _formSubmitted = false;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authActionsProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    setState(() => _formSubmitted = true);
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final ok = await ref
        .read(authActionsProvider.notifier)
        .updatePassword(newPassword: _passwordController.text);

    if (ok && mounted) {
      setState(() => _success = true);
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
              child: _success
                  ? _buildSuccessState(theme)
                  : _buildForm(theme, authState, isLoading),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Estado: formulario para nueva contraseña
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
          const SizedBox(height: AppTheme.spacingXl),

          // ─── Icono ───
          Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    PhosphorIcons.lockOpen(PhosphorIconsStyle.duotone),
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 500.ms)
              .scaleXY(begin: 0.7, end: 1, curve: Curves.easeOutBack),

          const SizedBox(height: AppTheme.spacingLg),

          // ─── Título ───
          Text(
            context.l10n.resetPasswordTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 150.ms, duration: 500.ms),

          const SizedBox(height: AppTheme.spacingSm),

          Text(
            context.l10n.resetPasswordSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.grey500,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

          const SizedBox(height: AppTheme.spacingXl),

          // ─── Nueva contraseña ───
          LomeTextField(
            label: context.l10n.resetPasswordNewHint,
            hint: context.l10n.registerPasswordLength,
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            prefixIcon: Icon(PhosphorIcons.lock(), size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? PhosphorIcons.eyeSlash()
                    : PhosphorIcons.eye(),
                size: 20,
                color: AppColors.grey400,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: FormValidators.password,
          ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

          const SizedBox(height: AppTheme.spacingMd),

          // ─── Confirmar contraseña ───
          LomeTextField(
            label: context.l10n.resetPasswordConfirmLabel,
            hint: context.l10n.resetPasswordConfirmHint,
            controller: _confirmController,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            prefixIcon: Icon(PhosphorIcons.lock(), size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? PhosphorIcons.eyeSlash()
                    : PhosphorIcons.eye(),
                size: 20,
                color: AppColors.grey400,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) =>
                FormValidators.confirmPassword(v, _passwordController.text),
          ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

          const SizedBox(height: AppTheme.spacingMd),

          // ─── Requisitos de contraseña ───
          _buildPasswordRequirements(
            theme,
          ).animate().fadeIn(delay: 450.ms, duration: 400.ms),

          const SizedBox(height: AppTheme.spacingLg),

          // ─── Error ───
          _buildErrorMessage(authState),

          // ─── Botón guardar ───
          AbsorbPointer(
            absorbing: isLoading,
            child: LomeButton(
              label: context.l10n.resetPasswordButton,
              isExpanded: true,
              isLoading: isLoading,
              onPressed: _handleReset,
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 500.ms),

          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Estado: contraseña actualizada
  // ---------------------------------------------------------------------------

  Widget _buildSuccessState(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppTheme.spacingXxl),

        // ─── Icono de éxito ───
        Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                PhosphorIcons.checkCircle(PhosphorIconsStyle.duotone),
                size: 52,
                color: AppColors.success,
              ),
            )
            .animate()
            .fadeIn(duration: 500.ms)
            .scaleXY(begin: 0.5, end: 1, curve: Curves.easeOutBack),

        const SizedBox(height: AppTheme.spacingLg),

        Text(
          context.l10n.resetPasswordSuccess,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

        const SizedBox(height: AppTheme.spacingSm),

        Text(
          context.l10n.resetPasswordSuccessMessage,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.grey500,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

        const SizedBox(height: AppTheme.spacingXl),

        LomeButton(
          label: context.l10n.loginButton,
          isExpanded: true,
          onPressed: () => context.go(RoutePaths.login),
        ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

        const SizedBox(height: AppTheme.spacingXl),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Subwidgets
  // ---------------------------------------------------------------------------

  Widget _buildPasswordRequirements(ThemeData theme) {
    final password = _passwordController.text;
    final hasMin = password.length >= 8;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(
      RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_+=\[\]\\/~`]'),
    );

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.passwordRequirementsTitle,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.grey600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _buildRequirement(context.l10n.registerPasswordLength, hasMin),
          const SizedBox(height: 4),
          _buildRequirement(context.l10n.registerPasswordUppercase, hasUpper),
          const SizedBox(height: 4),
          _buildRequirement(context.l10n.registerPasswordNumber, hasNumber),
          const SizedBox(height: 4),
          _buildRequirement(context.l10n.registerPasswordSpecial, hasSpecial),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet
              ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
              : PhosphorIcons.circle(),
          size: 16,
          color: isMet ? AppColors.success : AppColors.grey400,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isMet ? AppColors.success : AppColors.grey500,
            fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(AsyncValue<void> authState) {
    if (!authState.hasError) return const SizedBox.shrink();

    return Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .shakeX(hz: 3, amount: 4, duration: 400.ms);
  }
}
