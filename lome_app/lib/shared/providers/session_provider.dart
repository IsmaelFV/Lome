import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/session_manager.dart';

// ---------------------------------------------------------------------------
// Session Manager Provider
// ---------------------------------------------------------------------------

/// Provider del [SessionManager] — singleton durante el ciclo de vida de la app.
///
/// Se inicializa desde `main.dart` o `app.dart` y monitorea
/// los cambios de sesión de Supabase Auth.
final sessionManagerProvider = Provider<SessionManager>((ref) {
  final manager = SessionManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});

// ---------------------------------------------------------------------------
// Session Events Stream
// ---------------------------------------------------------------------------

/// Stream de eventos de sesión para que widgets reaccionen
/// a cambios como expiración de token, renovación, etc.
final sessionEventsProvider = StreamProvider<SessionEvent>((ref) {
  final manager = ref.watch(sessionManagerProvider);
  return manager.sessionEvents;
});

// ---------------------------------------------------------------------------
// Session Status
// ---------------------------------------------------------------------------

/// Provider del estado actual de la sesión.
///
/// Útil para widgets que necesitan saber si la sesión
/// está activa, expirada o el usuario no está autenticado.
final sessionStatusProvider = Provider<SessionStatus>((ref) {
  final event = ref.watch(sessionEventsProvider);
  return event.valueOrNull?.status ?? SessionStatus.unauthenticated;
});

// ---------------------------------------------------------------------------
// Session Helper Providers
// ---------------------------------------------------------------------------

/// `true` si hay una sesión válida con token no expirado.
final isSessionValidProvider = Provider<bool>((ref) {
  final manager = ref.watch(sessionManagerProvider);
  return manager.isSessionValid;
});

/// Tiempo restante antes de que expire el access_token actual.
final tokenExpiryProvider = Provider<Duration?>((ref) {
  final manager = ref.watch(sessionManagerProvider);
  return manager.timeUntilExpiry;
});
