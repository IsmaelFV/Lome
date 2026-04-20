import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _pulseController;
  late final AnimationController _driftController;
  late final AnimationController _slowController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _slowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _driftController.dispose();
    _slowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Formas abstractas geométricas ──
          ..._buildAbstractShapes(size),

          // ── Lluvia de iconos de comida por TODA la pantalla ──
          ..._buildFoodIcons(size),

          // ── Contenido principal ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.12),

                  // Logo + nombre
                  AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final scale = 1.0 + _pulseController.value * 0.03;
                          final glow = 0.22 + _pulseController.value * 0.12;
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 88,
                              height: 88,
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
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: glow,
                                    ),
                                    blurRadius: 32,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'L',
                                  style: TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                      .animate()
                      .fadeIn(duration: 700.ms)
                      .scaleXY(
                        begin: 0.4,
                        end: 1,
                        duration: 700.ms,
                        curve: Curves.easeOutBack,
                      ),

                  const SizedBox(height: 14),

                  const Text(
                        'LOME',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                          letterSpacing: 10,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 600.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 4),

                  Text(
                    context.l10n.platformTagline,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary.withValues(alpha: 0.5),
                      letterSpacing: 3,
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

                  const Spacer(flex: 2),

                  // Titulo
                  Text(
                        context.l10n.welcomeTitle,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          letterSpacing: -0.5,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 600.ms)
                      .slideY(begin: 0.12, end: 0),

                  const SizedBox(height: 10),

                  Container(
                        width: 48,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 480.ms, duration: 400.ms)
                      .scaleX(begin: 0, end: 1, curve: Curves.easeOutCubic),

                  const SizedBox(height: 14),

                  Text(
                    context.l10n.welcomeSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 550.ms, duration: 600.ms),

                  const Spacer(flex: 3),

                  // Botones
                  GestureDetector(
                        onTap: () => context.goNamed(RouteNames.login),
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final p = _pulseController.value * 0.06;
                            return Container(
                              width: double.infinity,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    Color(0xFF22C55E),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.25 + p,
                                    ),
                                    blurRadius: 16 + p * 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: child,
                            );
                          },
                          child: Center(
                            child: Text(
                              context.l10n.welcomeLoginButton,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 650.ms, duration: 500.ms)
                      .slideY(begin: 0.15, end: 0),

                  const SizedBox(height: 14),

                  SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () =>
                              context.pushNamed(RouteNames.register),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            context.l10n.welcomeRegisterButton,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 750.ms, duration: 500.ms)
                      .slideY(begin: 0.15, end: 0),

                  SizedBox(height: size.height * 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Formas abstractas geométricas: bloques, círculos, rectángulos redondeados
  // Combinando distintos tonos de verde + blanco
  // ═══════════════════════════════════════════════════════════════════════════
  List<Widget> _buildAbstractShapes(Size size) {
    return [
      // ── Gran bloque diagonal superior derecho ──
      Positioned(
        top: -size.height * 0.06,
        right: -size.width * 0.12,
        child: AnimatedBuilder(
          animation: _slowController,
          builder: (context, _) {
            final dy = math.sin(_slowController.value * math.pi) * 10;
            final dx = math.cos(_slowController.value * math.pi * 0.6) * 6;
            return Transform.translate(
              offset: Offset(dx, dy),
              child: Transform.rotate(
                angle: -0.35,
                child: Container(
                  width: size.width * 0.55,
                  height: size.height * 0.22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.12),
                        const Color(0xFF22C55E).withValues(alpha: 0.06),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),

      // ── Circulo grande esquina inferior izquierda ──
      Positioned(
        bottom: -size.width * 0.18,
        left: -size.width * 0.15,
        child: AnimatedBuilder(
          animation: _driftController,
          builder: (context, _) {
            final dy = math.cos(_driftController.value * math.pi) * 14;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.07),
                ),
              ),
            );
          },
        ),
      ),

      // ── Bloque redondeado medio-izquierda ──
      Positioned(
        top: size.height * 0.32,
        left: -size.width * 0.08,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, _) {
            final dy = math.sin(_floatController.value * math.pi + 1) * 8;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Transform.rotate(
                angle: 0.2,
                child: Container(
                  width: size.width * 0.35,
                  height: size.height * 0.12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: const Color(0xFFA3E635).withValues(alpha: 0.10),
                  ),
                ),
              ),
            );
          },
        ),
      ),

      // ── Circulo mediano superior izquierda ──
      Positioned(
        top: size.height * 0.04,
        left: -size.width * 0.06,
        child: AnimatedBuilder(
          animation: _slowController,
          builder: (context, _) {
            final dy = math.sin(_slowController.value * math.pi + 2) * 10;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Container(
                width: size.width * 0.28,
                height: size.width * 0.28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF22C55E).withValues(alpha: 0.08),
                ),
              ),
            );
          },
        ),
      ),

      // ── Bloque diagonal inferior derecho ──
      Positioned(
        bottom: size.height * 0.08,
        right: -size.width * 0.10,
        child: AnimatedBuilder(
          animation: _driftController,
          builder: (context, _) {
            final dx = math.sin(_driftController.value * math.pi + 0.5) * 8;
            return Transform.translate(
              offset: Offset(dx, 0),
              child: Transform.rotate(
                angle: 0.4,
                child: Container(
                  width: size.width * 0.45,
                  height: size.height * 0.10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryDark.withValues(alpha: 0.08),
                        const Color(0xFF22C55E).withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),

      // ── Circulo pequeño flotante derecho-medio ──
      Positioned(
        top: size.height * 0.50,
        right: size.width * 0.05,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, _) {
            final dy = math.cos(_floatController.value * math.pi + 0.8) * 12;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.10),
                ),
              ),
            );
          },
        ),
      ),

      // ── Rectángulo vertical derecho ──
      Positioned(
        top: size.height * 0.18,
        right: size.width * 0.02,
        child: AnimatedBuilder(
          animation: _slowController,
          builder: (context, _) {
            final dy = math.sin(_slowController.value * math.pi + 3) * 6;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Container(
                width: 18,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: const Color(0xFFA3E635).withValues(alpha: 0.14),
                ),
              ),
            );
          },
        ),
      ),

      // ── Circulito esquina superior derecho ──
      Positioned(
        top: size.height * 0.08,
        right: size.width * 0.20,
        child: AnimatedBuilder(
          animation: _driftController,
          builder: (context, _) {
            final dy = math.sin(_driftController.value * math.pi) * 5;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.18),
                ),
              ),
            );
          },
        ),
      ),

      // ── Bloque ancho inferior ──
      Positioned(
        bottom: size.height * 0.25,
        left: size.width * 0.10,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, _) {
            final dx = math.cos(_floatController.value * math.pi * 0.7) * 10;
            return Transform.translate(
              offset: Offset(dx, 0),
              child: Container(
                width: size.width * 0.28,
                height: 14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                ),
              ),
            );
          },
        ),
      ),

      // ── Circulo medio inferior centro ──
      Positioned(
        bottom: size.height * 0.32,
        left: size.width * 0.42,
        child: AnimatedBuilder(
          animation: _slowController,
          builder: (context, _) {
            final dy = math.cos(_slowController.value * math.pi + 1) * 8;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryDark.withValues(alpha: 0.08),
                ),
              ),
            );
          },
        ),
      ),

      // ── Pastilla diagonal centro-superior ──
      Positioned(
        top: size.height * 0.22,
        left: size.width * 0.30,
        child: AnimatedBuilder(
          animation: _driftController,
          builder: (context, _) {
            final dy = math.sin(_driftController.value * math.pi + 1.5) * 7;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Transform.rotate(
                angle: -0.6,
                child: Container(
                  width: 60,
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.primary.withValues(alpha: 0.10),
                  ),
                ),
              ),
            );
          },
        ),
      ),

      // ── Dot pequeño izquierda-medio ──
      Positioned(
        top: size.height * 0.44,
        left: size.width * 0.12,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, _) {
            final dy = math.sin(_floatController.value * math.pi + 2.5) * 6;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFA3E635).withValues(alpha: 0.20),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Muchos iconos de comida animados por TODA la pantalla
  // ═══════════════════════════════════════════════════════════════════════════
  List<Widget> _buildFoodIcons(Size size) {
    final icons = <_FoodIconData>[
      // ── Columna izquierda ──
      _FoodIconData(
        PhosphorIcons.hamburger(PhosphorIconsStyle.duotone),
        0.03,
        null,
        0.04,
        null,
        30,
        0.0,
        0.16,
      ),
      _FoodIconData(
        PhosphorIcons.coffee(PhosphorIconsStyle.duotone),
        0.11,
        null,
        0.14,
        null,
        24,
        0.8,
        0.12,
      ),
      _FoodIconData(
        PhosphorIcons.egg(PhosphorIconsStyle.duotone),
        0.20,
        null,
        0.02,
        null,
        22,
        1.5,
        0.10,
      ),
      _FoodIconData(
        PhosphorIcons.cookie(PhosphorIconsStyle.duotone),
        0.30,
        null,
        0.08,
        null,
        26,
        2.1,
        0.14,
      ),
      _FoodIconData(
        PhosphorIcons.bowlSteam(PhosphorIconsStyle.duotone),
        0.40,
        null,
        0.03,
        null,
        28,
        0.4,
        0.15,
      ),
      _FoodIconData(
        PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
        0.49,
        null,
        0.12,
        null,
        22,
        1.2,
        0.11,
      ),
      _FoodIconData(
        PhosphorIcons.martini(PhosphorIconsStyle.duotone),
        0.58,
        null,
        0.05,
        null,
        24,
        2.8,
        0.13,
      ),
      _FoodIconData(
        PhosphorIcons.bowlFood(PhosphorIconsStyle.duotone),
        0.66,
        null,
        0.10,
        null,
        20,
        0.6,
        0.10,
      ),
      _FoodIconData(
        PhosphorIcons.bread(PhosphorIconsStyle.duotone),
        0.75,
        null,
        0.02,
        null,
        26,
        1.9,
        0.14,
      ),
      _FoodIconData(
        PhosphorIcons.cookingPot(PhosphorIconsStyle.duotone),
        0.84,
        null,
        0.08,
        null,
        22,
        3.2,
        0.12,
      ),
      _FoodIconData(
        PhosphorIcons.knife(PhosphorIconsStyle.duotone),
        0.92,
        null,
        0.14,
        null,
        20,
        0.3,
        0.10,
      ),

      // ── Columna centro-izquierda ──
      _FoodIconData(
        PhosphorIcons.pizza(PhosphorIconsStyle.duotone),
        0.06,
        null,
        0.28,
        null,
        26,
        1.0,
        0.13,
      ),
      _FoodIconData(
        PhosphorIcons.iceCream(PhosphorIconsStyle.duotone),
        0.16,
        null,
        0.34,
        null,
        20,
        2.4,
        0.10,
      ),
      _FoodIconData(
        PhosphorIcons.fire(PhosphorIconsStyle.duotone),
        0.27,
        null,
        0.26,
        null,
        24,
        0.5,
        0.12,
      ),
      _FoodIconData(
        PhosphorIcons.wine(PhosphorIconsStyle.duotone),
        0.37,
        null,
        0.32,
        null,
        18,
        1.7,
        0.09,
      ),
      _FoodIconData(
        PhosphorIcons.hamburger(PhosphorIconsStyle.duotone),
        0.47,
        null,
        0.28,
        null,
        22,
        3.0,
        0.11,
      ),
      _FoodIconData(
        PhosphorIcons.fish(PhosphorIconsStyle.duotone),
        0.56,
        null,
        0.35,
        null,
        20,
        0.9,
        0.10,
      ),
      _FoodIconData(
        PhosphorIcons.coffee(PhosphorIconsStyle.duotone),
        0.65,
        null,
        0.25,
        null,
        24,
        2.2,
        0.13,
      ),
      _FoodIconData(
        PhosphorIcons.cake(PhosphorIconsStyle.duotone),
        0.74,
        null,
        0.30,
        null,
        22,
        1.4,
        0.12,
      ),
      _FoodIconData(
        PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
        0.83,
        null,
        0.28,
        null,
        26,
        0.1,
        0.14,
      ),

      // ── Columna centro-derecha ──
      _FoodIconData(
        PhosphorIcons.hamburger(PhosphorIconsStyle.duotone),
        0.04,
        null,
        null,
        0.28,
        24,
        2.0,
        0.12,
      ),
      _FoodIconData(
        PhosphorIcons.coffee(PhosphorIconsStyle.duotone),
        0.14,
        null,
        null,
        0.34,
        20,
        0.7,
        0.10,
      ),
      _FoodIconData(
        PhosphorIcons.bread(PhosphorIconsStyle.duotone),
        0.24,
        null,
        null,
        0.26,
        26,
        1.3,
        0.14,
      ),
      _FoodIconData(
        PhosphorIcons.knife(PhosphorIconsStyle.duotone),
        0.34,
        null,
        null,
        0.32,
        18,
        2.6,
        0.09,
      ),
      _FoodIconData(
        PhosphorIcons.package(PhosphorIconsStyle.duotone),
        0.44,
        null,
        null,
        0.28,
        24,
        0.2,
        0.12,
      ),
      _FoodIconData(
        PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
        0.53,
        null,
        null,
        0.34,
        22,
        1.8,
        0.11,
      ),
      _FoodIconData(
        PhosphorIcons.bookOpenText(PhosphorIconsStyle.duotone),
        0.62,
        null,
        null,
        0.26,
        20,
        3.4,
        0.10,
      ),
      _FoodIconData(
        PhosphorIcons.cookie(PhosphorIconsStyle.duotone),
        0.72,
        null,
        null,
        0.30,
        24,
        0.8,
        0.13,
      ),
      _FoodIconData(
        PhosphorIcons.hamburger(PhosphorIconsStyle.duotone),
        0.81,
        null,
        null,
        0.28,
        22,
        2.3,
        0.12,
      ),
      _FoodIconData(
        PhosphorIcons.coffee(PhosphorIconsStyle.duotone),
        0.90,
        null,
        null,
        0.34,
        20,
        1.1,
        0.10,
      ),

      // ── Columna derecha ──
      _FoodIconData(
        PhosphorIcons.pizza(PhosphorIconsStyle.duotone),
        0.02,
        null,
        null,
        0.04,
        28,
        1.6,
        0.15,
      ),
      _FoodIconData(
        PhosphorIcons.bread(PhosphorIconsStyle.duotone),
        0.10,
        null,
        null,
        0.10,
        24,
        0.3,
        0.12,
      ),
      _FoodIconData(
        PhosphorIcons.bowlSteam(PhosphorIconsStyle.duotone),
        0.19,
        null,
        null,
        0.06,
        22,
        2.5,
        0.11,
      ),
      _FoodIconData(
        PhosphorIcons.cake(PhosphorIconsStyle.duotone),
        0.28,
        null,
        null,
        0.14,
        20,
        1.1,
        0.10,
      ),
      _FoodIconData(
        PhosphorIcons.iceCream(PhosphorIconsStyle.duotone),
        0.38,
        null,
        null,
        0.04,
        26,
        3.1,
        0.14,
      ),
      _FoodIconData(
        PhosphorIcons.egg(PhosphorIconsStyle.duotone),
        0.48,
        null,
        null,
        0.12,
        22,
        0.7,
        0.11,
      ),
      _FoodIconData(
        PhosphorIcons.cookingPot(PhosphorIconsStyle.duotone),
        0.57,
        null,
        null,
        0.05,
        24,
        2.0,
        0.13,
      ),
      _FoodIconData(
        PhosphorIcons.wine(PhosphorIconsStyle.duotone),
        0.67,
        null,
        null,
        0.10,
        18,
        1.4,
        0.09,
      ),
      _FoodIconData(
        PhosphorIcons.hamburger(PhosphorIconsStyle.duotone),
        0.76,
        null,
        null,
        0.03,
        26,
        2.8,
        0.14,
      ),
      _FoodIconData(
        PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
        0.85,
        null,
        null,
        0.12,
        22,
        0.5,
        0.12,
      ),
      _FoodIconData(
        PhosphorIcons.martini(PhosphorIconsStyle.duotone),
        0.93,
        null,
        null,
        0.06,
        20,
        1.9,
        0.10,
      ),
    ];

    return icons.asMap().entries.map((entry) {
      final i = entry.key;
      final d = entry.value;
      final delay = (100 + i * 40).ms;

      // Alternar controllers para variedad de movimiento
      final controllers = [_floatController, _driftController, _slowController];
      final ctrl = controllers[i % 3];

      return Positioned(
        top: d.top != null ? size.height * d.top! : null,
        bottom: d.bottom != null ? size.height * d.bottom! : null,
        left: d.left != null ? size.width * d.left! : null,
        right: d.right != null ? size.width * d.right! : null,
        child: AnimatedBuilder(
          animation: ctrl,
          builder: (context, child) {
            final dy =
                math.sin(ctrl.value * math.pi + d.phase) * (4 + (i % 5) * 1.2);
            final dx =
                math.cos(ctrl.value * math.pi * 0.7 + d.phase) *
                (2 + (i % 4) * 0.8);
            final rotate = math.sin(ctrl.value * math.pi + d.phase) * 0.15;
            return Transform.translate(
              offset: Offset(dx, dy),
              child: Transform.rotate(angle: rotate, child: child),
            );
          },
          child: Icon(
            d.icon,
            size: d.size,
            color: AppColors.primary.withValues(alpha: d.alpha),
          ),
        ),
      ).animate().fadeIn(delay: delay, duration: 800.ms);
    }).toList();
  }
}

class _FoodIconData {
  final IconData icon;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final double phase;
  final double alpha;

  const _FoodIconData(
    this.icon,
    this.top,
    this.bottom,
    this.left,
    this.right,
    this.size,
    this.phase,
    this.alpha,
  );
}
