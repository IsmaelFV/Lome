import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators/form_validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/cooking_decorations.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _formSubmitted = false;

  late final AnimationController _floatController;
  late final AnimationController _rotateController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authActionsProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _formSubmitted = true);
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final user = await ref
        .read(authActionsProvider.notifier)
        .signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (user != null && mounted) {
      if (user.isPlatformAdmin) {
        context.go(RoutePaths.admin);
      } else if (user.hasTenants) {
        ref.read(activeTenantIdProvider.notifier).state =
            user.defaultMembership!.tenantId;
        context.go(RoutePaths.tables);
      } else {
        context.go(RoutePaths.marketplace);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authActionsProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Curva decorativa verde superior (animada)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(size.width, size.height * 0.32),
                  painter: _HeaderCurvePainter(
                    progress: _floatController.value,
                  ),
                );
              },
            ),
          ).animate().fadeIn(duration: 800.ms),

          // Blobs decorativos suaves
          ..._buildSoftBlobs(size),

          // Elementos de cocina animados
          ...buildCookingDecorations(
            screenSize: size,
            floatController: _floatController,
            rotateController: _rotateController,
          ),

          // Contenido principal
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: size.height * 0.01),

                      _buildLogo()
                          .animate()
                          .fadeIn(duration: 700.ms)
                          .scaleXY(
                            begin: 0.7,
                            end: 1,
                            duration: 600.ms,
                            curve: Curves.easeOutBack,
                          ),

                      const SizedBox(height: 28),

                      Text(
                            context.l10n.loginTitle,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: AppColors.primaryDark,
                            ),
                            textAlign: TextAlign.center,
                          )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 500.ms)
                          .slideY(begin: 0.15, end: 0),

                      const SizedBox(height: 8),

                      Container(
                            width: 48,
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryLight,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 350.ms, duration: 400.ms)
                          .scaleX(begin: 0, end: 1, curve: Curves.easeOutCubic),

                      const SizedBox(height: 10),

                      Text(
                        context.l10n.loginSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

                      const SizedBox(height: 32),

                      _buildFormCard(
                            theme: theme,
                            isLoading: isLoading,
                            authState: authState,
                          )
                          .animate()
                          .fadeIn(delay: 450.ms, duration: 600.ms)
                          .slideY(
                            begin: 0.08,
                            end: 0,
                            curve: Curves.easeOutCubic,
                            duration: 600.ms,
                          ),

                      const SizedBox(height: 28),

                      _buildSeparator().animate().fadeIn(
                        delay: 650.ms,
                        duration: 400.ms,
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.l10n.loginNoAccount,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          GestureDetector(
                            onTap: isLoading
                                ? null
                                : () => context.pushNamed(RouteNames.register),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Text(
                                context.l10n.loginRegisterLink,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 750.ms, duration: 400.ms),

                      SizedBox(height: size.height * 0.03),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSoftBlobs(Size size) {
    return [
      // Blob superior derecho
      Positioned(
        top: size.height * 0.08,
        right: -size.width * 0.12,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, _) {
            final dy = math.sin(_floatController.value * math.pi) * 12;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Container(
                width: size.width * 0.45,
                height: size.width * 0.45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryLight.withValues(alpha: 0.07),
                      AppColors.primaryLight.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ).animate().fadeIn(delay: 400.ms, duration: 1200.ms),

      // Blob inferior izquierdo
      Positioned(
        bottom: size.height * 0.05,
        left: -size.width * 0.1,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, _) {
            final dy = math.cos(_floatController.value * math.pi) * 10;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Container(
                width: size.width * 0.5,
                height: size.width * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.05),
                      AppColors.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ).animate().fadeIn(delay: 600.ms, duration: 1200.ms),

      // Blob central sutil
      Positioned(
        top: size.height * 0.45,
        left: size.width * 0.2,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, _) {
            final dx = math.sin(_floatController.value * math.pi + 1) * 8;
            return Transform.translate(
              offset: Offset(dx, 0),
              child: Container(
                width: size.width * 0.28,
                height: size.width * 0.28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF22C55E).withValues(alpha: 0.04),
                      const Color(0xFF22C55E).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ).animate().fadeIn(delay: 800.ms, duration: 1200.ms),
    ];
  }

  Widget _buildSeparator() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xFFE5E7EB)],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(
            PhosphorIcons.forkKnife(),
            size: 18,
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE5E7EB), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard({
    required ThemeData theme,
    required bool isLoading,
    required AsyncValue<void> authState,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            autovalidateMode: _formSubmitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLabel(context.l10n.email),
                const SizedBox(height: 6),
                _buildInput(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      hint: context.l10n.loginEmailHint,
                      icon: PhosphorIcons.envelope(),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: FormValidators.email,
                    )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 400.ms)
                    .slideX(begin: -0.04, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 18),

                _buildLabel(context.l10n.password),
                const SizedBox(height: 6),
                _buildInput(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      hint: context.l10n.loginPasswordHint,
                      icon: PhosphorIcons.lock(),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      validator: (v) =>
                          FormValidators.required(v, 'La contraseña'),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? PhosphorIcons.eyeSlash()
                              : PhosphorIcons.eye(),
                          size: 20,
                          color: const Color(0xFF9CA3AF),
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 580.ms, duration: 400.ms)
                    .slideX(begin: -0.04, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 6),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () => context.pushNamed(RouteNames.forgotPassword),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      context.l10n.forgotPassword,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                _buildErrorMessage(authState),

                AbsorbPointer(
                  absorbing: isLoading,
                  child: _buildLoginButton(isLoading),
                ).animate().fadeIn(delay: 660.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      style: const TextStyle(color: Color(0xFF1F2937), fontSize: 15),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB0B7C3), fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.6)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: TextStyle(
          color: AppColors.error.withValues(alpha: 0.9),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF374151),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _handleLogin,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          final pulse = _pulseController.value * 0.08;
          return Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF22C55E)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25 + pulse),
                  blurRadius: 16 + pulse * 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n.loginButton,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                              PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                              color: Colors.white,
                              size: 20,
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .moveX(
                              begin: 0,
                              end: 4,
                              duration: 1200.ms,
                              curve: Curves.easeInOut,
                            ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final scale = 1.0 + _pulseController.value * 0.03;
              final glow = 0.20 + _pulseController.value * 0.10;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        Color(0xFF22C55E),
                        AppColors.primaryDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: glow),
                        blurRadius: 24,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'L',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          const Text(
            'LOME',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDark,
              letterSpacing: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.platformTagline,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.primary.withValues(alpha: 0.5),
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(AsyncValue<void> authState) {
    if (!authState.hasError) return const SizedBox.shrink();

    return Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(
                PhosphorIcons.warningCircle(),
                color: AppColors.error.withValues(alpha: 0.8),
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  authState.error.toString(),
                  style: TextStyle(
                    color: AppColors.error.withValues(alpha: 0.9),
                    fontSize: 13,
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

class _HeaderCurvePainter extends CustomPainter {
  final double progress;

  _HeaderCurvePainter({this.progress = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final shift = math.sin(progress * math.pi) * size.height * 0.03;

    final mainPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, Color(0xFF22C55E)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final mainPath = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height * 0.65 + shift)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.85 + shift,
        size.width * 0.5,
        size.height * 0.72 - shift * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.58 - shift,
        size.width,
        size.height * 0.75 + shift * 0.7,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(mainPath, mainPaint);

    final lightPaint = Paint()
      ..color = AppColors.primaryLight.withValues(alpha: 0.12);

    final lightPath = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height * 0.55 - shift * 0.5)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.75 - shift,
        size.width * 0.6,
        size.height * 0.60 + shift * 0.3,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.45 + shift,
        size.width,
        size.height * 0.62 - shift * 0.5,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(lightPath, lightPaint);
  }

  @override
  bool shouldRepaint(covariant _HeaderCurvePainter old) =>
      old.progress != progress;
}
