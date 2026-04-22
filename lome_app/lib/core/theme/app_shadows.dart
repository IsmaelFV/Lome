import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Sistema de sombras de LOME.
///
/// Define niveles de elevacion consistentes para todo el sistema de diseno.
/// Incluye sombras neutras y sombras de marca (green-tinted) para cards premium.
class AppShadows {
  AppShadows._();

  /// Sombra sutil para elementos en superficie (cards, tiles).
  static List<BoxShadow> get sm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  /// Sombra media para elementos elevados (dropdowns, popovers).
  static List<BoxShadow> get md => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  /// Sombra pronunciada para modales y elementos flotantes.
  static List<BoxShadow> get lg => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 4),
    ),
  ];

  /// Sombra maxima para dialogs y sheets.
  static List<BoxShadow> get xl => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  /// Sombra de marca (green-tinted) para cards gold standard.
  /// Doble sombra: primaryDark alpha 0.08 + black alpha 0.04 (welcome/login pattern)
  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.primaryDark.withValues(alpha: 0.08),
      blurRadius: 32,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Sombra para cards elevadas en hover/press (feedback tactil).
  static List<BoxShadow> get cardElevated => [
    BoxShadow(
      color: AppColors.primaryDark.withValues(alpha: 0.12),
      blurRadius: 40,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Sombra sutil para navegacion inferior.
  static List<BoxShadow> get navigation => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, -2),
    ),
  ];
}
