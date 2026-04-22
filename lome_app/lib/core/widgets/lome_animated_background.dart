import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Fondo con formas geometricas flotantes inspirado en las paginas
/// de welcome/login/register (gold standard del design system).
///
/// Dibuja circulos y rectangulos redondeados a diferentes niveles de
/// opacidad que se mueven suavemente usando AnimationControllers.
/// Adaptado a tonos verdes LOME.
class LomeAnimatedBackground extends StatefulWidget {
  final Widget child;
  final bool enableAnimation;
  final List<Color>? colors;

  const LomeAnimatedBackground({
    super.key,
    required this.child,
    this.enableAnimation = true,
    this.colors,
  });

  @override
  State<LomeAnimatedBackground> createState() => _LomeAnimatedBackgroundState();
}

class _LomeAnimatedBackgroundState extends State<LomeAnimatedBackground>
    with TickerProviderStateMixin {
  late final AnimationController _slowController;
  late final AnimationController _mediumController;

  @override
  void initState() {
    super.initState();
    _slowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _mediumController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    if (widget.enableAnimation) {
      _slowController.repeat(reverse: true);
      _mediumController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _slowController.dispose();
    _mediumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        widget.colors ??
        [AppColors.primary, AppColors.primaryLight, AppColors.success];

    return Stack(
      children: [
        // Background color
        const Positioned.fill(child: ColoredBox(color: AppColors.white)),

        // Animated shapes
        if (widget.enableAnimation)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_slowController, _mediumController]),
              builder: (context, _) => CustomPaint(
                painter: _BackgroundShapesPainter(
                  slowProgress: _slowController.value,
                  mediumProgress: _mediumController.value,
                  colors: colors,
                ),
              ),
            ),
          ),

        // Content
        widget.child,
      ],
    );
  }
}

class _BackgroundShapesPainter extends CustomPainter {
  final double slowProgress;
  final double mediumProgress;
  final List<Color> colors;

  _BackgroundShapesPainter({
    required this.slowProgress,
    required this.mediumProgress,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Circulo grande top-right
    canvas.drawCircle(
      Offset(
        w * 0.85 + math.sin(slowProgress * math.pi * 2) * 12,
        h * 0.12 + math.cos(slowProgress * math.pi * 2) * 8,
      ),
      w * 0.25,
      Paint()..color = colors[0].withValues(alpha: 0.05),
    );

    // Circulo mediano left
    canvas.drawCircle(
      Offset(
        w * 0.1 + math.cos(mediumProgress * math.pi * 2) * 10,
        h * 0.35 + math.sin(mediumProgress * math.pi * 2) * 15,
      ),
      w * 0.18,
      Paint()..color = colors[1].withValues(alpha: 0.06),
    );

    // Rectangulo redondeado bottom-right
    final rrRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(
          w * 0.78 + math.sin(mediumProgress * math.pi * 2) * 8,
          h * 0.72 + math.cos(slowProgress * math.pi * 2) * 12,
        ),
        width: w * 0.28,
        height: w * 0.16,
      ),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      rrRect,
      Paint()..color = colors[2].withValues(alpha: 0.04),
    );

    // Circulo pequeno central
    canvas.drawCircle(
      Offset(
        w * 0.45 + math.cos(slowProgress * math.pi * 2) * 6,
        h * 0.55 + math.sin(mediumProgress * math.pi * 2) * 10,
      ),
      w * 0.08,
      Paint()..color = colors[0].withValues(alpha: 0.07),
    );

    // Circulo grande bottom-left (difuso)
    canvas.drawCircle(
      Offset(
        w * 0.2 + math.sin(slowProgress * math.pi * 2) * 14,
        h * 0.88 + math.cos(mediumProgress * math.pi * 2) * 10,
      ),
      w * 0.22,
      Paint()..color = colors[1].withValues(alpha: 0.04),
    );
  }

  @override
  bool shouldRepaint(covariant _BackgroundShapesPainter oldDelegate) {
    return oldDelegate.slowProgress != slowProgress ||
        oldDelegate.mediumProgress != mediumProgress;
  }
}
