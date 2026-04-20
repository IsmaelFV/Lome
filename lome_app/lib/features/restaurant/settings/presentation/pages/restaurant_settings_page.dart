import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/validators/form_validators.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../core/widgets/lome_button.dart';
import '../../../../../core/widgets/lome_text_field.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../providers/restaurant_settings_provider.dart';

/// Tipos de cocina disponibles.
const _cuisineOptions = [
  'Mediterránea',
  'Italiana',
  'Japonesa',
  'Mexicana',
  'Americana',
  'China',
  'India',
  'Tailandesa',
  'Francesa',
  'Española',
  'Peruana',
  'Árabe',
  'Vegana',
  'Fusión',
  'Otro',
];

/// Página de edición de datos del restaurante.
///
/// Permite modificar nombre, descripción, logo, dirección, contacto
/// y tipos de cocina del tenant activo.
class RestaurantSettingsPage extends ConsumerStatefulWidget {
  const RestaurantSettingsPage({super.key});

  @override
  ConsumerState<RestaurantSettingsPage> createState() =>
      _RestaurantSettingsPageState();
}

class _RestaurantSettingsPageState
    extends ConsumerState<RestaurantSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _address2Ctrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _postalCtrl;

  List<String> _selectedCuisine = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _websiteCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _address2Ctrl = TextEditingController();
    _cityCtrl = TextEditingController();
    _stateCtrl = TextEditingController();
    _postalCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _addressCtrl.dispose();
    _address2Ctrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _postalCtrl.dispose();
    super.dispose();
  }

  void _populateFields(RestaurantData data) {
    _nameCtrl.text = data.name;
    _descCtrl.text = data.description ?? '';
    _phoneCtrl.text = data.phone ?? '';
    _emailCtrl.text = data.email ?? '';
    _websiteCtrl.text = data.website ?? '';
    _addressCtrl.text = data.addressLine1 ?? '';
    _address2Ctrl.text = data.addressLine2 ?? '';
    _cityCtrl.text = data.city ?? '';
    _stateCtrl.text = data.state ?? '';
    _postalCtrl.text = data.postalCode ?? '';
    _selectedCuisine = List<String>.from(data.cuisineType);
    _initialized = true;
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      ref.read(restaurantSettingsProvider.notifier).uploadLogo(bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final current = ref.read(restaurantSettingsProvider).data;
    if (current == null) return;

    final updated = current.copyWith(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      website: _websiteCtrl.text.trim().isEmpty
          ? null
          : _websiteCtrl.text.trim(),
      addressLine1: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      addressLine2: _address2Ctrl.text.trim().isEmpty
          ? null
          : _address2Ctrl.text.trim(),
      city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      state: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
      postalCode: _postalCtrl.text.trim().isEmpty
          ? null
          : _postalCtrl.text.trim(),
      cuisineType: _selectedCuisine,
    );

    ref.read(restaurantSettingsProvider.notifier).save(updated);
  }

  String _cuisineLabel(BuildContext context, String cuisine) {
    return switch (cuisine) {
      'Mediterránea' => context.l10n.cuisineMediterranean,
      'Italiana' => context.l10n.cuisineItalian,
      'Japonesa' => context.l10n.cuisineJapanese,
      'Mexicana' => context.l10n.cuisineMexican,
      'Americana' => context.l10n.cuisineAmerican,
      'China' => context.l10n.cuisineChinese,
      'India' => context.l10n.cuisineIndian,
      'Tailandesa' => context.l10n.cuisineThai,
      'Francesa' => context.l10n.cuisineFrench,
      'Española' => context.l10n.cuisineSpanish,
      'Peruana' => context.l10n.cuisinePeruvian,
      'Árabe' => context.l10n.cuisineArabic,
      'Vegana' => context.l10n.cuisineVegan,
      'Fusión' => context.l10n.cuisineFusion,
      'Otro' => context.l10n.cuisineOther,
      _ => cuisine,
    };
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(restaurantSettingsProvider);

    // Poblar campos cuando llegan datos por primera vez
    if (!_initialized && settingsState.data != null) {
      _populateFields(settingsState.data!);
    }

    // Mensajes de feedback
    ref.listen<RestaurantSettingsState>(restaurantSettingsProvider, (
      prev,
      next,
    ) {
      if (next.successMessage != null && prev?.successMessage == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.successMessage!),
              backgroundColor: AppColors.success,
            ),
          );
      }
      if (next.errorMessage != null && prev?.errorMessage == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(title: context.l10n.restaurantSettingsTitle),
      body: settingsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                children: [
                  // ── Logo ──
                  _LogoSection(
                    logoUrl: settingsState.data?.logoUrl,
                    isSaving: settingsState.isSaving,
                    onPickLogo: _pickLogo,
                  ),

                  const SizedBox(height: AppTheme.spacingLg),

                  // ── Información básica ──
                  Text(
                    context.l10n.restaurantSettingsBasicInfo,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey500,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),

                  LomeTextField(
                    label: context.l10n.restaurantSettingsNameLabel,
                    controller: _nameCtrl,
                    validator: (v) => FormValidators.required(v, 'El nombre'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  LomeTextField(
                    label: context.l10n.restaurantSettingsDescLabel,
                    controller: _descCtrl,
                    hint: context.l10n.restaurantSettingsDescHint,
                    maxLines: 3,
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: AppTheme.spacingLg),

                  // ── Contacto ──
                  Text(
                    context.l10n.restaurantSettingsContact,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey500,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),

                  LomeTextField(
                    label: context.l10n.restaurantSettingsPhoneLabel,
                    controller: _phoneCtrl,
                    hint: context.l10n.restaurantSettingsPhoneHint,
                    validator: FormValidators.phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icon(PhosphorIcons.phone(PhosphorIconsStyle.duotone), size: 18),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  LomeTextField(
                    label: context.l10n.restaurantSettingsEmailLabel,
                    controller: _emailCtrl,
                    hint: context.l10n.restaurantSettingsEmailHint,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      return FormValidators.email(v);
                    },
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icon(PhosphorIcons.envelope(PhosphorIconsStyle.duotone), size: 18),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  LomeTextField(
                    label: context.l10n.restaurantSettingsWebLabel,
                    controller: _websiteCtrl,
                    hint: context.l10n.restaurantSettingsWebHint,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icon(PhosphorIcons.globe(PhosphorIconsStyle.duotone), size: 18),
                  ),

                  const SizedBox(height: AppTheme.spacingLg),

                  // ── Dirección ──
                  Text(
                    context.l10n.restaurantSettingsAddressSection,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey500,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),

                  LomeTextField(
                    label: context.l10n.restaurantSettingsAddressLabel,
                    controller: _addressCtrl,
                    hint: context.l10n.restaurantSettingsAddressHint,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icon(PhosphorIcons.mapPin(PhosphorIconsStyle.duotone), size: 18),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  LomeTextField(
                    label: context.l10n.restaurantSettingsAddress2Label,
                    controller: _address2Ctrl,
                    hint: context.l10n.restaurantSettingsAddress2Hint,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: LomeTextField(
                          label: context.l10n.restaurantSettingsCityLabel,
                          controller: _cityCtrl,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: LomeTextField(
                          label: context.l10n.restaurantSettingsStateLabel,
                          controller: _stateCtrl,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  LomeTextField(
                    label: context.l10n.restaurantSettingsPostalLabel,
                    controller: _postalCtrl,
                    hint: context.l10n.restaurantSettingsPostalHint,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                  ),

                  const SizedBox(height: AppTheme.spacingLg),

                  // ── Tipos de cocina ──
                  Text(
                    context.l10n.restaurantSettingsCuisine,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey500,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),

                  Wrap(
                    spacing: AppTheme.spacingSm,
                    runSpacing: AppTheme.spacingXs,
                    children: _cuisineOptions.map((c) {
                      final selected = _selectedCuisine.contains(c);
                      return FilterChip(
                        label: Text(_cuisineLabel(context, c)),
                        selected: selected,
                        selectedColor: AppColors.primary.withValues(
                          alpha: 0.15,
                        ),
                        checkmarkColor: AppColors.primary,
                        side: BorderSide(
                          color: selected
                              ? AppColors.primary
                              : AppColors.grey200,
                        ),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedCuisine.add(c);
                            } else {
                              _selectedCuisine.remove(c);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppTheme.spacingXl),

                  // ── Guardar ──
                  LomeButton(
                    label: context.l10n.saveChanges,
                    isExpanded: true,
                    isLoading: settingsState.isSaving,
                    onPressed: settingsState.isSaving ? null : _submit,
                  ),

                  const SizedBox(height: AppTheme.spacingXl),
                ],
              ),
            ),
    );
  }
}

// =============================================================================
// Logo section
// =============================================================================

class _LogoSection extends StatelessWidget {
  final String? logoUrl;
  final bool isSaving;
  final VoidCallback onPickLogo;

  const _LogoSection({
    this.logoUrl,
    required this.isSaving,
    required this.onPickLogo,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: isSaving ? null : onPickLogo,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.grey100,
                  backgroundImage: logoUrl != null
                      ? CachedNetworkImageProvider(logoUrl!)
                      : null,
                  child: logoUrl == null
                      ? Icon(
                          PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
                          size: 36,
                          color: AppColors.grey400,
                        )
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Icon(
                          PhosphorIcons.camera(PhosphorIconsStyle.duotone),
                          size: 16,
                          color: AppColors.white,
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            context.l10n.restaurantSettingsChangeLogo,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey400,
            ),
          ),
        ],
      ),
    );
  }
}
