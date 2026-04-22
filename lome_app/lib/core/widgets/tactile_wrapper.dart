import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Wrapper tactil inspirado en Reflectly.
///
/// Envuelve cualquier widget interactivo con feedback de escala + sombra
/// que da una sensacion fisica premium. Usa spring physics para el rebote.
///
/// Aplica:
/// - Scale down a [pressScale] al presionar (default 0.96 del design system)
/// - Sombra que se retrae al presionar
/// - Spring bounce al soltar
/// - Haptic feedback opcional
class TactileWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressScale;
  final bool enableHaptic;
  final String? semanticLabel;

  const TactileWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressScale = AppTheme.pressScale,
    this.enableHaptic = false,
    this.semanticLabel,
  });

  @override
  State<TactileWrapper> createState() => _TactileWrapperState();
}

class _TactileWrapperState extends State<TactileWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.pressScale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
        reverseCurve: AppTheme.curveSpring,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null && widget.onLongPress == null) {
      return widget.child;
    }

    final gesture = GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: widget.child,
      ),
    );

    if (widget.semanticLabel != null) {
      return Semantics(
        button: true,
        label: widget.semanticLabel,
        child: gesture,
      );
    }

    return gesture;
  }
}
