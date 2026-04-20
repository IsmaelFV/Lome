import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';

/// Estado de la sesión del usuario.
enum SessionStatus {
  /// Sesión activa y tokens válidos.
  active,

  /// El SDK renovó el access_token automáticamente con el refresh_token.
  refreshed,

  /// No hay sesión (el usuario no se ha autenticado o cerró sesión).
  unauthenticated,

  /// La sesión expiró y no pudo renovarse (refresh_token caducado).
  expired,
}

/// Evento emitido por el [SessionManager] cuando cambia el estado de la sesión.
class SessionEvent {
  final SessionStatus status;
  final Session? session;
  final String? message;

  const SessionEvent({
    required this.status,
    this.session,
    this.message,
  });
}

/// Servicio de gestión de sesiones del frontend.
///
/// ### Responsabilidades
///
/// 1. **Mantener la sesión activa**: Supabase Flutter almacena internamente
///    el `access_token` y `refresh_token` en almacenamiento seguro del SO
///    (Keychain en iOS, EncryptedSharedPreferences en Android, sessionStorage
///    en web). No necesitamos manejar `flutter_secure_storage` manualmente
///    para los tokens de Supabase — el SDK lo hace.
///
/// 2. **Renovar tokens automáticamente**: Supabase Flutter intercepta las
///    respuestas HTTP `401` y automáticamente usa el `refresh_token` para
///    obtener un nuevo `access_token`. Además, verifica la expiración del
///    token antes de cada petición y lo renueva si está a punto de expirar.
///
/// 3. **Detectar expiración**: Si el `refresh_token` también ha expirado
///    (por ejemplo, tras 7 días sin usar la app según la config del proyecto),
///    la renovación falla y el SDK dispara `AuthChangeEvent.signedOut`.
///    Este servicio lo detecta e informa a la UI.
///
/// 4. **Cerrar sesión**: Limpia la sesión local y revoca el `refresh_token`
///    en el servidor para que no pueda reutilizarse.
///
/// ### Arquitectura
///
/// ```
///   Supabase SDK                   SessionManager              Riverpod
///   ────────────                   ──────────────              ────────
///   onAuthStateChange ──────────►  _onAuthEvent() ──────────►  sessionEventProvider
///      │                              │                           │
///      │  tokenRefreshed              │  SessionStatus.refreshed  │  UI reacciona
///      │  signedOut                   │  SessionStatus.expired    │  (logout, snackbar)
///      │  signedIn                    │  SessionStatus.active     │
///      │                              │                           │
///   Almacena tokens               Expone estado              authStateProvider
///   en secure storage             de sesión                  (redireccion del router)
/// ```
///
/// ### Tokens y almacenamiento seguro
///
/// | Plataforma | Mecanismo de almacenamiento         | Seguridad                |
/// |------------|--------------------------------------|--------------------------|
/// | iOS        | Keychain                             | Cifrado por hardware     |
/// | Android    | EncryptedSharedPreferences (AES-256) | Cifrado por AndroidX     |
/// | Web        | sessionStorage / localStorage        | Protegido por Same-Origin|
///
/// El SDK de Supabase Flutter usa `flutter_secure_storage` internamente
/// cuando el paquete está disponible. Como ya lo tenemos en `pubspec.yaml`,
/// el almacenamiento de tokens es seguro automáticamente.
///
/// ### Flujo de renovación
///
/// ```
///   1. El access_token expira (por defecto cada 3600s)
///   2. La siguiente petición a Supabase detecta el token expirado
///   3. El SDK usa el refresh_token para obtener un nuevo par de tokens
///   4. Si éxito → dispara `tokenRefreshed` → la app sigue operando
///   5. Si falla → dispara `signedOut` → la app navega al login
/// ```
///
/// ### Configuración de caducidad (Supabase Dashboard)
///
/// - **Auth → Settings → JWT Expiry**: duración del access_token
///   (recomendado: 3600s = 1 hora).
/// - **Auth → Settings → Refresh Token rotation**: habilitar para
///   mayor seguridad (cada uso del refresh_token genera uno nuevo).
/// - **Auth → Settings → Refresh Token Reuse Interval**: ventana
///   en segundos para reutilizar un refresh_token ya rotado (0 = estricto).
class SessionManager {
  final SupabaseClient _client;
  StreamSubscription<AuthState>? _authSubscription;

  final _eventController = StreamController<SessionEvent>.broadcast();

  SessionManager({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  /// Stream de eventos de sesión para que la UI reaccione.
  Stream<SessionEvent> get sessionEvents => _eventController.stream;

  /// Sesión actual (puede ser null si no hay sesión).
  Session? get currentSession => _client.auth.currentSession;

  /// `true` si hay una sesión almacenada localmente.
  bool get hasSession => currentSession != null;

  /// `true` si el access_token aún no ha expirado.
  bool get isSessionValid {
    final session = currentSession;
    if (session == null) return false;

    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;

    // El token expira en este timestamp (segundos desde epoch)
    final expiryDate =
        DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);

    // Consideramos inválido si faltan menos de 30 segundos
    return expiryDate.isAfter(
      DateTime.now().add(const Duration(seconds: 30)),
    );
  }

  /// Tiempo restante del access_token actual.
  Duration? get timeUntilExpiry {
    final session = currentSession;
    if (session == null || session.expiresAt == null) return null;

    final expiryDate =
        DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
    final remaining = expiryDate.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Inicia el monitoreo de eventos de autenticación.
  ///
  /// Debe llamarse una sola vez durante el ciclo de vida de la app.
  void initialize() {
    _authSubscription = _client.auth.onAuthStateChange.listen(_onAuthEvent);

    // Emitir estado inicial
    if (hasSession) {
      _eventController.add(SessionEvent(
        status: SessionStatus.active,
        session: currentSession,
      ));
    } else {
      _eventController.add(const SessionEvent(
        status: SessionStatus.unauthenticated,
      ));
    }
  }

  /// Intenta refrescar la sesión manualmente.
  ///
  /// Útil para pre-refrescar antes de una operación crítica.
  Future<bool> refreshSession() async {
    try {
      final response = await _client.auth.refreshSession();
      if (response.session != null) {
        _eventController.add(SessionEvent(
          status: SessionStatus.refreshed,
          session: response.session,
        ));
        return true;
      }
      return false;
    } catch (_) {
      _eventController.add(const SessionEvent(
        status: SessionStatus.expired,
        message: 'No se pudo renovar la sesión',
      ));
      return false;
    }
  }

  /// Cierra la sesión actual.
  ///
  /// Revoca el refresh_token en el servidor y limpia el almacenamiento local.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Incluso si falla la revocación remota, limpiar localmente
    }
    _eventController.add(const SessionEvent(
      status: SessionStatus.unauthenticated,
    ));
  }

  void _onAuthEvent(AuthState state) {
    switch (state.event) {
      case AuthChangeEvent.signedIn:
        _eventController.add(SessionEvent(
          status: SessionStatus.active,
          session: state.session,
        ));
        break;

      case AuthChangeEvent.tokenRefreshed:
        // El SDK renovó el token automáticamente
        _eventController.add(SessionEvent(
          status: SessionStatus.refreshed,
          session: state.session,
        ));
        break;

      case AuthChangeEvent.signedOut:
        // Puede ser logout voluntario o refresh_token expirado
        _eventController.add(const SessionEvent(
          status: SessionStatus.expired,
          message: 'Tu sesión ha expirado. Por favor, inicia sesión de nuevo.',
        ));
        break;

      case AuthChangeEvent.passwordRecovery:
        // Lo maneja el DeepLinkHandler, no el SessionManager
        break;

      case AuthChangeEvent.userUpdated:
        // El perfil se actualizó — mantener sesión activa
        _eventController.add(SessionEvent(
          status: SessionStatus.active,
          session: state.session,
        ));
        break;

      default:
        break;
    }
  }

  /// Libera recursos.
  void dispose() {
    _authSubscription?.cancel();
    _eventController.close();
  }
}
