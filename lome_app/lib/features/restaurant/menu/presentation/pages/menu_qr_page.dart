import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../../core/config/env.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../providers/menu_provider.dart';

/// Página para generar y compartir el QR de la carta digital.
class MenuQrPage extends ConsumerStatefulWidget {
  const MenuQrPage({super.key});

  @override
  ConsumerState<MenuQrPage> createState() => _MenuQrPageState();
}

class _MenuQrPageState extends ConsumerState<MenuQrPage> {
  final _qrKey = GlobalKey();
  String _selectedStyle = 'modern';

  String get _menuUrl {
    final tenantId = ref.read(activeTenantIdProvider) ?? '';
    // URL pública de la carta digital
    final baseUrl = Env.supabaseUrl.isNotEmpty
        ? Env.supabaseUrl.replaceAll('.supabase.co', '.lome.app')
        : 'https://app.lome.app';
    return '$baseUrl/menu/$tenantId';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final designAsync = ref.watch(menuDesignProvider);
    final isPublished = designAsync.valueOrNull?.isPublished ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(title: 'QR de la Carta'),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          children: [
            // ── Estado de publicacion ─────────────────────────────────
            _buildPublishStatus(isPublished, theme),
            const SizedBox(height: AppTheme.spacingLg),

            // ── QR Card ──────────────────────────────────────────────
            _buildQrCard(theme),
            const SizedBox(height: AppTheme.spacingLg),

            // ── URL ──────────────────────────────────────────────────
            _buildUrlCard(theme),
            const SizedBox(height: AppTheme.spacingLg),

            // ── Estilos de QR ────────────────────────────────────────
            _buildStyleSelector(theme),
            const SizedBox(height: AppTheme.spacingLg),

            // ── Instrucciones ────────────────────────────────────────
            _buildInstructions(theme),
          ],
        ),
      ),
    );
  }

  // ── Estado de publicacion ─────────────────────────────────────────────────

  Widget _buildPublishStatus(bool isPublished, ThemeData theme) {
    return AnimatedContainer(
      duration: AppTheme.durationFast,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: isPublished
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isPublished
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPublished
                ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                : PhosphorIcons.warning(),
            color: isPublished ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              isPublished
                  ? 'Tu carta digital está publicada y visible para los clientes'
                  : 'Tu carta aún no está publicada. Edita el diseño y publícala primero.',
              style: TextStyle(
                fontSize: 14,
                color: isPublished ? AppColors.success : AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ── QR Card ───────────────────────────────────────────────────────────────

  Widget _buildQrCard(ThemeData theme) {
    return RepaintBoundary(
          key: _qrKey,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: AppShadows.card,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                children: [
                  const Text(
                    'Escanea para ver la carta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey800,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  _buildQrWidget(theme),
                  const SizedBox(height: AppTheme.spacingMd),
                  const Text(
                    'LOME',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 100.ms, duration: 400.ms)
        .scaleXY(begin: 0.95, end: 1.0, delay: 100.ms, duration: 400.ms);
  }

  Widget _buildQrWidget(ThemeData theme) {
    final qrColor = _selectedStyle == 'dark'
        ? Colors.white
        : AppColors.grey900;
    final bgColor = _selectedStyle == 'dark'
        ? AppColors.grey900
        : Colors.white;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: QrImageView(
        data: _menuUrl,
        version: QrVersions.auto,
        size: 220,
        eyeStyle: QrEyeStyle(
          eyeShape: _selectedStyle == 'rounded'
              ? QrEyeShape.circle
              : QrEyeShape.square,
          color: _selectedStyle == 'brand'
              ? AppColors.primary
              : qrColor,
        ),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: _selectedStyle == 'rounded'
              ? QrDataModuleShape.circle
              : QrDataModuleShape.square,
          color: _selectedStyle == 'brand'
              ? AppColors.primary
              : qrColor,
        ),
        gapless: true,
      ),
    );
  }

  // ── URL Card ──────────────────────────────────────────────────────────────

  Widget _buildUrlCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Icon(PhosphorIcons.link(PhosphorIconsStyle.duotone), color: AppColors.primary),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              _menuUrl,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grey500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TactileWrapper(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Enlace copiado al portapapeles'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(
                PhosphorIcons.copy(PhosphorIconsStyle.duotone),
                size: 18,
                color: AppColors.grey600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }

  // ── Style Selector ────────────────────────────────────────────────────────

  Widget _buildStyleSelector(ThemeData theme) {
    final styles = [
      _QrStyle('modern', 'Moderno', PhosphorIcons.square(PhosphorIconsStyle.duotone)),
      _QrStyle('rounded', 'Redondeado', PhosphorIcons.circle(PhosphorIconsStyle.duotone)),
      _QrStyle('brand', 'Marca', PhosphorIcons.palette(PhosphorIconsStyle.duotone)),
      _QrStyle('dark', 'Oscuro', PhosphorIcons.moon(PhosphorIconsStyle.duotone)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estilo del QR',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey800,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Row(
          children: styles.map((style) {
            final isActive = _selectedStyle == style.id;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TactileWrapper(
                  onTap: () => setState(() => _selectedStyle = style.id),
                  child: AnimatedContainer(
                    duration: AppTheme.durationFast,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: isActive ? AppColors.primary : AppColors.grey200,
                      ),
                      boxShadow: isActive ? AppShadows.card : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          style.icon,
                          size: 20,
                          color: isActive ? AppColors.white : AppColors.grey500,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          style.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isActive ? AppColors.white : AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 300.ms);
  }

  // ── Instrucciones ─────────────────────────────────────────────────────────

  Widget _buildInstructions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.lightbulb(PhosphorIconsStyle.duotone),
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Cómo usar el QR',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _buildStepItem(
            '1',
            'Diseña tu carta digital desde el editor de diseño',
            theme,
          ),
          _buildStepItem('2', 'Publica la carta cuando esté lista', theme),
          _buildStepItem('3', 'Imprime el QR y colócalo en las mesas', theme),
          _buildStepItem(
            '4',
            'Los clientes escanean y ven tu carta animada',
            theme,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 300.ms);
  }

  Widget _buildStepItem(String step, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grey500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrStyle {
  final String id;
  final String label;
  final IconData icon;

  const _QrStyle(this.id, this.label, this.icon);
}
