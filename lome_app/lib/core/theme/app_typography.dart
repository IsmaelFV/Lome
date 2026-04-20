import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Sistema tipografico de LOME.
///
/// Usa Inter como fuente principal por su excelente legibilidad
/// en pantallas de todo tamano, ideal para entornos de restauracion.
class AppTypography {
  AppTypography._();

  // ---------------------------------------------------------------------------
  // Text Theme (light)
  // ---------------------------------------------------------------------------

  static TextTheme get textTheme => TextTheme(
        displayLarge: _style(57, FontWeight.w700, AppColors.grey900),
        displayMedium: _style(45, FontWeight.w700, AppColors.grey900),
        displaySmall: _style(36, FontWeight.w600, AppColors.grey900),
        headlineLarge: _style(32, FontWeight.w600, AppColors.grey900),
        headlineMedium: _style(28, FontWeight.w600, AppColors.grey900),
        headlineSmall: _style(24, FontWeight.w600, AppColors.grey900),
        titleLarge: _style(22, FontWeight.w600, AppColors.grey800),
        titleMedium: _style(16, FontWeight.w600, AppColors.grey800),
        titleSmall: _style(14, FontWeight.w600, AppColors.grey800),
        bodyLarge: _style(16, FontWeight.w400, AppColors.grey700),
        bodyMedium: _style(14, FontWeight.w400, AppColors.grey700),
        bodySmall: _style(12, FontWeight.w400, AppColors.grey500),
        labelLarge: _style(14, FontWeight.w600, AppColors.grey700),
        labelMedium: _style(12, FontWeight.w500, AppColors.grey600),
        labelSmall: _style(11, FontWeight.w500, AppColors.grey500),
      );

  // ---------------------------------------------------------------------------
  // Text Theme (dark)
  // ---------------------------------------------------------------------------

  static TextTheme get textThemeDark => TextTheme(
        displayLarge: _style(57, FontWeight.w700, AppColors.white),
        displayMedium: _style(45, FontWeight.w700, AppColors.white),
        displaySmall: _style(36, FontWeight.w600, AppColors.white),
        headlineLarge: _style(32, FontWeight.w600, AppColors.white),
        headlineMedium: _style(28, FontWeight.w600, AppColors.white),
        headlineSmall: _style(24, FontWeight.w600, AppColors.white),
        titleLarge: _style(22, FontWeight.w600, AppColors.grey100),
        titleMedium: _style(16, FontWeight.w600, AppColors.grey100),
        titleSmall: _style(14, FontWeight.w600, AppColors.grey200),
        bodyLarge: _style(16, FontWeight.w400, AppColors.grey200),
        bodyMedium: _style(14, FontWeight.w400, AppColors.grey300),
        bodySmall: _style(12, FontWeight.w400, AppColors.grey400),
        labelLarge: _style(14, FontWeight.w600, AppColors.grey200),
        labelMedium: _style(12, FontWeight.w500, AppColors.grey300),
        labelSmall: _style(11, FontWeight.w500, AppColors.grey400),
      );

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static TextStyle _style(double size, FontWeight weight, Color color) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.4,
    );
  }

  /// Estilo para precios y numeros prominentes.
  static TextStyle price({double size = 20, Color? color}) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color ?? AppColors.grey900,
      letterSpacing: -0.5,
    );
  }

  /// Estilo para badges y etiquetas pequenas.
  static TextStyle badge({Color? color}) {
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.white,
      letterSpacing: 0.5,
    );
  }

  /// Estilo para estadisticas grandes en dashboards (Nubank/Revolut style).
  static TextStyle stat({double size = 32, Color? color}) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color ?? AppColors.grey900,
      letterSpacing: -1.0,
      height: 1.1,
    );
  }

  /// Estilo para labels de secciones (BMW restraint: semibold, muted).
  static TextStyle sectionLabel({Color? color}) {
    return GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.grey500,
      letterSpacing: 0.3,
    );
  }
}
