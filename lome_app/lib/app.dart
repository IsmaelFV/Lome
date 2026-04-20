import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
// ignore: unused_import
import 'package:go_router/go_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/services/push_notification_service.dart';
import 'features/auth/presentation/services/deep_link_handler.dart';
import 'l10n/app_localizations.dart';
import 'shared/providers/session_provider.dart';
import 'shared/services/session_manager.dart';

class LomeApp extends ConsumerStatefulWidget {
  const LomeApp({super.key});

  @override
  ConsumerState<LomeApp> createState() => _LomeAppState();
}

class _LomeAppState extends ConsumerState<LomeApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Inicializar servicios tras el primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Deep link handler: captura eventos como PASSWORD_RECOVERY
      ref.read(deepLinkHandlerProvider).initialize();
      // 2. Session manager: monitorea el ciclo completo de la sesión
      ref.read(sessionManagerProvider).initialize();
      // 3. Push notifications: inicializa FCM y registra token
      _initPushNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initPushNotifications() async {
    final push = PushNotificationService.instance;
    push.onNotificationTap = (data) {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx == null) return;
      final route = data['route'] as String?;
      if (route != null && route.isNotEmpty) {
        ctx.push(route);
      }
    };
    await push.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Cuando la app vuelve al foreground, verificar que la sesión sigue válida.
    // Si el token expiró mientras estaba en background, el SDK lo renovará
    // automáticamente en la siguiente petición, pero lo refrescamos proactivamente
    // para dar feedback inmediato al usuario.
    if (state == AppLifecycleState.resumed) {
      final manager = ref.read(sessionManagerProvider);
      if (manager.hasSession && !manager.isSessionValid) {
        manager.refreshSession();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    // Escuchar eventos de sesión para mostrar feedback al usuario
    ref.listen(sessionEventsProvider, (_, next) {
      next.whenData((event) {
        if (event.status == SessionStatus.expired && event.message != null) {
          final ctx = rootNavigatorKey.currentContext;
          if (ctx != null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(event.message!),
                backgroundColor: AppColors.warning,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      });
    });

    return MaterialApp.router(
      title: 'LŌME',
      debugShowCheckedModeBanner: false,

      // Temas
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // Router
      routerConfig: router,

      // Localización
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('es', 'ES'),
      supportedLocales: AppLocalizations.supportedLocales,

      builder: (context, child) {
        // Limitar escala de texto para accesibilidad controlada
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // ignore: deprecated_member_use
            textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.3),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
