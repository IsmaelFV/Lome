import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'core/config/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar servicios (Supabase, .env, etc.)
  await bootstrap();

  // Configurar manejo global de errores (requiere Supabase inicializado)
  setupErrorHandling();

  // Inicializar Sentry y arrancar la app
  if (Env.sentryDsn.isNotEmpty) {
    await SentryFlutter.init((options) {
      options.dsn = Env.sentryDsn;
      options.environment = Env.appEnvironment;
      options.release = 'lome_app@${Env.appVersion}';
      options.tracesSampleRate = Env.isProduction ? 0.2 : 1.0;
      options.sendDefaultPii = false;
      options.attachScreenshot = !Env.isProduction;
    }, appRunner: () => runApp(const ProviderScope(child: LomeApp())));
  } else {
    runApp(const ProviderScope(child: LomeApp()));
  }
}
