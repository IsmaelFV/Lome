import 'dart:async';
import 'dart:collection';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/providers/supabase_provider.dart';
import '../config/env.dart';

// ─── Modelo de evento de monitorización ──────────────────────────────────────

class _MonitoringEvent {
  final String type; // 'error' | 'api_usage'
  final Map<String, dynamic> payload;

  const _MonitoringEvent({required this.type, required this.payload});

  Map<String, dynamic> toJson() => {'type': type, 'payload': payload};
}

// ─── Servicio de Monitorización ──────────────────────────────────────────────

/// Servicio central de monitorización técnica de la plataforma LŌME.
///
/// Responsabilidades:
/// 1. **Reporte de errores**: Captura excepciones y las envía a `error_logs`.
/// 2. **Tiempos de respuesta**: Mide y registra la duración de cada llamada API.
/// 3. **Uso de API**: Registra endpoints, métodos HTTP y códigos de respuesta.
///
/// Implementa un **buffer con flush periódico** para no saturar la red:
/// los eventos se acumulan en memoria y se envían en lotes cada 30 segundos
/// o cuando el buffer alcanza 50 eventos.
class MonitoringService {
  final SupabaseClient _client;

  /// Buffer interno de eventos pendientes de envío.
  final Queue<_MonitoringEvent> _buffer = Queue();

  /// Temporizador para flush periódico.
  Timer? _flushTimer;

  /// Máximo de eventos en buffer antes de flush automático.
  static const _maxBufferSize = 50;

  /// Intervalo entre flushes periódicos.
  static const _flushInterval = Duration(seconds: 30);

  /// Información del dispositivo (cacheada al inicio).
  late final Map<String, dynamic> _deviceInfo;

  MonitoringService(this._client) {
    _deviceInfo = _buildDeviceInfo();
    _startPeriodicFlush();
  }

  // ─── Error Reporting ─────────────────────────────────────────────────────

  /// Reporta un error al sistema de monitorización.
  void reportError({
    required String message,
    String severity = 'error',
    String source = 'flutter',
    String? stackTrace,
    String? tenantId,
    Map<String, dynamic>? context,
  }) {
    _enqueue(_MonitoringEvent(
      type: 'error',
      payload: {
        'severity': severity,
        'source': source,
        'message': message,
        'stack_trace': stackTrace,
        'tenant_id': tenantId,
        'device_info': _deviceInfo,
        'app_version': Env.appVersion,
        'context': context ?? {},
      },
    ));
  }

  /// Captura un error de Flutter (para usar con FlutterError.onError).
  void captureFlutterError(FlutterErrorDetails details) {
    reportError(
      message: details.exceptionAsString(),
      severity: 'error',
      source: 'flutter',
      stackTrace: details.stack?.toString(),
      context: {
        'library': details.library,
        'context': details.context?.toString(),
      },
    );
  }

  /// Captura un error de plataforma (para PlatformDispatcher.onError).
  void capturePlatformError(Object error, StackTrace stack) {
    reportError(
      message: error.toString(),
      severity: 'error',
      source: 'platform',
      stackTrace: stack.toString(),
    );
  }

  // ─── API Timing ──────────────────────────────────────────────────────────

  /// Mide el tiempo de una operación async y registra el resultado.
  ///
  /// Uso:
  /// ```dart
  /// final result = await monitoring.trackApiCall(
  ///   endpoint: '/rest/v1/orders',
  ///   method: 'GET',
  ///   operation: () => supabase.from('orders').select(),
  /// );
  /// ```
  Future<T> trackApiCall<T>({
    required String endpoint,
    required String method,
    required Future<T> Function() operation,
    String? tenantId,
  }) async {
    final stopwatch = Stopwatch()..start();
    int? statusCode;

    try {
      final result = await operation();
      stopwatch.stop();
      statusCode = 200;
      return result;
    } catch (e) {
      stopwatch.stop();
      statusCode = _extractStatusCode(e);
      rethrow;
    } finally {
      _enqueue(_MonitoringEvent(
        type: 'api_usage',
        payload: {
          'endpoint': endpoint,
          'method': method,
          'status_code': statusCode,
          'response_time_ms': stopwatch.elapsedMilliseconds,
          'tenant_id': tenantId,
          'metadata': {
            'timestamp': DateTime.now().toIso8601String(),
          },
        },
      ));
    }
  }

  /// Registra una llamada API ya completada (sin medir el tiempo).
  void logApiCall({
    required String endpoint,
    required String method,
    int? statusCode,
    int? responseTimeMs,
    String? tenantId,
  }) {
    _enqueue(_MonitoringEvent(
      type: 'api_usage',
      payload: {
        'endpoint': endpoint,
        'method': method,
        'status_code': statusCode,
        'response_time_ms': responseTimeMs,
        'tenant_id': tenantId,
      },
    ));
  }

  // ─── Buffer Management ───────────────────────────────────────────────────

  void _enqueue(_MonitoringEvent event) {
    _buffer.add(event);
    if (_buffer.length >= _maxBufferSize) {
      flush();
    }
  }

  void _startPeriodicFlush() {
    _flushTimer = Timer.periodic(_flushInterval, (_) => flush());
  }

  /// Envía todos los eventos acumulados al backend.
  Future<void> flush() async {
    if (_buffer.isEmpty) return;

    // Extraer todos los eventos del buffer
    final events = _buffer.toList();
    _buffer.clear();

    try {
      await _client.functions.invoke(
        'log-event',
        body: {
          'type': 'batch',
          'events': events.map((e) => e.toJson()).toList(),
        },
      );
    } catch (_) {
      // Si falla el envío, re-encolar los eventos (hasta el límite)
      if (_buffer.length + events.length <= _maxBufferSize * 2) {
        for (final event in events) {
          _buffer.add(event);
        }
      }
      // Si superamos el doble del buffer, descartamos los más viejos
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Map<String, dynamic> _buildDeviceInfo() {
    try {
      if (kIsWeb) {
        return {'platform': 'web'};
      }
      return {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
        'locale': Platform.localeName,
      };
    } catch (_) {
      return {'platform': 'unknown'};
    }
  }

  int? _extractStatusCode(Object error) {
    if (error is PostgrestException) {
      return int.tryParse(error.code ?? '');
    }
    return 500;
  }

  /// Libera recursos.
  void dispose() {
    _flushTimer?.cancel();
    // Intentar enviar los eventos pendientes antes de destruir
    flush();
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final monitoringServiceProvider = Provider<MonitoringService>((ref) {
  final service = MonitoringService(ref.read(supabaseClientProvider));
  ref.onDispose(() => service.dispose());
  return service;
});
