import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/services/monitoring_service.dart';
import 'firebase_options.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
  ),
);

/// Inicializa todos los servicios necesarios antes de arrancar la app.
/// Retorna el [SharedPreferences] ya inicializado para inyectarlo al [StorageService].
Future<SharedPreferences> bootstrap() async {
  // Cargar variables de entorno desde .env
  await dotenv.load(fileName: '.env');

  // Validar variables de entorno obligatorias
  Env.validate();

  // Orientaciones permitidas
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Estilo de la barra de estado
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Inicializar Supabase
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Inicializar SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Inicializar Firebase (para push notifications)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.i('✅ Firebase inicializado');
  } catch (e) {
    logger.w('⚠️ Firebase no configurado — push deshabilitado');
    logger.w('   Ejecuta: flutterfire configure');
  }

  logger.i('✅ Bootstrap completado — Env: ${Env.appEnvironment}');

  return prefs;
}

/// Capturador global de errores para producción.
void setupErrorHandling() {
  final monitoring = MonitoringService(Supabase.instance.client);

  FlutterError.onError = (details) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    } else {
      logger.e(
        'FlutterError',
        error: details.exception,
        stackTrace: details.stack,
      );
      monitoring.captureFlutterError(details);
      Sentry.captureException(details.exception, stackTrace: details.stack);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    logger.e('PlatformError', error: error, stackTrace: stack);
    monitoring.capturePlatformError(error, stack);
    Sentry.captureException(error, stackTrace: stack);
    return true;
  };
}
