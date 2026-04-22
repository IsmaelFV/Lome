import 'package:flutter/material.dart';

/// Paleta de colores de LOME.
///
/// Basada en tonos verdes modernos con acentos calidos para contexto gastronomico.
/// Inspirada en Reflectly (gradientes), BMW (premium), Nubank (limpieza).
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Brand Colors
  // ---------------------------------------------------------------------------

  static const Color primary = Color(0xFF15803D);
  static const Color primaryLight = Color(0xFFA3E635);
  static const Color primaryDark = Color(0xFF064E3B);
  static const Color primarySoft = Color(0xFFECFDF5);

  // ---------------------------------------------------------------------------
  // Accent — toque calido para contexto gastronomico
  // ---------------------------------------------------------------------------

  static const Color accent = Color(0xFFFDCB6E);
  static const Color accentDark = Color(0xFFF59E0B);
  static const Color accentSoft = Color(0xFFFFFBEB);

  // ---------------------------------------------------------------------------
  // Semantic Colors
  // ---------------------------------------------------------------------------

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ---------------------------------------------------------------------------
  // Neutrals
  // ---------------------------------------------------------------------------

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF0A0A0A);

  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  // ---------------------------------------------------------------------------
  // Backgrounds
  // ---------------------------------------------------------------------------

  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color backgroundDark = Color(0xFF111827);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1F2937);

  // Dark mode restaurant (deep green-black, premium feel for kitchens)
  static const Color restaurantDarkBg = Color(0xFF071A12);
  static const Color restaurantDarkSurface = Color(0xFF0F2318);
  static const Color restaurantDarkCard = Color(0xFF163328);

  // ---------------------------------------------------------------------------
  // Order Status Colors
  // ---------------------------------------------------------------------------

  static const Color statusPending = Color(0xFFFBBF24);
  static const Color statusConfirmed = Color(0xFF3B82F6);
  static const Color statusPreparing = Color(0xFFF97316);
  static const Color statusReady = Color(0xFF22C55E);
  static const Color statusServed = Color(0xFF8B5CF6);
  static const Color statusDelivered = Color(0xFF10B981);
  static const Color statusCancelled = Color(0xFFEF4444);
  static const Color statusCompleted = Color(0xFF059669);

  // ---------------------------------------------------------------------------
  // Table Status Colors
  // ---------------------------------------------------------------------------

  static const Color tableAvailable = Color(0xFF22C55E);
  static const Color tableOccupied = Color(0xFFEF4444);
  static const Color tableReserved = Color(0xFFFBBF24);
  static const Color tableWaitingFood = Color(0xFFF97316);
  static const Color tableWaitingPayment = Color(0xFF8B5CF6);
  static const Color tableMaintenance = Color(0xFF6B7280);

  // ---------------------------------------------------------------------------
  // Gradients
  // ---------------------------------------------------------------------------

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, Color(0xFF022C22)],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [white, grey50],
  );

  /// Gradiente suave para hero cards (Nubank-style)
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF22C55E)],
  );

  /// Gradiente calido para promociones y destacados
  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentDark],
  );

  /// Gradiente sutil para fondos de secciones
  static const LinearGradient subtleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primarySoft, white],
  );

  /// Gradiente de glass/frosted overlay
  static LinearGradient get glassGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [white.withValues(alpha: 0.25), white.withValues(alpha: 0.10)],
  );

  // ---------------------------------------------------------------------------
  // Mapa de neutrales (acceso por clave para compatibilidad)
  // ---------------------------------------------------------------------------

  static const Map<String, Color> neutrals = {
    'grey50': grey50,
    'grey100': grey100,
    'grey200': grey200,
    'grey300': grey300,
    'grey400': grey400,
    'grey500': grey500,
    'grey600': grey600,
    'grey700': grey700,
    'grey800': grey800,
    'grey900': grey900,
  };
}
