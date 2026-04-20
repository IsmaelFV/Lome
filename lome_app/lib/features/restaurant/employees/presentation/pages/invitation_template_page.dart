import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../core/widgets/lome_loading.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../../../../shared/providers/supabase_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Constantes
// ---------------------------------------------------------------------------

const _templateStyles = [
  'professional',
  'casual',
  'elegant',
  'minimal',
  'colorful',
];

const _templateLabels = {
  'professional': 'Profesional',
  'casual': 'Casual',
  'elegant': 'Elegante',
  'minimal': 'Minimalista',
  'colorful': 'Colorido',
};

const _templateDescriptions = {
  'professional':
      'Colores oscuros y corporativos. Ideal para restaurantes formales.',
  'casual': 'Naranja y tonos cálidos. Perfecto para restaurantes informales.',
  'elegant': 'Dorados y marrón. Para restaurantes de alta cocina.',
  'minimal': 'Blanco y negro. Limpio y universal.',
  'colorful': 'Púrpura y rosa. Para marcas divertidas y modernas.',
};

final _templateIcons = {
  'professional': PhosphorIcons.briefcase(PhosphorIconsStyle.duotone),
  'casual': PhosphorIcons.sun(PhosphorIconsStyle.duotone),
  'elegant': PhosphorIcons.diamond(PhosphorIconsStyle.duotone),
  'minimal': PhosphorIcons.square(PhosphorIconsStyle.duotone),
  'colorful': PhosphorIcons.palette(PhosphorIconsStyle.duotone),
};

const _presetColors = [
  '#FF6B35',
  '#E74C3C',
  '#E91E63',
  '#9B59B6',
  '#6C5CE7',
  '#3498DB',
  '#1ABC9C',
  '#2ECC71',
  '#27AE60',
  '#F39C12',
  '#FDCB6E',
  '#D35400',
  '#8E6F47',
  '#795548',
  '#2D3436',
  '#636E72',
  '#1A1A2E',
  '#0F3460',
  '#000000',
  '#FFFFFF',
];

final _defaultColors = {
  'professional': {
    'primary_color': '#1A1A2E',
    'secondary_color': '#16213E',
    'background_color': '#F8F9FA',
    'button_color': '#0F3460',
    'text_color': '#2D3436',
    'accent_color': '#E94560',
  },
  'casual': {
    'primary_color': '#FF6B35',
    'secondary_color': '#2D3436',
    'background_color': '#FFF8F0',
    'button_color': '#FF6B35',
    'text_color': '#2D3436',
    'accent_color': '#FDCB6E',
  },
  'elegant': {
    'primary_color': '#2C3E50',
    'secondary_color': '#8E6F47',
    'background_color': '#FAF8F5',
    'button_color': '#8E6F47',
    'text_color': '#2C3E50',
    'accent_color': '#D4A574',
  },
  'minimal': {
    'primary_color': '#000000',
    'secondary_color': '#666666',
    'background_color': '#FFFFFF',
    'button_color': '#000000',
    'text_color': '#333333',
    'accent_color': '#999999',
  },
  'colorful': {
    'primary_color': '#6C5CE7',
    'secondary_color': '#A29BFE',
    'background_color': '#F8F7FF',
    'button_color': '#6C5CE7',
    'text_color': '#2D3436',
    'accent_color': '#FD79A8',
  },
};

// ---------------------------------------------------------------------------
// Provider: Invitation template
// ---------------------------------------------------------------------------

final invitationTemplateProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
      final client = ref.read(supabaseClientProvider);
      final tenantId = ref.read(activeTenantIdProvider);
      if (tenantId == null) return null;

      final response = await client.rpc(
        'get_or_create_invitation_template',
        params: {'p_tenant_id': tenantId},
      );

      if (response is List && response.isNotEmpty) {
        return response.first as Map<String, dynamic>;
      }
      return null;
    });

// ---------------------------------------------------------------------------
// Página: Editor de plantilla de invitación
// ---------------------------------------------------------------------------

class InvitationTemplatePage extends ConsumerStatefulWidget {
  const InvitationTemplatePage({super.key});

  @override
  ConsumerState<InvitationTemplatePage> createState() =>
      _InvitationTemplatePageState();
}

class _InvitationTemplatePageState
    extends ConsumerState<InvitationTemplatePage> {
  // -- Campos de estado --
  String _templateStyle = 'casual';
  String _primaryColor = '#FF6B35';
  String _secondaryColor = '#2D3436';
  String _backgroundColor = '#FFF8F0';
  String _buttonColor = '#FF6B35';
  String _textColor = '#2D3436';
  String _accentColor = '#FDCB6E';
  bool _showLogo = true;
  bool _showRestaurantInfo = true;

  final _subjectController = TextEditingController();
  final _headerController = TextEditingController();
  final _bodyController = TextEditingController();
  final _buttonTextController = TextEditingController();
  final _footerController = TextEditingController();
  final _declineController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasChanges = false;
  String? _templateId;

  @override
  void dispose() {
    _subjectController.dispose();
    _headerController.dispose();
    _bodyController.dispose();
    _buttonTextController.dispose();
    _footerController.dispose();
    _declineController.dispose();
    super.dispose();
  }

  void _loadFromDb(Map<String, dynamic> data) {
    _templateId = data['id'] as String?;
    _templateStyle = data['template_style'] as String? ?? 'casual';
    _primaryColor = data['primary_color'] as String? ?? '#FF6B35';
    _secondaryColor = data['secondary_color'] as String? ?? '#2D3436';
    _backgroundColor = data['background_color'] as String? ?? '#FFF8F0';
    _buttonColor = data['button_color'] as String? ?? '#FF6B35';
    _textColor = data['text_color'] as String? ?? '#2D3436';
    _accentColor = data['accent_color'] as String? ?? '#FDCB6E';
    _showLogo = data['show_logo'] as bool? ?? true;
    _showRestaurantInfo = data['show_restaurant_info'] as bool? ?? true;
    _subjectController.text = data['subject_line'] as String? ?? '';
    _headerController.text = data['header_text'] as String? ?? '';
    _bodyController.text = data['body_text'] as String? ?? '';
    _buttonTextController.text = data['button_text'] as String? ?? '';
    _footerController.text = data['footer_text'] as String? ?? '';
    _declineController.text = data['decline_text'] as String? ?? '';
  }

  void _applyPreset(String style) {
    final colors = _defaultColors[style];
    if (colors == null) return;
    setState(() {
      _templateStyle = style;
      _primaryColor = colors['primary_color']!;
      _secondaryColor = colors['secondary_color']!;
      _backgroundColor = colors['background_color']!;
      _buttonColor = colors['button_color']!;
      _textColor = colors['text_color']!;
      _accentColor = colors['accent_color']!;
      _hasChanges = true;
    });
  }

  Future<void> _save() async {
    if (_templateId == null) return;

    setState(() => _isSaving = true);
    try {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('invitation_templates')
          .update({
            'template_style': _templateStyle,
            'primary_color': _primaryColor,
            'secondary_color': _secondaryColor,
            'background_color': _backgroundColor,
            'button_color': _buttonColor,
            'text_color': _textColor,
            'accent_color': _accentColor,
            'show_logo': _showLogo,
            'show_restaurant_info': _showRestaurantInfo,
            'subject_line': _subjectController.text,
            'header_text': _headerController.text,
            'body_text': _bodyController.text,
            'button_text': _buttonTextController.text,
            'footer_text': _footerController.text,
            'decline_text': _declineController.text,
          })
          .eq('id', _templateId!);

      _hasChanges = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.invTemplSaved),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final templateAsync = ref.watch(invitationTemplateProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(
        title: context.l10n.invTemplTitle,
        actions: [
          if (_hasChanges)
            TextButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(PhosphorIcons.floppyDisk(PhosphorIconsStyle.duotone)),
              label: Text(context.l10n.save),
            ),
        ],
      ),
      body: templateAsync.when(
        loading: () => const Center(child: LomeLoading()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          if (data == null) {
            return Center(child: Text(context.l10n.invTemplNoTenant));
          }

          // Cargar datos solo la primera vez
          if (!_isLoading && _templateId == null) {
            _isLoading = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => _loadFromDb(data));
            });
          }

          if (_templateId == null) {
            return const Center(child: LomeLoading());
          }

          return ListView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.all(16),
            children:
                [
                      // ── Plantillas predeterminadas ──
                      _SectionTitle(
                        icon: PhosphorIcons.swatches(PhosphorIconsStyle.duotone),
                        title: context.l10n.invTemplPresets,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 140,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _templateStyles.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final style = _templateStyles[index];
                            final isSelected = style == _templateStyle;
                            final colors = _defaultColors[style]!;
                            return _TemplatePresetCard(
                              style: style,
                              label: _templateLabels[style]!,
                              description: _templateDescriptions[style]!,
                              icon: _templateIcons[style]!,
                              primaryColor: colors['primary_color']!,
                              secondaryColor: colors['secondary_color']!,
                              buttonColor: colors['button_color']!,
                              isSelected: isSelected,
                              onTap: () => _applyPreset(style),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Preview del email ──
                      _SectionTitle(
                        icon: PhosphorIcons.eye(PhosphorIconsStyle.duotone),
                        title: context.l10n.invTemplPreview,
                      ),
                      const SizedBox(height: 12),
                      _EmailPreview(
                        primaryColor: _primaryColor,
                        secondaryColor: _secondaryColor,
                        backgroundColor: _backgroundColor,
                        buttonColor: _buttonColor,
                        textColor: _textColor,
                        accentColor: _accentColor,
                        headerText: _headerController.text.isNotEmpty
                            ? _headerController.text
                            : '¡Hola!',
                        bodyText: _bodyController.text.isNotEmpty
                            ? _bodyController.text
                                  .replaceAll('{restaurant}', 'Mi Restaurante')
                                  .replaceAll('{inviter}', 'Carlos')
                                  .replaceAll('{role}', 'Camarero/a')
                                  .replaceAll('{email}', 'ejemplo@mail.com')
                                  .replaceAll('{expire_date}', '1 abr 2026')
                            : 'Carlos te ha invitado a unirte al equipo de Mi Restaurante como Camarero/a.',
                        buttonText: _buttonTextController.text.isNotEmpty
                            ? _buttonTextController.text
                            : 'Aceptar Invitación',
                        showLogo: _showLogo,
                        showRestaurantInfo: _showRestaurantInfo,
                      ),

                      const SizedBox(height: 28),

                      // ── Colores ──
                      _SectionTitle(
                        icon: PhosphorIcons.palette(PhosphorIconsStyle.duotone),
                        title: context.l10n.invTemplColors,
                      ),
                      const SizedBox(height: 12),
                      _ColorRow(
                        label: context.l10n.invTemplPrimaryColor,
                        color: _primaryColor,
                        onChanged: (c) => setState(() {
                          _primaryColor = c;
                          _hasChanges = true;
                        }),
                      ),
                      _ColorRow(
                        label: context.l10n.invTemplSecondaryColor,
                        color: _secondaryColor,
                        onChanged: (c) => setState(() {
                          _secondaryColor = c;
                          _hasChanges = true;
                        }),
                      ),
                      _ColorRow(
                        label: context.l10n.invTemplButtonColor,
                        color: _buttonColor,
                        onChanged: (c) => setState(() {
                          _buttonColor = c;
                          _hasChanges = true;
                        }),
                      ),
                      _ColorRow(
                        label: context.l10n.invTemplAccentColor,
                        color: _accentColor,
                        onChanged: (c) => setState(() {
                          _accentColor = c;
                          _hasChanges = true;
                        }),
                      ),
                      _ColorRow(
                        label: context.l10n.invTemplBgColor,
                        color: _backgroundColor,
                        onChanged: (c) => setState(() {
                          _backgroundColor = c;
                          _hasChanges = true;
                        }),
                      ),
                      _ColorRow(
                        label: context.l10n.invTemplTextColor,
                        color: _textColor,
                        onChanged: (c) => setState(() {
                          _textColor = c;
                          _hasChanges = true;
                        }),
                      ),

                      const SizedBox(height: 28),

                      // ── Opciones de visualización ──
                      _SectionTitle(
                        icon: PhosphorIcons.eye(PhosphorIconsStyle.duotone),
                        title: context.l10n.invTemplDisplayOptions,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        title: Text(context.l10n.invTemplShowLogo),
                        subtitle: Text(context.l10n.invTemplShowLogoDesc),
                        value: _showLogo,
                        onChanged: (v) => setState(() {
                          _showLogo = v;
                          _hasChanges = true;
                        }),
                      ),
                      SwitchListTile.adaptive(
                        title: Text(context.l10n.invTemplShowRestInfo),
                        subtitle: Text(context.l10n.invTemplShowRestInfoDesc),
                        value: _showRestaurantInfo,
                        onChanged: (v) => setState(() {
                          _showRestaurantInfo = v;
                          _hasChanges = true;
                        }),
                      ),

                      const SizedBox(height: 28),

                      // ── Textos personalizables ──
                      _SectionTitle(
                        icon: PhosphorIcons.notepad(PhosphorIconsStyle.duotone),
                        title: context.l10n.invTemplTexts,
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          context.l10n.invTemplVariablesHint,
                          style: const TextStyle(fontSize: 12, color: AppColors.grey500),
                        ),
                      ),
                      _TextFieldTile(
                        label: context.l10n.invTemplSubjectLine,
                        controller: _subjectController,
                        onChanged: () => setState(() => _hasChanges = true),
                      ),
                      _TextFieldTile(
                        label: context.l10n.invTemplHeaderText,
                        controller: _headerController,
                        onChanged: () => setState(() => _hasChanges = true),
                      ),
                      _TextFieldTile(
                        label: context.l10n.invTemplBodyText,
                        controller: _bodyController,
                        maxLines: 3,
                        onChanged: () => setState(() => _hasChanges = true),
                      ),
                      _TextFieldTile(
                        label: context.l10n.invTemplButtonText,
                        controller: _buttonTextController,
                        onChanged: () => setState(() => _hasChanges = true),
                      ),
                      _TextFieldTile(
                        label: context.l10n.invTemplFooterText,
                        controller: _footerController,
                        maxLines: 2,
                        onChanged: () => setState(() => _hasChanges = true),
                      ),
                      _TextFieldTile(
                        label: context.l10n.invTemplDeclineText,
                        controller: _declineController,
                        onChanged: () => setState(() => _hasChanges = true),
                      ),

                      const SizedBox(height: 80),
                    ]
                    .animate(interval: 40.ms)
                    .fadeIn(duration: 200.ms)
                    .slideY(begin: 0.02, end: 0, duration: 200.ms),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Widgets auxiliares
// =============================================================================

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.grey900,
          ),
        ),
      ],
    );
  }
}

// ─── Preset Card ─────────────────────────────────────────────────────────────

class _TemplatePresetCard extends StatelessWidget {
  final String style;
  final String label;
  final String description;
  final IconData icon;
  final String primaryColor;
  final String secondaryColor;
  final String buttonColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplatePresetCard({
    required this.style,
    required this.label,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.buttonColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pColor = _parseHex(primaryColor);
    final sColor = _parseHex(secondaryColor);

    return TactileWrapper(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey200,
            width: isSelected ? 2.5 : 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [pColor, sColor],
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: pColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const Spacer(),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIcons.check(PhosphorIconsStyle.bold),
                      size: 14,
                      color: pColor,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Email Preview ───────────────────────────────────────────────────────────

class _EmailPreview extends StatelessWidget {
  final String primaryColor;
  final String secondaryColor;
  final String backgroundColor;
  final String buttonColor;
  final String textColor;
  final String accentColor;
  final String headerText;
  final String bodyText;
  final String buttonText;
  final bool showLogo;
  final bool showRestaurantInfo;

  const _EmailPreview({
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.buttonColor,
    required this.textColor,
    required this.accentColor,
    required this.headerText,
    required this.bodyText,
    required this.buttonText,
    required this.showLogo,
    required this.showRestaurantInfo,
  });

  @override
  Widget build(BuildContext context) {
    final pColor = _parseHex(primaryColor);
    final sColor = _parseHex(secondaryColor);
    final bgColor = _parseHex(backgroundColor);
    final btnColor = _parseHex(buttonColor);
    final txtColor = _parseHex(textColor);
    final accColor = _parseHex(accentColor);
    final btnTextColor =
        ThemeData.estimateBrightnessForColor(btnColor) == Brightness.light
        ? Colors.black
        : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          // Header gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              gradient: LinearGradient(
                colors: [pColor, sColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                if (showLogo) ...[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                child: Icon(
                      PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (showRestaurantInfo)
                  const Text(
                    'Mi Restaurante',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headerText,
                  style: TextStyle(
                    color: pColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  bodyText,
                  style: TextStyle(color: txtColor, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 20),

                // Role badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accColor.withValues(alpha: 0.12),
                      border: Border.all(color: accColor),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Rol: Camarero/a',
                      style: TextStyle(
                        color: pColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // CTA button
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: btnColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        color: btnTextColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(15),
              ),
              border: const Border(top: BorderSide(color: AppColors.grey200)),
            ),
            child: Column(
              children: [
                Text(
                  'Powered by LŌME',
                  style: TextStyle(color: AppColors.grey400, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Color Row ───────────────────────────────────────────────────────────────

class _ColorRow extends StatelessWidget {
  final String label;
  final String color;
  final ValueChanged<String> onChanged;

  const _ColorRow({
    required this.label,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          TactileWrapper(
            onTap: () => _showColorPicker(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _parseHex(color),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.grey300),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.grey700))),
          Text(
            color,
            style: const TextStyle(
              color: AppColors.grey500,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _presetColors.map((hex) {
            final isSelected = hex.toLowerCase() == color.toLowerCase();
            return TactileWrapper(
              onTap: () {
                onChanged(hex);
                Navigator.pop(ctx);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _parseHex(hex),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.grey300,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        PhosphorIcons.check(PhosphorIconsStyle.bold),
                        color:
                            ThemeData.estimateBrightnessForColor(
                                  _parseHex(hex),
                                ) ==
                                Brightness.light
                            ? Colors.black
                            : Colors.white,
                        size: 18,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Text Field Tile ─────────────────────────────────────────────────────────

class _TextFieldTile extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final VoidCallback onChanged;

  const _TextFieldTile({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

Color _parseHex(String hex) {
  final h = hex.replaceFirst('#', '');
  if (h.length == 6) {
    return Color(int.parse('FF$h', radix: 16));
  }
  return const Color(0xFF2D3436);
}
