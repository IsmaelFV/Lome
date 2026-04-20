import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../auth/presentation/providers/auth_provider.dart';

/// Provider que expone si el onboarding del tenant activo está completo.
///
/// Usa una key compuesta `onboarding_complete_{tenantId}` para soportar
/// múltiples restaurantes por usuario.
final onboardingCompleteProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final tenantId = ref.watch(activeTenantIdProvider);
  return OnboardingNotifier(tenantId);
});

class OnboardingNotifier extends StateNotifier<bool> {
  final String? _tenantId;

  OnboardingNotifier(this._tenantId) : super(false) {
    _loadState();
  }

  String get _key => 'onboarding_complete_${_tenantId ?? 'none'}';

  Future<void> _loadState() async {
    if (_tenantId == null) {
      state = false;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> markComplete() async {
    if (_tenantId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    state = true;
  }

  Future<void> reset() async {
    if (_tenantId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    state = false;
  }
}
