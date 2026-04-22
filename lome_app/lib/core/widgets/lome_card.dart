import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';

/// Card reutilizable de LOME.
///
/// Wrapper sobre el Card de Material con estilo consistente.
/// Cuando tiene [onTap], muestra una sutil elevación al presionar.
class LomeCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final List<BoxShadow>? shadow;
  final BorderRadius? borderRadius;
  final Border? border;

  /// Si es `true`, pinta el fondo con un gradiente suave verde.
  final bool useGradient;

  /// Etiqueta para lectores de pantalla.
  final String? semanticLabel;

  const LomeCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.shadow,
    this.borderRadius,
    this.border,
    this.useGradient = false,
    this.semanticLabel,
  });

  @override
  State<LomeCard> createState() => _LomeCardState();
}

class _LomeCardState extends State<LomeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _elevAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _elevAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius =
        widget.borderRadius ?? BorderRadius.circular(AppTheme.radiusMd);

    return AnimatedBuilder(
      animation: _elevAnim,
      builder: (context, child) {
        final t = _elevAnim.value;
        return Container(
          margin: widget.margin,
          decoration: BoxDecoration(
            color: widget.useGradient
                ? null
                : widget.color ??
                      (isDark ? AppColors.surfaceDark : AppColors.white),
            gradient: widget.useGradient
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.04),
                      AppColors.primaryLight.withValues(alpha: 0.08),
                    ],
                  )
                : null,
            borderRadius: radius,
            border:
                widget.border ??
                Border.all(
                  color: isDark ? AppColors.grey700 : AppColors.grey200,
                ),
            boxShadow:
                widget.shadow ??
                [
                  ...AppShadows.sm,
                  if (t > 0)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.06 * t),
                      blurRadius: 12 * t,
                      offset: Offset(0, 4 * t),
                    ),
                ],
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: widget.onTap != null ? (_) => _ctrl.forward() : null,
          onTapUp: widget.onTap != null ? (_) => _ctrl.reverse() : null,
          onTapCancel: widget.onTap != null ? () => _ctrl.reverse() : null,
          borderRadius: radius,
          child: Semantics(
            button: widget.onTap != null,
            label: widget.semanticLabel,
            child: Padding(
              padding:
                  widget.padding ?? const EdgeInsets.all(AppTheme.spacingMd),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Card de estadistica para dashboards.
///
/// Muestra valor numérico + ícono + subtítulo con estilo KPI.
class LomeStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Widget? trailing;

  const LomeStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icoColor = iconColor ?? AppColors.primary;

    return LomeCard(
      semanticLabel: '$title: $value',
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (iconBackgroundColor ?? icoColor).withValues(alpha: 0.12),
                  (iconBackgroundColor ?? icoColor).withValues(alpha: 0.20),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, color: icoColor, size: 24),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.grey500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
