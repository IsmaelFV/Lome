import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// =============================================================================
// Modelo
// =============================================================================

/// Estados operativos posibles del restaurante.
enum OperationalStatus {
  open,
  closed,
  temporarilyClosed;

  String get label => switch (this) {
    open => 'Abierto',
    closed => 'Cerrado',
    temporarilyClosed => 'Cerrado temporalmente',
  };

  String get dbValue => switch (this) {
    open => 'open',
    closed => 'closed',
    temporarilyClosed => 'temporarily_closed',
  };

  static OperationalStatus fromDb(String value) => switch (value) {
    'open' => OperationalStatus.open,
    'closed' => OperationalStatus.closed,
    'temporarily_closed' => OperationalStatus.temporarilyClosed,
    _ => OperationalStatus.open,
  };
}

// =============================================================================
// State
// =============================================================================

class RestaurantStatusState {
  final OperationalStatus status;
  final bool isLoading;
  final String? errorMessage;

  const RestaurantStatusState({
    this.status = OperationalStatus.open,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get acceptsOrders => status == OperationalStatus.open;

  RestaurantStatusState copyWith({
    OperationalStatus? status,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RestaurantStatusState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// =============================================================================
// Provider
// =============================================================================

final restaurantStatusProvider =
    StateNotifierProvider<RestaurantStatusNotifier, RestaurantStatusState>((
      ref,
    ) {
      return RestaurantStatusNotifier(ref);
    });

/// Shortcut: ¿el restaurante acepta pedidos ahora?
final acceptsOrdersProvider = Provider<bool>((ref) {
  return ref.watch(restaurantStatusProvider).acceptsOrders;
});

class RestaurantStatusNotifier extends StateNotifier<RestaurantStatusState> {
  final Ref _ref;

  RestaurantStatusNotifier(this._ref) : super(const RestaurantStatusState()) {
    _loadStatus();
  }

  SupabaseClient get _client => _ref.read(supabaseClientProvider);
  String? get _tenantId => _ref.read(activeTenantIdProvider);

  Future<void> _loadStatus() async {
    final tenantId = _tenantId;
    if (tenantId == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final row = await _client
          .from('tenants')
          .select('operational_status')
          .eq('id', tenantId)
          .single();

      final dbStatus = row['operational_status'] as String? ?? 'open';
      state = state.copyWith(
        status: OperationalStatus.fromDb(dbStatus),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar estado: $e',
      );
    }
  }

  Future<void> setStatus(OperationalStatus newStatus) async {
    final tenantId = _tenantId;
    if (tenantId == null) return;

    final previous = state.status;
    // Optimistic update
    state = state.copyWith(status: newStatus, clearError: true);

    try {
      await _client
          .from('tenants')
          .update({'operational_status': newStatus.dbValue})
          .eq('id', tenantId);
    } catch (e) {
      // Revertir
      state = state.copyWith(
        status: previous,
        errorMessage: 'Error al cambiar estado: $e',
      );
    }
  }
}
