import 'package:intl/intl.dart';

/// Helper para formatear cantidades monetarias.
class CurrencyHelper {
  CurrencyHelper._();

  static final _formatter = NumberFormat.currency(
    locale: 'es_ES',
    symbol: '\u20AC', // Euro sign
    decimalDigits: 2,
  );

  static final _compactFormatter = NumberFormat.compactCurrency(
    locale: 'es_ES',
    symbol: '\u20AC',
    decimalDigits: 1,
  );

  /// Formatea un double como precio: "12,50 EUR".
  static String format(double amount) => _formatter.format(amount);

  /// Formatea de forma compacta: "1,2k EUR".
  static String formatCompact(double amount) => _compactFormatter.format(amount);

  /// Formatea sin simbolo de moneda: "12,50".
  static String formatPlain(double amount) {
    return NumberFormat('#,##0.00', 'es_ES').format(amount);
  }
}
