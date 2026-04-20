import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

/// Tipos de cuenta soportados en el registro.
enum AccountType { customer, restaurantOwner }

/// Fuente de datos remota para autenticacion.
///
/// Comunica directamente con Supabase Auth y la tabla profiles.
/// Gestiona el ciclo completo: registro, login, sesion, perfil y tenant.
abstract class AuthRemoteDataSource {
  Stream<AuthState> get authStateChanges;
  Session? get currentSession;
  Future<UserModel> signInWithEmail(String email, String password);
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required AccountType accountType,
    String? restaurantName,
  });
  Future<void> signOut();
  Future<UserModel> getCurrentUser();
  Future<void> resetPassword(String email);
  Future<void> updatePassword(String newPassword);
  Future<UserModel> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  });
  Future<void> resendVerificationEmail(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _client;

  AuthRemoteDataSourceImpl({required SupabaseClient client}) : _client = client;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const AuthException(message: 'Error al iniciar sesión');
      }

      // Verificar si el email fue confirmado
      if (response.user!.emailConfirmedAt == null) {
        throw const AuthException(
          message: 'Tu cuenta no ha sido verificada. Revisa tu email.',
          code: 'email_not_confirmed',
        );
      }

      return _fetchProfile(response.user!.id);
    } on AuthApiException catch (e) {
      throw _mapAuthApiException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required AccountType accountType,
    String? restaurantName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'account_type': accountType == AccountType.customer
              ? 'customer'
              : 'owner',
          if (phone != null) 'phone': phone,
          if (restaurantName != null) 'restaurant_name': restaurantName,
        },
        emailRedirectTo: null, // Usa la URL por defecto de Supabase
      );

      if (response.user == null) {
        throw const AuthException(message: 'Error al registrar usuario');
      }

      // El trigger handle_new_user de la BD (SECURITY DEFINER) crea:
      //   1. El perfil en profiles (con full_name, email, phone)
      //   2. Si account_type='owner': el tenant + membership con role='owner'
      // Todo esto ocurre atómicamente ANTES de que el SDK retorne la sesión.
      // No necesitamos hacer nada más que fetch el perfil.

      return _fetchProfile(response.user!.id);
    } on AuthApiException catch (e) {
      throw _mapAuthApiException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'No hay sesión activa');
    }
    return _fetchProfile(user.id);
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.lome://reset-callback',
      );
    } on AuthApiException catch (e) {
      throw _mapAuthApiException(e);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthApiException catch (e) {
      throw _mapAuthApiException(e);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final userId = _client.auth.currentUser!.id;
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await _client.from('profiles').update(updates).eq('id', userId);
      return _fetchProfile(userId);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> resendVerificationEmail(String email) async {
    try {
      await _client.auth.resend(type: OtpType.signup, email: email);
    } on AuthApiException catch (e) {
      throw _mapAuthApiException(e);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers privados
  // ---------------------------------------------------------------------------

  /// Obtiene el perfil completo con memberships y datos del tenant.
  Future<UserModel> _fetchProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select('''
          *,
          tenant_memberships!tenant_memberships_user_id_fkey (
            id,
            tenant_id,
            role,
            is_active,
            tenants (
              name,
              logo_url
            )
          )
        ''')
        .eq('id', userId)
        .single();

    return UserModel.fromJson(response);
  }

  /// Traduce errores de Supabase Auth a mensajes legibles en español.
  AuthException _mapAuthApiException(AuthApiException e) {
    final code = e.code ?? '';
    final message = switch (code) {
      'invalid_credentials' => 'Email o contraseña incorrectos',
      'user_not_found' => 'No existe una cuenta con este email',
      'email_not_confirmed' =>
        'Tu cuenta no ha sido verificada. Revisa tu email.',
      'user_already_exists' ||
      'email_exists' => 'Ya existe una cuenta con este email',
      'weak_password' =>
        'La contraseña es demasiado débil. Usa al menos 8 caracteres.',
      'over_request_rate_limit' || 'rate_limit' =>
        'Demasiados intentos. Espera un momento y vuelve a intentarlo.',
      'validation_failed' => 'Los datos introducidos no son válidos',
      'same_password' => 'La nueva contraseña debe ser diferente a la actual',
      _ => e.message,
    };
    return AuthException(message: message, code: code);
  }
}
