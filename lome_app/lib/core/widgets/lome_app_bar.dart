import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_colors.dart';

/// AppBar personalizado de LOME.
///
/// Soporta dos variantes:
/// - **flat** (default): fondo blanco, texto oscuro — para páginas interiores.
/// - **gradient**: fondo con [AppColors.darkGradient], texto blanco — para
///   la cabecera principal de una sección (dashboard, marketplace, etc.).
class LomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;
  final Color? backgroundColor;
  final Widget? leading;
  final double elevation;
  final PreferredSizeWidget? bottom;

  /// Si es `true`, usa el gradiente verde oscuro + texto/iconos blancos.
  final bool useGradient;

  const LomeAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.showBack = true,
    this.onBack,
    this.backgroundColor,
    this.leading,
    this.elevation = 0,
    this.bottom,
    this.useGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = useGradient ? AppColors.white : null;

    return AppBar(
      title:
          titleWidget ??
          (title != null ? Text(title!, style: TextStyle(color: fg)) : null),
      actions: actions,
      leading:
          leading ??
          (showBack && Navigator.of(context).canPop()
              ? IconButton(
                  icon: Icon(
                    PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
                    size: 22,
                    color: fg,
                  ),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: onBack ?? () => Navigator.of(context).pop(),
                )
              : null),
      automaticallyImplyLeading: showBack,
      backgroundColor:
          backgroundColor ?? (useGradient ? AppColors.primaryDark : null),
      elevation: elevation,
      surfaceTintColor: Colors.transparent,
      foregroundColor: fg,
      iconTheme: fg != null ? IconThemeData(color: fg) : null,
      flexibleSpace: useGradient
          ? Container(
              decoration: const BoxDecoration(gradient: AppColors.darkGradient),
            )
          : null,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

/// Badge de notificacion para iconos del AppBar.
///
/// Muestra un indicador numérico sobre el icono hijo con una sutil
/// animación de escala al cambiar el conteo.
class LomeBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final Color? color;

  const LomeBadge({
    super.key,
    required this.child,
    required this.count,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -6,
          top: -4,
          child: AnimatedScale(
            scale: count > 0 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: color ?? AppColors.error,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: (color ?? AppColors.error).withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
