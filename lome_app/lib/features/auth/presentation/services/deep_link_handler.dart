import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/router/route_names.dart';

/// Servicio que escucha los deep links de Supabase Auth y reacciona.
///
/// ### ¿Cómo funciona la recuperación de contraseña con deep links?
///
/// 1. El usuario solicita un email de recuperación (`resetPasswordForEmail`).
/// 2. Supabase genera un enlace temporal con un token OTP firmado:
///    ```
///    https://<project>.supabase.co/auth/v1/verify?type=recovery
///      &token=<otp>&redirect_to=<tu_app_scheme>://reset-callback
///    ```
/// 3. El enlace caduca según la configuración del proyecto de Supabase
///    (por defecto 1 hora; configurable en Auth → URL Configuration).
///
/// 4. Al abrir el enlace:
///    a. En **móvil**: el SO resuelve el deep link (`io.supabase.lome://…`)
///       y abre la app. Supabase Flutter intercepta el callback,
///       valida el token y genera una sesión temporal de tipo «recovery».
///    b. En **web**: el redirect va al dominio de la PWA y Supabase Flutter
///       lee el fragmento `#access_token=…` de la URL para crear la sesión.
///
/// 5. El SDK dispara `AuthChangeEvent.passwordRecovery`.
///
/// 6. Este `DeepLinkHandler` escucha ese evento y navega a `/reset-password`,
///    donde el usuario introduce la nueva contraseña.
///
/// 7. La pantalla llama a `auth.updateUser(UserAttributes(password: …))`
///    que usa el access_token de la sesión de recovery.
///
/// 8. Si el token ha expirado, la llamada falla con un error que se muestra
///    al usuario: «El enlace ha expirado. Solicita uno nuevo.»
///
/// ### Configuración necesaria en Supabase Dashboard
///
/// - **Auth → URL Configuration → Redirect URLs**: añadir
///   `io.supabase.lome://reset-callback` (mobile)
///   y la URL de tu web (ej. `https://app.lome.io/reset-callback`).
///
/// - **Auth → Email Templates → Reset Password**: personalizar el template
///   para usar el redirect URL correcto y el idioma español.
///
/// - **Auth → Settings → Token Expiry**: configurar la caducidad del OTP
///   (recomendado: 3600 s = 1 hora).
///
/// ### Configuración necesaria en el proyecto Flutter
///
/// **Android** (`android/app/src/main/AndroidManifest.xml`):
/// ```xml
/// <intent-filter>
///   <action android:name="android.intent.action.VIEW" />
///   <category android:name="android.intent.category.DEFAULT" />
///   <category android:name="android.intent.category.BROWSABLE" />
///   <data android:scheme="io.supabase.lome"
///         android:host="reset-callback" />
/// </intent-filter>
/// ```
///
/// **iOS** (`ios/Runner/Info.plist`):
/// ```xml
/// <key>CFBundleURLTypes</key>
/// <array>
///   <dict>
///     <key>CFBundleTypeRole</key>
///     <string>Editor</string>
///     <key>CFBundleURLSchemes</key>
///     <array>
///       <string>io.supabase.lome</string>
///     </array>
///   </dict>
/// </array>
/// ```
///
/// **Web** (`web/index.html`): no requiere config adicional —
/// el token se lee del fragmento hash de la URL.
class DeepLinkHandler {
  final SupabaseClient _client;
  final GlobalKey<NavigatorState> _navigatorKey;
  StreamSubscription<AuthState>? _subscription;

  DeepLinkHandler({
    required SupabaseClient client,
    required GlobalKey<NavigatorState> navigatorKey,
  })  : _client = client,
        _navigatorKey = navigatorKey;

  /// Comienza a escuchar eventos de autenticación.
  ///
  /// Debe llamarse una sola vez al inicio de la app (desde [LomeApp]).
  void initialize() {
    _subscription = _client.auth.onAuthStateChange.listen(_onAuthEvent);
  }

  /// Libera la suscripción.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _onAuthEvent(AuthState state) {
    final event = state.event;
    final context = _navigatorKey.currentContext;
    if (context == null) return;

    switch (event) {
      case AuthChangeEvent.passwordRecovery:
        // El usuario abrió el enlace de recovery → navegar a la pantalla
        // de nueva contraseña. La sesión ya tiene un token temporal válido.
        GoRouter.of(context).go(RoutePaths.resetPassword);
        break;

      case AuthChangeEvent.signedIn:
        // Un deep link de verificación de email también puede disparar
        // signedIn si el callback es de tipo login. No hacemos nada aquí
        // porque el router redirect ya maneja el caso.
        break;

      default:
        break;
    }
  }
}

/// Provider global del [DeepLinkHandler].
///
/// Usa el `rootNavigatorKey` del router para acceder al contexto de navegación.
/// Se inicializa desde [LomeApp].
final deepLinkHandlerProvider = Provider<DeepLinkHandler>((ref) {
  // Importamos rootNavigatorKey desde app_router.dart
  final navigatorKey =
      ref.watch(rootNavigatorKeyProvider);
  return DeepLinkHandler(
    client: Supabase.instance.client,
    navigatorKey: navigatorKey,
  );
});
