import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bootstrap.dart';

/// Handler de mensajes en background (debe ser top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // El sistema muestra la notificación automáticamente
  // cuando el payload incluye `notification`.
}

/// Servicio centralizado de push notifications via FCM.
///
/// Singleton que gestiona:
/// - Permisos de notificación
/// - Registro/borrado de tokens en Supabase (`device_tokens`)
/// - Notificaciones en foreground (via `flutter_local_notifications`)
/// - Taps en notificaciones (navegación)
/// - Limpieza automática al cerrar sesión
class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();

  FirebaseMessaging? _messaging;
  FlutterLocalNotificationsPlugin? _localNotifications;
  StreamSubscription<AuthState>? _authSub;
  bool _initialized = false;
  String? _currentToken;

  /// Callback cuando el usuario toca una notificación push.
  /// Recibe el `data` payload del mensaje FCM.
  void Function(Map<String, dynamic> data)? onNotificationTap;

  static const _androidChannel = AndroidNotificationChannel(
    'lome_notifications',
    'LŌME',
    description: 'Notificaciones de pedidos, alertas y novedades',
    importance: Importance.high,
  );

  bool get isAvailable => _messaging != null;
  String? get currentToken => _currentToken;

  /// Inicializa el servicio. Llama una sola vez tras `Firebase.initializeApp()`.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      _messaging = FirebaseMessaging.instance;
    } catch (e) {
      logger.w('Firebase Messaging no disponible: $e');
      return;
    }

    // Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Solicitar permisos
    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      logger.i('Push notifications: permiso denegado');
      return;
    }

    // Local notifications (Android/iOS foreground)
    if (!kIsWeb) {
      await _setupLocalNotifications();
    }

    // iOS: mostrar notificaciones en foreground
    await _messaging!.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Token inicial
    await _refreshToken();

    // Escuchar refresh de token
    _messaging!.onTokenRefresh.listen(_saveTokenToSupabase);

    // Mensajes en foreground
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Tap en notificación (app estaba en background)
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageTap);

    // Mensaje inicial (app lanzada desde notificación en estado terminated)
    final initial = await _messaging!.getInitialMessage();
    if (initial != null) {
      Future.delayed(const Duration(milliseconds: 600), () {
        _onMessageTap(initial);
      });
    }

    // Auth: borrar token al cerrar sesión, refrescar al iniciar
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        _deleteToken();
      } else if (data.event == AuthChangeEvent.signedIn) {
        _refreshToken();
      }
    });

    logger.i('✅ Push notifications inicializadas');
  }

  // ── Local Notifications Setup ──

  Future<void> _setupLocalNotifications() async {
    _localNotifications = FlutterLocalNotificationsPlugin();

    await _localNotifications!.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;
        if (route != null) {
          onNotificationTap?.call({'route': route});
        }
      },
    );

    // Crear canal Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications!
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);
    }
  }

  // ── Message Handlers ──

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null || kIsWeb) return;

    _localNotifications?.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['route'],
    );
  }

  void _onMessageTap(RemoteMessage message) {
    onNotificationTap?.call(message.data);
  }

  // ── Token Management ──

  Future<void> _refreshToken() async {
    try {
      final token = await _messaging?.getToken();
      if (token != null && token != _currentToken) {
        _currentToken = token;
        await _saveTokenToSupabase(token);
      }
    } catch (e) {
      logger.w('Error obteniendo token FCM: $e');
    }
  }

  Future<void> _saveTokenToSupabase(String token) async {
    _currentToken = token;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final platform = kIsWeb
        ? 'web'
        : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');

    try {
      await Supabase.instance.client.from('device_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': platform,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'token');
    } catch (e) {
      logger.w('Error guardando token: $e');
    }
  }

  Future<void> _deleteToken() async {
    final token = _currentToken;
    if (token == null) return;

    try {
      await Supabase.instance.client
          .from('device_tokens')
          .delete()
          .eq('token', token);
      await _messaging?.deleteToken();
      _currentToken = null;
    } catch (e) {
      logger.w('Error eliminando token: $e');
    }
  }

  /// Activa/desactiva push para este dispositivo.
  Future<void> setEnabled(bool enabled) async {
    if (_currentToken == null) return;
    try {
      await Supabase.instance.client
          .from('device_tokens')
          .update({'push_enabled': enabled})
          .eq('token', _currentToken!);
    } catch (e) {
      logger.w('Error actualizando push_enabled: $e');
    }
  }

  /// Actualiza las preferencias de categoría para este dispositivo.
  Future<void> updatePreferences(Map<String, bool> prefs) async {
    if (_currentToken == null) return;
    try {
      await Supabase.instance.client
          .from('device_tokens')
          .update({'preferences': prefs})
          .eq('token', _currentToken!);
    } catch (e) {
      logger.w('Error actualizando preferencias: $e');
    }
  }

  void dispose() {
    _authSub?.cancel();
  }
}
