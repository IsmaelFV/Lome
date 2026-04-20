import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/push_notification_service.dart';

// =============================================================================
// Service provider
// =============================================================================

final pushNotificationServiceProvider = Provider<PushNotificationService>(
  (ref) => PushNotificationService.instance,
);

// =============================================================================
// Notification Preferences
// =============================================================================

class NotificationPreferences {
  final bool pushEnabled;
  final bool orders;
  final bool reviews;
  final bool stock;
  final bool system;

  const NotificationPreferences({
    this.pushEnabled = true,
    this.orders = true,
    this.reviews = true,
    this.stock = true,
    this.system = true,
  });

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? orders,
    bool? reviews,
    bool? stock,
    bool? system,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      orders: orders ?? this.orders,
      reviews: reviews ?? this.reviews,
      stock: stock ?? this.stock,
      system: system ?? this.system,
    );
  }

  Map<String, bool> toPreferencesMap() => {
        'orders': orders,
        'reviews': reviews,
        'stock': stock,
        'system': system,
      };
}

// =============================================================================
// Provider
// =============================================================================

final notificationPreferencesProvider = StateNotifierProvider<
    NotificationPreferencesNotifier, NotificationPreferences>(
  (ref) => NotificationPreferencesNotifier(
    ref.read(pushNotificationServiceProvider),
  ),
);

class NotificationPreferencesNotifier
    extends StateNotifier<NotificationPreferences> {
  final PushNotificationService _service;

  NotificationPreferencesNotifier(this._service)
      : super(const NotificationPreferences()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationPreferences(
      pushEnabled: prefs.getBool('push_enabled') ?? true,
      orders: prefs.getBool('push_orders') ?? true,
      reviews: prefs.getBool('push_reviews') ?? true,
      stock: prefs.getBool('push_stock') ?? true,
      system: prefs.getBool('push_system') ?? true,
    );
  }

  Future<void> setPushEnabled(bool value) async {
    state = state.copyWith(pushEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_enabled', value);
    await _service.setEnabled(value);
  }

  Future<void> setOrders(bool value) async {
    state = state.copyWith(orders: value);
    await _save('push_orders', value);
  }

  Future<void> setReviews(bool value) async {
    state = state.copyWith(reviews: value);
    await _save('push_reviews', value);
  }

  Future<void> setStock(bool value) async {
    state = state.copyWith(stock: value);
    await _save('push_stock', value);
  }

  Future<void> setSystem(bool value) async {
    state = state.copyWith(system: value);
    await _save('push_system', value);
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    await _service.updatePreferences(state.toPreferencesMap());
  }
}
