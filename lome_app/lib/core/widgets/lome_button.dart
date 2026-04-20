import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Boton principal reutilizable de LOME.
///
/// Soporta variantes: primary, secondary, outlined, text, danger.
/// Incluye feedback táctil con escala y un loader animado.
enum LomeButtonVariant { primary, secondary, outlined, text, danger }

class LomeButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final LomeButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final double? width;
  final double height;

  const LomeButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = LomeButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.width,
    this.height = 48,
  });

  @override
  State<LomeButton> createState() => _LomeButtonState();
}

class _LomeButtonState extends State<LomeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) => _tapCtrl.forward();
  void _handleTapUp(TapUpDetails _) => _tapCtrl.reverse();
  void _handleTapCancel() => _tapCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    final child = _buildChild(context);

    Widget button;
    switch (widget.variant) {
      case LomeButtonVariant.primary:
        button = ElevatedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(widget.width ?? 0, widget.height),
          ),
          child: child,
        );
      case LomeButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(widget.width ?? 0, widget.height),
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.primaryDark,
          ),
          child: child,
        );
      case LomeButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(widget.width ?? 0, widget.height),
          ),
          child: child,
        );
      case LomeButtonVariant.text:
        button = TextButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: TextButton.styleFrom(
            minimumSize: Size(widget.width ?? 0, widget.height),
          ),
          child: child,
        );
      case LomeButtonVariant.danger:
        button = ElevatedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(widget.width ?? 0, widget.height),
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
          ),
          child: child,
        );
    }

    if (widget.isExpanded) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return Semantics(
      button: true,
      enabled: widget.onPressed != null && !widget.isLoading,
      label: widget.label,
      child: GestureDetector(
        onTapDown: widget.onPressed != null ? _handleTapDown : null,
        onTapUp: widget.onPressed != null ? _handleTapUp : null,
        onTapCancel: widget.onPressed != null ? _handleTapCancel : null,
        child: ScaleTransition(scale: _scaleAnim, child: button),
      ),
    );
  }

  Widget _buildChild(BuildContext context) {
    if (widget.isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.variant == LomeButtonVariant.outlined
                ? AppColors.primary
                : AppColors.white,
          ),
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 18),
          const SizedBox(width: AppTheme.spacingSm),
          Text(widget.label),
        ],
      );
    }

    return Text(widget.label);
  }
}
