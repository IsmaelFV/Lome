import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

/// Extensiones utiles sobre BuildContext.
extension ContextExtensions on BuildContext {
  // -------------------------------------------------------------------------
  // Localizations
  // -------------------------------------------------------------------------

  AppLocalizations get l10n => AppLocalizations.of(this);

  // -------------------------------------------------------------------------
  // Theme shortcuts
  // -------------------------------------------------------------------------

  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  bool get isDarkMode => theme.brightness == Brightness.dark;

  // -------------------------------------------------------------------------
  // MediaQuery shortcuts
  // -------------------------------------------------------------------------

  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => mediaQuery.padding;
  double get bottomInset => mediaQuery.viewInsets.bottom;

  // -------------------------------------------------------------------------
  // Responsive breakpoints
  // -------------------------------------------------------------------------

  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;

  // -------------------------------------------------------------------------
  // Snackbar
  // -------------------------------------------------------------------------

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }
}
