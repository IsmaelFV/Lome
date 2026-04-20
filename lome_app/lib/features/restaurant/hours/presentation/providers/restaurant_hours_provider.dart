import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/providers/supabase_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';

// =============================================================================
// Modelo
// =============================================================================

class RestaurantHour {
  final String? id;
  final String tenantId;
  final int dayOfWeek; // 0=Lun, 1=Mar, ..., 6=Dom
  final String openTime; // HH:mm
  final String closeTime;
  final bool isActive;

  const RestaurantHour({
    this.id,
    required this.tenantId,
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
    this.isActive = true,
  });

  factory RestaurantHour.fromJson(Map<String, dynamic> json) {
    return RestaurantHour(
      id: json['id'] as String?,
      tenantId: json['tenant_id'] as String,
      dayOfWeek: json['day_of_week'] as int,
      openTime: (json['open_time'] as String).substring(0, 5),
      closeTime: (json['close_time'] as String).substring(0, 5),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toInsertJson() => {
    'tenant_id': tenantId,
    'day_of_week': dayOfWeek,
    'open_time': openTime,
    'close_time': closeTime,
    'is_active': isActive,
  };

  static String dayName(int day) {
    const names = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return names[day];
  }

  static String dayShort(int day) {
    const names = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return names[day];
  }
}

// =============================================================================
// State
// =============================================================================

class RestaurantHoursState {
  final List<RestaurantHour> hours;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const RestaurantHoursState({
    this.hours = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  /// Devuelve las franjas horarias de un día concreto.
  List<RestaurantHour> hoursForDay(int day) =>
      hours.where((h) => h.dayOfWeek == day && h.isActive).toList();

  /// true si hay al menos una franja configurada para un día.
  bool isDayOpen(int day) => hoursForDay(day).isNotEmpty;

  RestaurantHoursState copyWith({
    List<RestaurantHour>? hours,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return RestaurantHoursState(
      hours: hours ?? this.hours,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

// =============================================================================
// Provider
// =============================================================================

final restaurantHoursProvider =
    StateNotifierProvider<RestaurantHoursNotifier, RestaurantHoursState>((ref) {
      return RestaurantHoursNotifier(ref);
    });

class RestaurantHoursNotifier extends StateNotifier<RestaurantHoursState> {
  final Ref _ref;

  RestaurantHoursNotifier(this._ref) : super(const RestaurantHoursState()) {
    loadHours();
  }

  SupabaseClient get _client => _ref.read(supabaseClientProvider);
  String? get _tenantId => _ref.read(activeTenantIdProvider);

  Future<void> loadHours() async {
    final tenantId = _tenantId;
    if (tenantId == null) return;

    state = state.copyWith(isLoading: true, clearMessages: true);

    try {
      final rows = await _client
          .from('restaurant_hours')
          .select()
          .eq('tenant_id', tenantId)
          .eq('is_active', true)
          .order('day_of_week')
          .order('open_time');

      final hours = (rows as List)
          .map((r) => RestaurantHour.fromJson(r))
          .toList();

      state = state.copyWith(hours: hours, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar horarios: $e',
      );
    }
  }

  /// Guarda una franja horaria (crea o actualiza).
  Future<void> saveHour({
    String? id,
    required int dayOfWeek,
    required String openTime,
    required String closeTime,
  }) async {
    final tenantId = _tenantId;
    if (tenantId == null) return;

    state = state.copyWith(isSaving: true, clearMessages: true);

    try {
      if (id != null) {
        await _client
            .from('restaurant_hours')
            .update({'open_time': openTime, 'close_time': closeTime})
            .eq('id', id);
      } else {
        await _client.from('restaurant_hours').insert({
          'tenant_id': tenantId,
          'day_of_week': dayOfWeek,
          'open_time': openTime,
          'close_time': closeTime,
        });
      }

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Horario guardado',
      );
      await loadHours();
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error al guardar horario: $e',
      );
    }
  }

  Future<void> deleteHour(String hourId) async {
    state = state.copyWith(isSaving: true, clearMessages: true);

    try {
      await _client.from('restaurant_hours').delete().eq('id', hourId);

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Franja horaria eliminada',
      );
      await loadHours();
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error al eliminar: $e',
      );
    }
  }
}
