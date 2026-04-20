import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de almacenamiento local.
///
/// Usa SharedPreferences para datos no sensibles y
/// FlutterSecureStorage para datos sensibles (tokens, claves).
class StorageService {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  StorageService({
    required SharedPreferences prefs,
    FlutterSecureStorage? secure,
  })  : _prefs = prefs,
        _secure = secure ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  // -------------------------------------------------------------------------
  // SharedPreferences (non-sensitive)
  // -------------------------------------------------------------------------

  // Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyActiveTenantId = 'active_tenant_id';
  static const String keyLocale = 'locale';

  String? getString(String key) => _prefs.getString(key);
  Future<bool> setString(String key, String value) => _prefs.setString(key, value);

  bool? getBool(String key) => _prefs.getBool(key);
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  int? getInt(String key) => _prefs.getInt(key);
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  Future<bool> remove(String key) => _prefs.remove(key);

  Future<bool> clear() => _prefs.clear();

  // -------------------------------------------------------------------------
  // Secure Storage (sensitive)
  // -------------------------------------------------------------------------

  Future<String?> getSecure(String key) => _secure.read(key: key);
  Future<void> setSecure(String key, String value) =>
      _secure.write(key: key, value: value);
  Future<void> removeSecure(String key) => _secure.delete(key: key);
  Future<void> clearSecure() => _secure.deleteAll();

  // -------------------------------------------------------------------------
  // Convenience methods
  // -------------------------------------------------------------------------

  String? get activeTenantId => getString(keyActiveTenantId);
  Future<bool> setActiveTenantId(String id) => setString(keyActiveTenantId, id);

  bool get isOnboardingComplete => getBool(keyOnboardingComplete) ?? false;
  Future<bool> setOnboardingComplete() => setBool(keyOnboardingComplete, true);
}
