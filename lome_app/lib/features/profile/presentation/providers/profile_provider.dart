import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../shared/services/cloudinary_service.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/profile_repository_impl.dart';

// ---------------------------------------------------------------------------
// Services
// ---------------------------------------------------------------------------

/// Provider del servicio de Cloudinary.
final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});

/// Provider del ImagePicker.
final imagePickerProvider = Provider<ImagePicker>((ref) {
  return ImagePicker();
});

// ---------------------------------------------------------------------------
// Profile Notifier
// ---------------------------------------------------------------------------

/// Estado del perfil.
class ProfileState {
  final UserEntity? user;
  final bool isLoading;
  final bool isUploadingAvatar;
  final bool isChangingPassword;
  final bool isDeletingAccount;
  final String? errorMessage;
  final String? successMessage;

  const ProfileState({
    this.user,
    this.isLoading = false,
    this.isUploadingAvatar = false,
    this.isChangingPassword = false,
    this.isDeletingAccount = false,
    this.errorMessage,
    this.successMessage,
  });

  ProfileState copyWith({
    UserEntity? user,
    bool? isLoading,
    bool? isUploadingAvatar,
    bool? isChangingPassword,
    bool? isDeletingAccount,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      isChangingPassword: isChangingPassword ?? this.isChangingPassword,
      isDeletingAccount: isDeletingAccount ?? this.isDeletingAccount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

/// Notifier para la gestión del perfil de usuario.
///
/// Maneja:
/// - Carga del perfil actual desde el auth state
/// - Subida de foto de perfil a Cloudinary
/// - Actualización de nombre, teléfono
/// - Guardado de la URL del avatar en la BD
final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref);
});

class ProfileNotifier extends StateNotifier<ProfileState> {
  final Ref _ref;

  ProfileNotifier(this._ref) : super(const ProfileState()) {
    // Cargar el usuario actual al inicializar
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    final user = _ref.read(currentUserProvider).valueOrNull;
    if (user != null) {
      state = state.copyWith(user: user);
    }
  }

  /// Limpia mensajes de error y éxito.
  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  /// Selecciona y sube una foto de perfil.
  ///
  /// Flujo:
  /// 1. Abre el picker de imágenes (galería o cámara)
  /// 2. Lee los bytes de la imagen seleccionada
  /// 3. Los envía a Cloudinary vía HTTP multipart POST
  /// 4. Cloudinary devuelve la URL segura
  /// 5. La URL se guarda en la tabla `profiles` via `updateProfile`
  /// 6. El estado del perfil se actualiza con la nueva URL
  Future<void> pickAndUploadAvatar({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final picker = _ref.read(imagePickerProvider);
      final image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return; // Canceló

      state = state.copyWith(
        isUploadingAvatar: true,
        clearError: true,
      );

      // Leer los bytes de la imagen
      final Uint8List bytes = await image.readAsBytes();
      final fileName = image.name;

      // Subir a Cloudinary
      final cloudinary = _ref.read(cloudinaryServiceProvider);
      final result = await cloudinary.uploadImage(
        imageBytes: bytes,
        fileName: fileName,
        folder: 'lome/avatars',
      );

      // Generar URL optimizada para avatar (200×200, face detection)
      final optimizedUrl = CloudinaryService.avatarUrl(result.secureUrl);

      // Guardar la URL en la base de datos
      final repository = _ref.read(authRepositoryProvider);
      final updateResult = await repository.updateProfile(
        avatarUrl: optimizedUrl,
      );

      updateResult.fold(
        (failure) {
          state = state.copyWith(
            isUploadingAvatar: false,
            errorMessage: failure.message,
          );
        },
        (updatedUser) {
          state = state.copyWith(
            user: updatedUser,
            isUploadingAvatar: false,
            successMessage: 'Foto de perfil actualizada',
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isUploadingAvatar: false,
        errorMessage: 'Error al subir la imagen: $e',
      );
    }
  }

  /// Actualiza los datos del perfil (nombre y/o teléfono).
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final repository = _ref.read(authRepositoryProvider);
    final result = await repository.updateProfile(
      fullName: fullName,
      phone: phone,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (updatedUser) {
        state = state.copyWith(
          user: updatedUser,
          isLoading: false,
          successMessage: 'Perfil actualizado correctamente',
        );
        return true;
      },
    );
  }

  /// Cambia la contraseña del usuario.
  ///
  /// Usa el endpoint de Supabase Auth para actualizar la contraseña.
  /// No requiere la contraseña actual ya que el usuario ya está autenticado.
  Future<bool> changePassword({required String newPassword}) async {
    state = state.copyWith(isChangingPassword: true, clearError: true, clearSuccess: true);

    final repository = _ref.read(authRepositoryProvider);
    final result = await repository.updatePassword(newPassword: newPassword);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isChangingPassword: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(
          isChangingPassword: false,
          successMessage: 'Contraseña actualizada correctamente',
        );
        return true;
      },
    );
  }

  /// Solicita la eliminación de la cuenta del usuario.
  ///
  /// Flujo GDPR:
  /// 1. El frontend llama a una Edge Function de Supabase
  /// 2. La Edge Function anonimiza los datos del perfil:
  ///    - full_name → 'Usuario eliminado'
  ///    - email → hash@deleted.lome.app
  ///    - phone → null
  ///    - avatar_url → null
  /// 3. Desactiva todas las membresías del usuario
  /// 4. Marca la cuenta de auth como eliminada
  /// 5. Las referencias (pedidos, etc.) mantienen el user_id
  ///    pero los datos personales ya están anonimizados
  Future<bool> deleteAccount() async {
    state = state.copyWith(isDeletingAccount: true, clearError: true);

    try {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(
          isDeletingAccount: false,
          errorMessage: 'No hay sesión activa',
        );
        return false;
      }

      // Llamar a la Edge Function para anonimizar y eliminar
      final repo = _ref.read(profileRepositoryProvider);
      await repo.deleteAccount(userId);

      state = state.copyWith(
        isDeletingAccount: false,
        user: null,
        successMessage: 'Cuenta eliminada correctamente',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isDeletingAccount: false,
        errorMessage: 'Error al eliminar la cuenta: $e',
      );
      return false;
    }
  }
}
