import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Contador animado que cuenta desde [begin] hasta [end].
///
/// Inspirado en Nubank/Revolut — los numeros grandes del dashboard
/// cuentan desde 0 con curva easeOutCubic al aparecer.
/// Usa [duration] para controlar la velocidad (default: 600ms).
class AnimatedCounter extends StatefulWidget {
  final double end;
  final double begin;
  final Duration duration;
  final String Function(double value) formatter;
  final TextStyle? style;

  const AnimatedCounter({
    super.key,
    required this.end,
    this.begin = 0,
    this.duration = AppTheme.durationStagger,
    required this.formatter,
    this.style,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: widget.begin, end: widget.end).animate(
      CurvedAnimation(parent: _controller, curve: AppTheme.curveSmooth),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.end != widget.end) {
      _animation = Tween<double>(begin: _animation.value, end: widget.end)
          .animate(
            CurvedAnimation(parent: _controller, curve: AppTheme.curveSmooth),
          );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) =>
          Text(widget.formatter(_animation.value), style: widget.style),
    );
  }
}
