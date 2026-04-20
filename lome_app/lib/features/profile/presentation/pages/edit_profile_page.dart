import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators/form_validators.dart';
import '../../../../core/widgets/lome_button.dart';
import '../../../../core/widgets/lome_text_field.dart';
import '../providers/profile_provider.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

/// Pantalla de edición de perfil de usuario.
///
/// Muestra:
/// - Avatar con opción de cambio (galería o cámara, subida a Cloudinary)
/// - Nombre completo (editable)
/// - Email (solo lectura — se gestiona desde Supabase Auth)
/// - Teléfono (editable)
///
/// Flujo de subida de foto de perfil:
/// 1. Usuario toca el avatar → se muestra un bottom sheet para elegir fuente
/// 2. El picker de imágenes obtiene la foto (comprimida a 800×800, 85% calidad)
/// 3. Los bytes se envían a Cloudinary Upload API (POST multipart, unsigned)
/// 4. Cloudinary procesa la imagen y devuelve la URL segura
/// 5. La URL se guarda en `profiles.avatar_url` en Supabase
/// 6. La UI se actualiza mostrando la nueva foto
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initFields() {
    if (_initialized) return;
    final user = ref.read(profileNotifierProvider).user;
    if (user != null) {
      _nameController.text = user.fullName;
      _phoneController.text = user.phone ?? '';
      _initialized = true;
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final success = await ref
        .read(profileNotifierProvider.notifier)
        .updateProfile(
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.profileUpdated),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      );
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  context.l10n.editProfilePhotoChange,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      PhosphorIcons.images(),
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(context.l10n.editProfilePhotoGallery),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref
                        .read(profileNotifierProvider.notifier)
                        .pickAndUploadAvatar(source: ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(PhosphorIcons.camera(), color: AppColors.info),
                  ),
                  title: Text(context.l10n.editProfilePhotoCamera),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref
                        .read(profileNotifierProvider.notifier)
                        .pickAndUploadAvatar(source: ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final user = profileState.user;
    final theme = Theme.of(context);

    // Inicializar campos con los datos actuales del usuario
    _initFields();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(context.l10n.editProfile),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Avatar ───
                    Center(
                      child: _buildAvatarSection(
                        user.avatarUrl,
                        profileState.isUploadingAvatar,
                        theme,
                      ),
                    ).animate().fadeIn(duration: 500.ms),

                    const SizedBox(height: AppTheme.spacingXl),

                    // ─── Nombre ───
                    LomeTextField(
                      label: context.l10n.fullName,
                      hint: context.l10n.editProfileNameHint,
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icon(PhosphorIcons.user(), size: 20),
                      validator: (v) => FormValidators.required(v, 'El nombre'),
                    ).animate().fadeIn(delay: 100.ms, duration: 500.ms),

                    const SizedBox(height: AppTheme.spacingMd),

                    // ─── Email (solo lectura) ───
                    LomeTextField(
                      label: context.l10n.email,
                      hint: '',
                      controller: TextEditingController(text: user.email),
                      prefixIcon: Icon(PhosphorIcons.envelope(), size: 20),
                      enabled: false,
                    ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                    const SizedBox(height: AppTheme.spacingSm),
                    Padding(
                      padding: const EdgeInsets.only(left: AppTheme.spacingSm),
                      child: Text(
                        context.l10n.editProfileEmailNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.grey400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingMd),

                    // ─── Teléfono ───
                    LomeTextField(
                      label: context.l10n.phone,
                      hint: context.l10n.registerPhoneHint,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      prefixIcon: Icon(PhosphorIcons.phone(), size: 20),
                      validator: FormValidators.phone,
                    ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

                    const SizedBox(height: AppTheme.spacingXl),

                    // ─── Error ───
                    if (profileState.errorMessage != null)
                      Container(
                            padding: const EdgeInsets.all(AppTheme.spacingMd),
                            margin: const EdgeInsets.only(
                              bottom: AppTheme.spacingMd,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  PhosphorIcons.warningCircle(),
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: AppTheme.spacingSm),
                                Expanded(
                                  child: Text(
                                    profileState.errorMessage!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .shakeX(hz: 3, amount: 4, duration: 400.ms),

                    // ─── Botón Guardar ───
                    LomeButton(
                      label: context.l10n.saveChanges,
                      isExpanded: true,
                      isLoading: profileState.isLoading,
                      onPressed: _handleSave,
                    ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

                    const SizedBox(height: AppTheme.spacingXl),

                    // ─── Sección: Cambiar contraseña ───
                    _buildPasswordSection(
                      theme,
                      profileState,
                    ).animate().fadeIn(delay: 500.ms, duration: 500.ms),

                    const SizedBox(height: AppTheme.spacingXl),

                    // ─── Sección: Zona de peligro ───
                    _buildDangerZone(
                      theme,
                      profileState,
                    ).animate().fadeIn(delay: 600.ms, duration: 500.ms),

                    const SizedBox(height: AppTheme.spacingLg),
                  ],
                ),
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Password change section
  // ---------------------------------------------------------------------------

  Widget _buildPasswordSection(ThemeData theme, ProfileState profileState) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  PhosphorIcons.lock(),
                  size: 18,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                context.l10n.changePassword,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            context.l10n.editProfileNewPasswordDesc,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.grey500,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          LomeButton(
            label: context.l10n.changePassword,
            variant: LomeButtonVariant.outlined,
            isExpanded: true,
            icon: PhosphorIcons.key(),
            onPressed: () => _showChangePasswordDialog(theme),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(ThemeData theme) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    bool obscurePassword = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(context.l10n.changePassword),
              content: Form(
                key: dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LomeTextField(
                      label: context.l10n.editProfileNewPasswordHint,
                      hint: context.l10n.registerPasswordLength,
                      controller: passwordController,
                      obscureText: obscurePassword,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icon(PhosphorIcons.lock(), size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? PhosphorIcons.eyeSlash()
                              : PhosphorIcons.eye(),
                          size: 20,
                          color: AppColors.grey400,
                        ),
                        onPressed: () => setDialogState(
                          () => obscurePassword = !obscurePassword,
                        ),
                      ),
                      validator: FormValidators.password,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    LomeTextField(
                      label: context.l10n.registerConfirmPasswordLabel,
                      hint: context.l10n.editProfileConfirmPasswordHint,
                      controller: confirmController,
                      obscureText: obscureConfirm,
                      textInputAction: TextInputAction.done,
                      prefixIcon: Icon(PhosphorIcons.lock(), size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? PhosphorIcons.eyeSlash()
                              : PhosphorIcons.eye(),
                          size: 20,
                          color: AppColors.grey400,
                        ),
                        onPressed: () => setDialogState(
                          () => obscureConfirm = !obscureConfirm,
                        ),
                      ),
                      validator: (v) => FormValidators.confirmPassword(
                        v,
                        passwordController.text,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(context.l10n.cancel),
                ),
                LomeButton(
                  label: context.l10n.save,
                  isLoading: ref
                      .read(profileNotifierProvider)
                      .isChangingPassword,
                  onPressed: () async {
                    if (!dialogFormKey.currentState!.validate()) return;
                    final success = await ref
                        .read(profileNotifierProvider.notifier)
                        .changePassword(newPassword: passwordController.text);
                    if (success && ctx.mounted) {
                      Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.passwordChanged),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Danger zone (account deletion)
  // ---------------------------------------------------------------------------

  Widget _buildDangerZone(ThemeData theme, ProfileState profileState) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  PhosphorIcons.warning(PhosphorIconsStyle.duotone),
                  size: 18,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                context.l10n.editProfileDangerZone,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            context.l10n.editProfileDangerZoneDesc,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.grey600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          LomeButton(
            label: context.l10n.editProfileDeleteMyAccount,
            variant: LomeButtonVariant.danger,
            isExpanded: true,
            icon: PhosphorIcons.trash(),
            isLoading: profileState.isDeletingAccount,
            onPressed: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    PhosphorIcons.warning(PhosphorIconsStyle.duotone),
                    color: AppColors.error,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(context.l10n.deleteAccount),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.editProfileDeleteDialogDesc,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: AppColors.grey600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(
                        ctx,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.grey600),
                      children: [
                        TextSpan(
                          text: context.l10n.editProfileDeleteTypePrefix,
                        ),
                        TextSpan(
                          text: context.l10n.editProfileDeleteButton,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                        TextSpan(
                          text: context.l10n.editProfileDeleteTypeSuffix,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  TextField(
                    controller: confirmController,
                    decoration: InputDecoration(
                      hintText: context.l10n.editProfileDeleteButton,
                      isDense: true,
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(context.l10n.cancel),
                ),
                LomeButton(
                  label: context.l10n.deleteAccount,
                  variant: LomeButtonVariant.danger,
                  isLoading: ref
                      .read(profileNotifierProvider)
                      .isDeletingAccount,
                  onPressed:
                      confirmController.text ==
                          context.l10n.editProfileDeleteButton
                      ? () async {
                          final success = await ref
                              .read(profileNotifierProvider.notifier)
                              .deleteAccount();
                          if (success && ctx.mounted) {
                            Navigator.pop(ctx);
                            if (mounted) {
                              context.go('/login');
                            }
                          }
                        }
                      : null,
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Avatar section
  // ---------------------------------------------------------------------------

  Widget _buildAvatarSection(
    String? avatarUrl,
    bool isUploading,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: isUploading ? null : _showAvatarOptions,
      child: Column(
        children: [
          Stack(
            children: [
              // Avatar circle
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.grey200, width: 3),
                ),
                child: ClipOval(
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                            color: AppColors.grey100,
                            child: Icon(
                              PhosphorIcons.user(),
                              size: 48,
                              color: AppColors.grey400,
                            ),
                          ),
                          errorWidget: (_, _, _) => Container(
                            color: AppColors.grey100,
                            child: Icon(
                              PhosphorIcons.user(),
                              size: 48,
                              color: AppColors.grey400,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.grey100,
                          child: Icon(
                            PhosphorIcons.user(),
                            size: 48,
                            color: AppColors.grey400,
                          ),
                        ),
                ),
              ),

              // Upload overlay when loading
              if (isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.black.withValues(alpha: 0.4),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(AppColors.white),
                        ),
                      ),
                    ),
                  ),
                ),

              // Camera icon badge
              if (!isUploading)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      PhosphorIcons.camera(),
                      size: 16,
                      color: AppColors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            context.l10n.editProfilePhotoChangeShort,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
