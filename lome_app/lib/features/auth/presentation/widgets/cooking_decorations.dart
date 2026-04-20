import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';

// =============================================================================
// Elementos decorativos de cocina para las pantallas de autenticación
// =============================================================================

/// Genera una lista de iconos de cocina prominentes posicionados para un Stack.
/// Usa Material Icons filled para mayor impacto visual.
List<Widget> buildCookingDecorations({
  required Size screenSize,
  required AnimationController floatController,
  required AnimationController rotateController,
  double opacity = 0.18,
}) {
  final color = AppColors.primary;

  return [
    // ─── Hamburguesa - superior derecha ───
    _buildFloatingIcon(
      icon: PhosphorIcons.hamburger(PhosphorIconsStyle.duotone),
      top: screenSize.height * 0.04,
      right: screenSize.width * 0.05,
      size: 48,
      color: color.withValues(alpha: opacity),
      controller: floatController,
      phaseOffset: 0,
      floatAmount: 8,
      rotation: -0.15,
    ).animate().fadeIn(delay: 400.ms, duration: 1200.ms),

    // ─── Taza de café - superior izquierda ───
    _buildFloatingIcon(
      icon: PhosphorIcons.coffee(PhosphorIconsStyle.duotone),
      top: screenSize.height * 0.08,
      left: screenSize.width * 0.06,
      size: 40,
      color: color.withValues(alpha: opacity * 0.9),
      controller: floatController,
      phaseOffset: 1.0,
      floatAmount: 5,
      rotation: 0.12,
    ).animate().fadeIn(delay: 500.ms, duration: 1200.ms),

    // ─── Pizza - centro derecha ───
    _buildFloatingIcon(
      icon: PhosphorIcons.pizza(PhosphorIconsStyle.duotone),
      top: screenSize.height * 0.36,
      right: screenSize.width * 0.03,
      size: 38,
      color: color.withValues(alpha: opacity * 0.8),
      controller: rotateController,
      phaseOffset: 0,
      floatAmount: 0,
      rotation: 0,
      useSlowSpin: true,
    ).animate().fadeIn(delay: 800.ms, duration: 1200.ms),

    // ─── Cubiertos cruzados - inferior izquierda ───
    _buildFloatingIcon(
      icon: PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
      bottom: screenSize.height * 0.08,
      left: screenSize.width * 0.06,
      size: 44,
      color: color.withValues(alpha: opacity),
      controller: floatController,
      phaseOffset: 0.5,
      floatAmount: 6,
      rotation: 0.2,
    ).animate().fadeIn(delay: 600.ms, duration: 1200.ms),

    // ─── Croissant / panadería - inferior derecha ───
    _buildFloatingIcon(
      icon: PhosphorIcons.bread(PhosphorIconsStyle.duotone),
      bottom: screenSize.height * 0.12,
      right: screenSize.width * 0.07,
      size: 42,
      color: color.withValues(alpha: opacity * 0.85),
      controller: floatController,
      phaseOffset: 2.1,
      floatAmount: 7,
      rotation: -0.1,
    ).animate().fadeIn(delay: 700.ms, duration: 1200.ms),

    // ─── Bowl de ramen - centro izquierda ───
    _buildFloatingIcon(
      icon: PhosphorIcons.bowlSteam(PhosphorIconsStyle.duotone),
      top: screenSize.height * 0.52,
      left: screenSize.width * 0.02,
      size: 36,
      color: color.withValues(alpha: opacity * 0.7),
      controller: floatController,
      phaseOffset: 1.5,
      floatAmount: 5,
      rotation: 0.08,
    ).animate().fadeIn(delay: 900.ms, duration: 1200.ms),

    // ─── Helado - arriba centro-derecha ───
    _buildFloatingIcon(
      icon: PhosphorIcons.iceCream(PhosphorIconsStyle.duotone),
      top: screenSize.height * 0.18,
      right: screenSize.width * 0.28,
      size: 30,
      color: color.withValues(alpha: opacity * 0.6),
      controller: floatController,
      phaseOffset: 0.8,
      floatAmount: 4,
      rotation: 0.15,
    ).animate().fadeIn(delay: 1000.ms, duration: 1200.ms),
  ];
}

/// Crea un icono flotante animado posicionado.
Widget _buildFloatingIcon({
  required IconData icon,
  required double size,
  required Color color,
  required AnimationController controller,
  required double phaseOffset,
  required double floatAmount,
  required double rotation,
  double? top,
  double? bottom,
  double? left,
  double? right,
  bool useSlowSpin = false,
}) {
  return Positioned(
    top: top,
    bottom: bottom,
    left: left,
    right: right,
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        if (useSlowSpin) {
          final angle = controller.value * math.pi * 2 * 0.06;
          return Transform.rotate(angle: angle, child: child);
        }
        final dy =
            math.sin(controller.value * math.pi + phaseOffset) * floatAmount;
        final scale =
            1.0 + math.sin(controller.value * math.pi + phaseOffset) * 0.04;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(
            scale: scale,
            child: Transform.rotate(angle: rotation, child: child),
          ),
        );
      },
      child: Icon(icon, size: size, color: color),
    ),
  );
}
