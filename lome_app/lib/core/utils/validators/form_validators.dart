/// Validadores de formularios reutilizables.
///
/// Devuelven null si el valor es valido, o un String con el mensaje de error.
class FormValidators {
  FormValidators._();

  static String? required(String? value, [String fieldName = 'Este campo']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es obligatorio';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Introduce un email valido';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contrasena es obligatoria';
    }
    if (value.length < 8) {
      return 'Minimo 8 caracteres';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Debe contener al menos una mayuscula';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Debe contener al menos un numero';
    }
    if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_+=\[\]\\/~`]'))) {
      return 'Debe contener al menos un caracter especial (!@#\$...)';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) {
      return 'Las contrasenas no coinciden';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    if (!RegExp(r'^\+?[\d\s-]{9,15}$').hasMatch(value)) {
      return 'Introduce un telefono valido';
    }
    return null;
  }

  static String? minLength(
    String? value,
    int min, [
    String fieldName = 'Este campo',
  ]) {
    if (value != null && value.length < min) {
      return '$fieldName debe tener al menos $min caracteres';
    }
    return null;
  }

  static String? maxLength(
    String? value,
    int max, [
    String fieldName = 'Este campo',
  ]) {
    if (value != null && value.length > max) {
      return '$fieldName no puede superar los $max caracteres';
    }
    return null;
  }

  static String? positiveNumber(
    String? value, [
    String fieldName = 'El valor',
  ]) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    final number = double.tryParse(value);
    if (number == null || number < 0) {
      return '$fieldName debe ser un numero positivo';
    }
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El precio es obligatorio';
    }
    final number = double.tryParse(value);
    if (number == null || number < 0) {
      return 'Introduce un precio valido';
    }
    return null;
  }

  /// Combina multiples validadores. Ejecuta en orden y devuelve el primer error.
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
