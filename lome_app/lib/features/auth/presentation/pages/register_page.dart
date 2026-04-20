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
import '../../data/datasources/auth_remote_datasource.dart';
import '../providers/auth_provider.dart';
import '../widgets/cooking_decorations.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _restaurantNameController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _formSubmitted = false;
  AccountType _accountType = AccountType.customer;

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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _restaurantNameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _formSubmitted = true);
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final user = await ref
        .read(authActionsProvider.notifier)
        .signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          accountType: _accountType,
          restaurantName: _accountType == AccountType.restaurantOwner
              ? _restaurantNameController.text.trim()
              : null,
        );

    if (user != null && mounted) {
      // Si el email ya fue confirmado (auto-confirm), navegar al home correcto.
      // Si no, ir a la página de verificación de email.
      if (user.memberships.isNotEmpty ||
          _accountType == AccountType.restaurantOwner) {
        context.go(RoutePaths.restaurantOnboarding);
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
          // Curva decorativa verde superior animada
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) => CustomPaint(
                size: Size(size.width, size.height * 0.24),
                painter: _HeaderCurvePainter(progress: _floatController.value),
              ),
            ),
          ).animate().fadeIn(duration: 800.ms),

          // Blobs suaves flotantes
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
                      SizedBox(height: size.height * 0.005),

                      // Header con boton atras
                      Row(
                        children: [
                          if (GoRouter.of(context).canPop())
                            GestureDetector(
                              onTap: () => GoRouter.of(context).pop(),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  PhosphorIcons.caretLeft(
                                    PhosphorIconsStyle.bold,
                                  ),
                                  size: 18,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                        ],
                      ).animate().fadeIn(duration: 300.ms),

                      const SizedBox(height: 16),

                      // Mini logo
                      _buildMiniLogo()
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .scaleXY(
                            begin: 0.6,
                            end: 1,
                            duration: 700.ms,
                            curve: Curves.easeOutBack,
                          ),

                      const SizedBox(height: 20),

                      Text(
                            context.l10n.registerTitle,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: AppColors.primaryDark,
                            ),
                            textAlign: TextAlign.center,
                          )
                          .animate()
                          .fadeIn(delay: 100.ms, duration: 500.ms)
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
                          .fadeIn(delay: 200.ms, duration: 400.ms)
                          .scaleX(begin: 0, end: 1, curve: Curves.easeOutCubic),

                      const SizedBox(height: 10),

                      Text(
                        context.l10n.registerSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 250.ms, duration: 500.ms),

                      const SizedBox(height: 24),

                      // Selector de tipo de cuenta
                      _buildAccountTypeSelector().animate().fadeIn(
                        delay: 280.ms,
                        duration: 500.ms,
                      ),

                      const SizedBox(height: 20),

                      // Formulario
                      _buildFormCard(
                            theme: theme,
                            isLoading: isLoading,
                            authState: authState,
                          )
                          .animate()
                          .fadeIn(delay: 350.ms, duration: 600.ms)
                          .slideY(
                            begin: 0.08,
                            end: 0,
                            curve: Curves.easeOutCubic,
                            duration: 600.ms,
                          ),

                      const SizedBox(height: 20),

                      _buildSeparator().animate().fadeIn(
                        delay: 550.ms,
                        duration: 400.ms,
                      ),

                      const SizedBox(height: 16),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.l10n.registerHaveAccount,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          GestureDetector(
                            onTap: isLoading
                                ? null
                                : () => GoRouter.of(context).pop(),
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
                                context.l10n.registerLoginLink,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

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

  Widget _buildMiniLogo() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final value = _pulseController.value;
        final scale = 1.0 + value * 0.03;
        final glow = 0.20 + value * 0.10;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 56,
            height: 56,
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
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: glow),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'L',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildAccountTypeCard(
            icon: PhosphorIcons.shoppingBag(),
            label: context.l10n.registerAccountTypeCustomer,
            description: context.l10n.registerAccountTypeCustomerDesc,
            isSelected: _accountType == AccountType.customer,
            onTap: () => setState(() => _accountType = AccountType.customer),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAccountTypeCard(
            icon: PhosphorIcons.storefront(),
            label: context.l10n.registerAccountTypeRestaurant,
            description: context.l10n.registerAccountTypeRestaurantDesc,
            isSelected: _accountType == AccountType.restaurantOwner,
            onTap: () =>
                setState(() => _accountType = AccountType.restaurantOwner),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountTypeCard({
    required IconData icon,
    required String label,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.4)
                : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.10)
                    : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? AppColors.primary : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isSelected ? AppColors.primary : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSoftBlobs(Size size) {
    return [
      Positioned(
        top: size.height * 0.10,
        right: -40,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, _) => Transform.translate(
            offset: Offset(0, _floatController.value * 12),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryLight.withValues(alpha: 0.07),
                    AppColors.primaryLight.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: size.height * 0.18,
        left: -30,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, _) => Transform.translate(
            offset: Offset(0, -_floatController.value * 10),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.05),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        top: size.height * 0.55,
        right: size.width * 0.15,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, _) => Transform.translate(
            offset: Offset(0, _floatController.value * 8),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF22C55E).withValues(alpha: 0.04),
                    const Color(0xFF22C55E).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            autovalidateMode: _formSubmitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Nombre
                _buildLabel(
                  context.l10n.fullName,
                ).animate().fadeIn(delay: 380.ms, duration: 400.ms),
                const SizedBox(height: 6),
                _buildInput(
                      controller: _nameController,
                      hint: context.l10n.registerNameHint,
                      icon: PhosphorIcons.user(),
                      textInputAction: TextInputAction.next,
                      validator: (v) => FormValidators.required(v, 'El nombre'),
                    )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms)
                    .slideX(begin: -0.04, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 14),

                // Restaurante (condicional)
                if (_accountType == AccountType.restaurantOwner) ...[
                  _buildLabel(context.l10n.registerRestaurantNameLabel),
                  const SizedBox(height: 6),
                  _buildInput(
                        controller: _restaurantNameController,
                        hint: context.l10n.registerRestaurantNameHint,
                        icon: PhosphorIcons.storefront(),
                        textInputAction: TextInputAction.next,
                        validator: (v) => FormValidators.required(
                          v,
                          'El nombre del restaurante',
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.08, end: 0),
                  const SizedBox(height: 14),
                ],

                // Email
                _buildLabel(context.l10n.email),
                const SizedBox(height: 6),
                _buildInput(
                      controller: _emailController,
                      hint: context.l10n.registerEmailHint,
                      icon: PhosphorIcons.envelope(),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: FormValidators.email,
                    )
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 400.ms)
                    .slideX(begin: -0.04, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 14),

                // Telefono
                _buildLabel(context.l10n.registerPhoneLabel),
                const SizedBox(height: 6),
                _buildInput(
                      controller: _phoneController,
                      hint: context.l10n.registerPhoneHint,
                      icon: PhosphorIcons.phone(),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: FormValidators.phone,
                    )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 400.ms)
                    .slideX(begin: -0.04, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 14),

                // Password
                _buildLabel(context.l10n.password),
                const SizedBox(height: 6),
                _buildInput(
                      controller: _passwordController,
                      hint: context.l10n.registerPasswordLength,
                      icon: PhosphorIcons.lock(),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      validator: FormValidators.password,
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
                    .fadeIn(delay: 550.ms, duration: 400.ms)
                    .slideX(begin: -0.04, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 14),

                // Confirmar password
                _buildLabel(context.l10n.registerConfirmPasswordLabel),
                const SizedBox(height: 6),
                _buildInput(
                      controller: _confirmPasswordController,
                      hint: context.l10n.registerConfirmPasswordHint,
                      icon: PhosphorIcons.lock(),
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      validator: (v) => FormValidators.confirmPassword(
                        v,
                        _passwordController.text,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? PhosphorIcons.eyeSlash()
                              : PhosphorIcons.eye(),
                          size: 20,
                          color: const Color(0xFF9CA3AF),
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 400.ms)
                    .slideX(begin: -0.04, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 18),

                _buildErrorMessage(authState),

                AbsorbPointer(
                  absorbing: isLoading,
                  child: _buildRegisterButton(isLoading),
                ).animate().fadeIn(delay: 650.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
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

  Widget _buildRegisterButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _handleRegister,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
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
            child: child,
          );
        },
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
                      _accountType == AccountType.customer
                          ? context.l10n.registerButton
                          : context.l10n.registerCreateRestaurantButton,
                      style: const TextStyle(
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
  _HeaderCurvePainter({required this.progress});

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
      ..lineTo(0, size.height * 0.60)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.80 + shift,
        size.width * 0.5,
        size.height * 0.68,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.55 - shift,
        size.width,
        size.height * 0.72,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(mainPath, mainPaint);

    final lightPaint = Paint()
      ..color = AppColors.primaryLight.withValues(alpha: 0.12);

    final lightPath = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height * 0.50)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.70 - shift * 0.5,
        size.width * 0.6,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.42 + shift * 0.5,
        size.width,
        size.height * 0.58,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(lightPath, lightPaint);
  }

  @override
  bool shouldRepaint(covariant _HeaderCurvePainter old) =>
      old.progress != progress;
}
