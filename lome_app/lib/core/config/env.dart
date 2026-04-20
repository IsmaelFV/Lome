/// Configuracion de entorno para LOME.
///
/// Gestiona las variables de entorno necesarias para
/// conectar con Supabase, Cloudinary y otros servicios externos.
///
/// En desarrollo las claves se leen desde `.env` (flutter_dotenv).
/// En produccion se pueden inyectar via --dart-define (tienen prioridad)
/// o mantener el .env en los assets.
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  // ---------------------------------------------------------------------------
  // Helpers: --dart-define tiene prioridad sobre .env
  // ---------------------------------------------------------------------------

  static String _get(String key, {String defaultValue = ''}) {
    // 1. Compile-time (--dart-define)
    const compiled = <String, String>{
      'SUPABASE_URL': String.fromEnvironment('SUPABASE_URL'),
      'SUPABASE_ANON_KEY': String.fromEnvironment('SUPABASE_ANON_KEY'),
      'CLOUDINARY_CLOUD_NAME': String.fromEnvironment('CLOUDINARY_CLOUD_NAME'),
      'CLOUDINARY_UPLOAD_PRESET': String.fromEnvironment(
        'CLOUDINARY_UPLOAD_PRESET',
      ),
      'SENTRY_DSN': String.fromEnvironment('SENTRY_DSN'),
      'APP_ENV': String.fromEnvironment('APP_ENV'),
      'APP_VERSION': String.fromEnvironment('APP_VERSION'),
    };
    final compileValue = compiled[key];
    if (compileValue != null && compileValue.isNotEmpty) return compileValue;

    // 2. Runtime (.env file)
    return dotenv.get(key, fallback: defaultValue);
  }

  // ---------------------------------------------------------------------------
  // Supabase
  // ---------------------------------------------------------------------------

  static String get supabaseUrl => _get('SUPABASE_URL');
  static String get supabaseAnonKey => _get('SUPABASE_ANON_KEY');

  // ---------------------------------------------------------------------------
  // Cloudinary
  // ---------------------------------------------------------------------------

  static String get cloudinaryCloudName => _get('CLOUDINARY_CLOUD_NAME');
  static String get cloudinaryUploadPreset => _get('CLOUDINARY_UPLOAD_PRESET');

  // ---------------------------------------------------------------------------
  // Sentry
  // ---------------------------------------------------------------------------

  static String get sentryDsn => _get('SENTRY_DSN');

  // ---------------------------------------------------------------------------
  // General
  // ---------------------------------------------------------------------------

  static String get appEnvironment =>
      _get('APP_ENV', defaultValue: 'development');
  static String get appVersion => _get('APP_VERSION', defaultValue: '1.0.0');

  static bool get isProduction => appEnvironment == 'production';
  static bool get isDevelopment => appEnvironment == 'development';
  static bool get isStaging => appEnvironment == 'staging';

  /// Valida que las variables de entorno criticas esten configuradas.
  static void validate() {
    final missing = <String>[];
    if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');

    if (missing.isNotEmpty && isProduction) {
      throw StateError('Variables de entorno faltantes: ${missing.join(', ')}');
    }
  }
}
