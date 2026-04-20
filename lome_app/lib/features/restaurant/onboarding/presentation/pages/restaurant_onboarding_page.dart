import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/services/cloudinary_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/lome_button.dart';
import '../../../../../core/widgets/lome_text_field.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../settings/presentation/providers/restaurant_settings_provider.dart';
import '../../../hours/presentation/providers/restaurant_hours_provider.dart';
import '../providers/restaurant_onboarding_provider.dart';

/// Wizard de onboarding para nuevos restaurantes.
///
/// 4 pasos: Info básica → Contacto/Dirección → Horarios → Confirmación
class RestaurantOnboardingPage extends ConsumerStatefulWidget {
  const RestaurantOnboardingPage({super.key});

  @override
  ConsumerState<RestaurantOnboardingPage> createState() =>
      _RestaurantOnboardingPageState();
}

class _RestaurantOnboardingPageState
    extends ConsumerState<RestaurantOnboardingPage>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _progressController;

  int _currentStep = 0;
  static const _totalSteps = 4;

  // Step 1: Info básica
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  Uint8List? _logoBytes;
  String? _logoUrl;
  final _selectedCuisines = <String>[];
  bool _isUploadingLogo = false;

  // Step 2: Contacto y dirección
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  // Step 3: Horarios
  final _selectedDays = <int>{};
  TimeOfDay _openTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 22, minute: 0);
  bool _sameHoursAllDays = true;
  final _daySchedules = <int, _DaySchedule>{};

  // Step 4: Confirmación
  bool _isSaving = false;

  final _formKeys = List.generate(_totalSteps, (_) => GlobalKey<FormState>());

  static const _cuisineOptions = [
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: AppTheme.durationMedium,
    );

    // Pre-fill name from tenant
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user != null && user.hasTenants) {
        final tenantName = user.defaultMembership?.tenantName ?? '';
        if (tenantName.isNotEmpty) {
          _nameController.text = tenantName;
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _totalSteps) return;

    // Validate current step before going forward
    if (step > _currentStep) {
      if (!_formKeys[_currentStep].currentState!.validate()) return;
    }

    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: AppTheme.durationMedium,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
    );
    if (xFile == null) return;

    final bytes = await xFile.readAsBytes();
    setState(() {
      _logoBytes = bytes;
      _isUploadingLogo = true;
    });

    try {
      final tenantId = ref.read(activeTenantIdProvider);
      final url = await CloudinaryService.uploadImage(
        bytes: bytes,
        folder: 'lome/restaurants/$tenantId',
        publicId: 'logo',
      );
      final optimized = CloudinaryService.optimizedUrl(
        url,
        width: 300,
        height: 300,
      );
      setState(() {
        _logoUrl = optimized;
        _isUploadingLogo = false;
      });
    } catch (_) {
      setState(() => _isUploadingLogo = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir el logo')),
        );
      }
    }
  }

  Future<void> _pickTime(BuildContext context, bool isOpen) async {
    final initial = isOpen ? _openTime : _closeTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: AppTheme.light.copyWith(
          timePickerTheme: TimePickerThemeData(
            backgroundColor: AppColors.white,
            hourMinuteColor: AppColors.primarySoft,
            dialHandColor: AppColors.primary,
            dialBackgroundColor: AppColors.grey50,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isOpen) {
          _openTime = picked;
        } else {
          _closeTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _completeOnboarding() async {
    setState(() => _isSaving = true);

    try {
      final tenantId = ref.read(activeTenantIdProvider);
      if (tenantId == null) return;

      // Save restaurant data
      final settingsNotifier = ref.read(restaurantSettingsProvider.notifier);
      await settingsNotifier.save(RestaurantData(
        id: tenantId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        logoUrl: _logoUrl,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        addressLine1: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        postalCode: _postalCodeController.text.trim().isEmpty
            ? null
            : _postalCodeController.text.trim(),
        cuisineType: _selectedCuisines,
      ));

      // Save hours
      if (_selectedDays.isNotEmpty) {
        final hoursNotifier = ref.read(restaurantHoursProvider.notifier);
        for (final day in _selectedDays) {
          final schedule = _sameHoursAllDays
              ? null
              : _daySchedules[day];
          final open = schedule?.open ?? _openTime;
          final close = schedule?.close ?? _closeTime;
          await hoursNotifier.saveHour(
            dayOfWeek: day,
            openTime: _formatTime(open),
            closeTime: _formatTime(close),
          );
        }
      }

      // Mark onboarding complete
      await ref.read(onboardingCompleteProvider.notifier).markComplete();

      if (mounted) {
        context.go(RoutePaths.tables);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1BasicInfo(),
                  _buildStep2Contact(),
                  _buildStep3Hours(),
                  _buildStep4Confirmation(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    const titles = [
      'Tu restaurante',
      'Contacto',
      'Horarios',
      '¡Listo!',
    ];
    const subtitles = [
      'Cuéntanos sobre tu negocio',
      'Cómo te encuentran tus clientes',
      'Cuándo estás abierto',
      'Revisa y comienza',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        AppTheme.spacingMd,
        AppTheme.spacingLg,
        AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(
              _stepIcon(_currentStep),
              color: AppColors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: AppTheme.durationFast,
                  child: Text(
                    titles[_currentStep],
                    key: ValueKey('title-$_currentStep'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey900,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: AppTheme.durationFast,
                  child: Text(
                    subtitles[_currentStep],
                    key: ValueKey('sub-$_currentStep'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.grey500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_currentStep + 1} / $_totalSteps',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.grey400,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  IconData _stepIcon(int step) {
    switch (step) {
      case 0:
        return PhosphorIcons.storefront(PhosphorIconsStyle.duotone);
      case 1:
        return PhosphorIcons.mapPin(PhosphorIconsStyle.duotone);
      case 2:
        return PhosphorIcons.clock(PhosphorIconsStyle.duotone);
      case 3:
        return PhosphorIcons.checkCircle(PhosphorIconsStyle.duotone);
      default:
        return PhosphorIcons.storefront(PhosphorIconsStyle.duotone);
    }
  }

  // ---------------------------------------------------------------------------
  // Progress Bar
  // ---------------------------------------------------------------------------

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final isCompleted = i < _currentStep;
          final isCurrent = i == _currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: AppTheme.durationMedium,
              curve: Curves.easeOutCubic,
              height: 4,
              margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 4 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isCompleted
                    ? AppColors.primary
                    : isCurrent
                        ? AppColors.primaryLight
                        : AppColors.grey200,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1: Info básica
  // ---------------------------------------------------------------------------

  Widget _buildStep1BasicInfo() {
    return Form(
      key: _formKeys[0],
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        children: [
          // Logo upload
          Center(
            child: GestureDetector(
              onTap: _isUploadingLogo ? null : _pickLogo,
              child: AnimatedContainer(
                duration: AppTheme.durationMedium,
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _logoBytes != null
                        ? AppColors.primary
                        : AppColors.grey200,
                    width: 2,
                  ),
                  image: _logoBytes != null
                      ? DecorationImage(
                          image: MemoryImage(_logoBytes!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _isUploadingLogo
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : _logoBytes == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                PhosphorIcons.camera(
                                    PhosphorIconsStyle.duotone),
                                size: 28,
                                color: AppColors.grey400,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Logo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.grey400,
                                ),
                              ),
                            ],
                          )
                        : null,
              ),
            ),
          ).animate().scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 400.ms,
                curve: Curves.easeOutBack,
              ),

          const SizedBox(height: AppTheme.spacingLg),

          LomeTextField(
            label: 'Nombre del restaurante',
            hint: 'Ej: La Trattoria de Mario',
            controller: _nameController,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
            prefixIcon: Icon(
              PhosphorIcons.storefront(PhosphorIconsStyle.light),
              size: 20,
            ),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          LomeTextField(
            label: 'Descripción',
            hint: 'Breve descripción de tu restaurante...',
            controller: _descriptionController,
            maxLines: 3,
            prefixIcon: Icon(
              PhosphorIcons.textAlignLeft(PhosphorIconsStyle.light),
              size: 20,
            ),
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // Cuisine types
          const Text(
            'Tipo de cocina',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.grey700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _cuisineOptions.map((cuisine) {
              final selected = _selectedCuisines.contains(cuisine);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedCuisines.remove(cuisine);
                    } else {
                      _selectedCuisines.add(cuisine);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: AppTheme.durationFast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primarySoft : AppColors.grey50,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(
                      color:
                          selected ? AppColors.primary : AppColors.grey200,
                    ),
                  ),
                  child: Text(
                    cuisine,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                      color:
                          selected ? AppColors.primary : AppColors.grey600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2: Contacto y dirección
  // ---------------------------------------------------------------------------

  Widget _buildStep2Contact() {
    return Form(
      key: _formKeys[1],
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        children: [
          _buildSectionLabel(
            'Contacto',
            PhosphorIcons.phone(PhosphorIconsStyle.duotone),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          LomeTextField(
            label: 'Teléfono',
            hint: '+34 600 000 000',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            prefixIcon: Icon(
              PhosphorIcons.phone(PhosphorIconsStyle.light),
              size: 20,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          LomeTextField(
            label: 'Email de contacto',
            hint: 'info@mirestaurante.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icon(
              PhosphorIcons.envelope(PhosphorIconsStyle.light),
              size: 20,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          LomeTextField(
            label: 'Sitio web',
            hint: 'https://mirestaurante.com',
            controller: _websiteController,
            keyboardType: TextInputType.url,
            prefixIcon: Icon(
              PhosphorIcons.globe(PhosphorIconsStyle.light),
              size: 20,
            ),
          ),

          const SizedBox(height: AppTheme.spacingXl),

          _buildSectionLabel(
            'Dirección',
            PhosphorIcons.mapPin(PhosphorIconsStyle.duotone),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          LomeTextField(
            label: 'Dirección',
            hint: 'Calle, número...',
            controller: _addressController,
            prefixIcon: Icon(
              PhosphorIcons.mapPin(PhosphorIconsStyle.light),
              size: 20,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: LomeTextField(
                  label: 'Ciudad',
                  hint: 'Madrid',
                  controller: _cityController,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: LomeTextField(
                  label: 'C.P.',
                  hint: '28001',
                  controller: _postalCodeController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // Optional note
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.info(PhosphorIconsStyle.duotone),
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingMd),
                const Expanded(
                  child: Text(
                    'Todos estos campos son opcionales. Podrás completarlos después desde Ajustes.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3: Horarios
  // ---------------------------------------------------------------------------

  Widget _buildStep3Hours() {
    return Form(
      key: _formKeys[2],
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        children: [
          const Text(
            'Selecciona los días que abres',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.grey700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Day selector grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (day) {
              final selected = _selectedDays.contains(day);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedDays.remove(day);
                    } else {
                      _selectedDays.add(day);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: AppTheme.durationFast,
                  width: 72,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.grey50,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.grey200,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    RestaurantHour.dayShort(day),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.white : AppColors.grey600,
                    ),
                  ),
                ),
              );
            }),
          ),

          if (_selectedDays.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingLg),

            // Same hours toggle
            GestureDetector(
              onTap: () {
                setState(() => _sameHoursAllDays = !_sameHoursAllDays);
              },
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: AppTheme.durationFast,
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _sameHoursAllDays
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _sameHoursAllDays
                              ? AppColors.primary
                              : AppColors.grey300,
                          width: 2,
                        ),
                      ),
                      child: _sameHoursAllDays
                          ? const Icon(Icons.check,
                              size: 14, color: AppColors.white)
                          : null,
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    const Expanded(
                      child: Text(
                        'Mismo horario todos los días',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.grey700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingMd),

            if (_sameHoursAllDays) ...[
              _buildTimeRow('Apertura', _openTime, () => _pickTime(context, true)),
              const SizedBox(height: AppTheme.spacingMd),
              _buildTimeRow('Cierre', _closeTime, () => _pickTime(context, false)),
            ] else ...[
              ...(_selectedDays.toList()..sort()).map((day) {
                final schedule = _daySchedules[day] ??
                    _DaySchedule(open: _openTime, close: _closeTime);
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          RestaurantHour.dayName(day),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey700,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Row(
                          children: [
                            Expanded(
                              child: _buildCompactTimeButton(
                                schedule.open,
                                () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: schedule.open,
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _daySchedules[day] = schedule.copyWith(
                                          open: picked);
                                    });
                                  }
                                },
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('—',
                                  style: TextStyle(color: AppColors.grey400)),
                            ),
                            Expanded(
                              child: _buildCompactTimeButton(
                                schedule.close,
                                () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: schedule.close,
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _daySchedules[day] = schedule.copyWith(
                                          close: picked);
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],

          const SizedBox(height: AppTheme.spacingLg),

          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.info(PhosphorIconsStyle.duotone),
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingMd),
                const Expanded(
                  child: Text(
                    'Podrás configurar horarios más detallados después desde Ajustes > Horarios.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 4: Confirmation
  // ---------------------------------------------------------------------------

  Widget _buildStep4Confirmation() {
    return Form(
      key: _formKeys[3],
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        children: [
          // Success illustration
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                PhosphorIcons.rocketLaunch(PhosphorIconsStyle.duotone),
                color: AppColors.white,
                size: 36,
              ),
            ),
          ).animate().scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              ),

          const SizedBox(height: AppTheme.spacingLg),

          const Text(
            '¡Todo listo para empezar!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
          ),

          const SizedBox(height: AppTheme.spacingSm),

          const Text(
            'Revisa el resumen de tu restaurante. Puedes modificar todo esto después desde Ajustes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey500,
            ),
          ),

          const SizedBox(height: AppTheme.spacingXl),

          // Summary cards
          _buildSummaryCard(
            icon: PhosphorIcons.storefront(PhosphorIconsStyle.duotone),
            title: 'Restaurante',
            items: [
              _nameController.text.trim(),
              if (_descriptionController.text.trim().isNotEmpty)
                _descriptionController.text.trim(),
              if (_selectedCuisines.isNotEmpty)
                _selectedCuisines.join(', '),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMd),

          _buildSummaryCard(
            icon: PhosphorIcons.mapPin(PhosphorIconsStyle.duotone),
            title: 'Contacto y ubicación',
            items: [
              if (_phoneController.text.trim().isNotEmpty)
                '📞 ${_phoneController.text.trim()}',
              if (_emailController.text.trim().isNotEmpty)
                '✉ ${_emailController.text.trim()}',
              if (_addressController.text.trim().isNotEmpty)
                '📍 ${_addressController.text.trim()}',
              if (_cityController.text.trim().isNotEmpty)
                _cityController.text.trim(),
              if (_phoneController.text.trim().isEmpty &&
                  _emailController.text.trim().isEmpty &&
                  _addressController.text.trim().isEmpty)
                'Sin datos de contacto aún',
            ],
          ),

          const SizedBox(height: AppTheme.spacingMd),

          _buildSummaryCard(
            icon: PhosphorIcons.clock(PhosphorIconsStyle.duotone),
            title: 'Horarios',
            items: _selectedDays.isEmpty
                ? ['Sin horarios configurados aún']
                : [
                    'Días: ${(_selectedDays.toList()..sort()).map((d) => RestaurantHour.dayShort(d)).join(', ')}',
                    if (_sameHoursAllDays)
                      '${_formatTime(_openTime)} — ${_formatTime(_closeTime)}',
                  ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Bar
  // ---------------------------------------------------------------------------

  Widget _buildBottomBar() {
    final isLastStep = _currentStep == _totalSteps - 1;
    final isFirstStep = _currentStep == 0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isFirstStep)
            Expanded(
              child: LomeButton(
                label: 'Atrás',
                variant: LomeButtonVariant.outlined,
                onPressed: () => _goToStep(_currentStep - 1),
                icon: PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
              ),
            ),
          if (!isFirstStep) const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            flex: isFirstStep ? 1 : 1,
            child: LomeButton(
              label: isLastStep ? 'Comenzar' : 'Siguiente',
              isLoading: _isSaving,
              onPressed: isLastStep
                  ? _completeOnboarding
                  : () => _goToStep(_currentStep + 1),
              icon: isLastStep
                  ? PhosphorIcons.rocketLaunch(PhosphorIconsStyle.bold)
                  : PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppTheme.spacingSm),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.grey900,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRow(String label, TimeOfDay time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIcons.clock(PhosphorIconsStyle.light),
              size: 20,
              color: AppColors.grey500,
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.grey500,
              ),
            ),
            const Spacer(),
            Text(
              _formatTime(time),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Icon(
              PhosphorIcons.caretRight(PhosphorIconsStyle.light),
              size: 16,
              color: AppColors.grey400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTimeButton(TimeOfDay time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppColors.grey200),
        ),
        alignment: Alignment.center,
        child: Text(
          _formatTime(time),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppTheme.spacingSm),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(
                left: 40,
                bottom: 4,
              ),
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.grey600,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }
}

// =============================================================================
// Helper class for per-day schedules
// =============================================================================

class _DaySchedule {
  final TimeOfDay open;
  final TimeOfDay close;

  const _DaySchedule({required this.open, required this.close});

  _DaySchedule copyWith({TimeOfDay? open, TimeOfDay? close}) =>
      _DaySchedule(
        open: open ?? this.open,
        close: close ?? this.close,
      );
}
