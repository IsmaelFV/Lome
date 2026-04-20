import 'package:intl/intl.dart';

/// Extensiones utiles sobre DateTime.
extension DateExtensions on DateTime {
  /// Formatea como "15 mar 2026".
  String get shortDate => DateFormat('d MMM y', 'es_ES').format(this);

  /// Formatea como "15 de marzo de 2026".
  String get longDate => DateFormat("d 'de' MMMM 'de' y", 'es_ES').format(this);

  /// Formatea como "14:30".
  String get shortTime => DateFormat('HH:mm').format(this);

  /// Formatea como "15 mar 14:30".
  String get shortDateTime => DateFormat('d MMM HH:mm', 'es_ES').format(this);

  /// Devuelve un texto relativo: "Hace 5 min", "Hace 2 h", "Ayer", etc.
  String get relative {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inSeconds < 60) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} dias';
    return shortDate;
  }

  /// Comprueba si es hoy.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Comprueba si es ayer.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Inicio del dia (00:00:00).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Fin del dia (23:59:59).
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
}
