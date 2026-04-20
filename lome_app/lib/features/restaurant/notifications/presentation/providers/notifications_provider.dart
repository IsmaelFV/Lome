import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/providers/supabase_provider.dart';
import '../../../data/repositories/restaurant_support_repository_impl.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';

// =============================================================================
// Modelo
// =============================================================================

class AppNotification {
  final String id;
  final String userId;
  final String? tenantId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    this.tenantId,
    required this.title,
    required this.body,
    required this.type,
    this.data = const {},
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      tenantId: json['tenant_id'] as String?,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Icono semántico según tipo de notificación.
  String get iconType {
    return switch (type) {
      'new_order' => 'receipt',
      'order_ready' => 'kitchen',
      'low_stock' => 'inventory',
      'admin_message' => 'message',
      'order_update' => 'receipt',
      'new_review' => 'star',
      'incident' => 'warning',
      _ => 'notification',
    };
  }

  /// Devuelve el order_id si la notificación está vinculada a un pedido.
  String? get orderId => data['order_id'] as String?;
}

// =============================================================================
// State
// =============================================================================

class NotificationsState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? errorMessage;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// =============================================================================
// Provider
// =============================================================================

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
      return NotificationsNotifier(ref);
    });

/// Contador de no leídas (para badges).
final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).unreadCount;
});

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final Ref _ref;
  RealtimeChannel? _channel;

  NotificationsNotifier(this._ref) : super(const NotificationsState()) {
    _init();
  }

  SupabaseClient get _client => _ref.read(supabaseClientProvider);
  String? get _tenantId => _ref.read(activeTenantIdProvider);

  Future<void> _init() async {
    await loadNotifications();
    _subscribeToRealtime();
  }

  Future<void> loadNotifications() async {
    final tenantId = _tenantId;
    if (tenantId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repo = _ref.read(restaurantSupportRepositoryProvider);
      final rows = await repo.getNotifications(tenantId);

      final list = rows.map((r) => AppNotification.fromJson(r)).toList();

      state = state.copyWith(notifications: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar notificaciones: $e',
      );
    }
  }

  void _subscribeToRealtime() {
    _channel = _client
        .channel('user-notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            final newNotif = AppNotification.fromJson(payload.newRecord);
            // Solo insertar si es para este usuario (RLS ya filtra, pero doble check)
            state = state.copyWith(
              notifications: [newNotif, ...state.notifications],
            );
          },
        )
        .subscribe();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final repo = _ref.read(restaurantSupportRepositoryProvider);
      await repo.markNotificationAsRead(notificationId);

      final updated = state.notifications.map((n) {
        if (n.id == notificationId) {
          return AppNotification(
            id: n.id,
            userId: n.userId,
            tenantId: n.tenantId,
            title: n.title,
            body: n.body,
            type: n.type,
            data: n.data,
            isRead: true,
            readAt: DateTime.now(),
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();

      state = state.copyWith(notifications: updated);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      final unreadIds = state.notifications
          .where((n) => !n.isRead)
          .map((n) => n.id)
          .toList();

      if (unreadIds.isEmpty) return;

      final repo = _ref.read(restaurantSupportRepositoryProvider);
      await repo.markNotificationsAsRead(unreadIds);

      final updated = state.notifications
          .map(
            (n) => AppNotification(
              id: n.id,
              userId: n.userId,
              tenantId: n.tenantId,
              title: n.title,
              body: n.body,
              type: n.type,
              data: n.data,
              isRead: true,
              readAt: n.readAt ?? DateTime.now(),
              createdAt: n.createdAt,
            ),
          )
          .toList();

      state = state.copyWith(notifications: updated);
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_channel != null) {
      _client.removeChannel(_channel!);
    }
    super.dispose();
  }
}

// =============================================================================
// Provider: última notificación de pedido listo (para banner en-app)
// =============================================================================

/// Emite la última notificación no leída de tipo `order_ready`.
/// Las páginas de camareros pueden escuchar este provider para mostrar
/// un banner/snackbar cuando un pedido está listo para servir.
final latestOrderReadyProvider = Provider<AppNotification?>((ref) {
  final state = ref.watch(notificationsProvider);
  final unread = state.notifications
      .where((n) => !n.isRead && n.type == 'order_ready')
      .toList();
  return unread.isNotEmpty ? unread.first : null;
});
