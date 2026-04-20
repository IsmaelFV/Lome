import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../shared/providers/push_notification_provider.dart';

/// Página de configuración de notificaciones push.
///
/// Permite activar/desactivar push globalmente y por categoría
/// (pedidos, reseñas, inventario, sistema).
class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPreferencesProvider);
    final notifier = ref.read(notificationPreferencesProvider.notifier);
    final service = ref.read(pushNotificationServiceProvider);
    final isAvailable = service.isAvailable;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(title: context.l10n.notifications),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
        children: [
          // ── Aviso si Firebase no está configurado ──
          if (!isAvailable)
            _InfoBanner(
              icon: PhosphorIcons.warning(PhosphorIconsStyle.duotone),
              color: AppColors.warning,
              text: context.l10n.pushNotConfigured,
            ).animate().fadeIn(duration: 300.ms),

          // ── Toggle principal ──
          _SectionCard(
            delay: 0,
            children: [
              _ToggleTile(
                icon: PhosphorIcons.bellRinging(PhosphorIconsStyle.duotone),
                iconColor: AppColors.primary,
                title: context.l10n.pushEnable,
                subtitle: context.l10n.pushEnableSubtitle,
                value: prefs.pushEnabled,
                onChanged: isAvailable
                    ? (v) => notifier.setPushEnabled(v)
                    : null,
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingSm),

          // ── Sección categorías ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingLg,
              AppTheme.spacingMd,
              AppTheme.spacingLg,
              AppTheme.spacingSm,
            ),
            child: Text(
              context.l10n.pushCategories,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.grey500,
                letterSpacing: 0.5,
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 100.ms),

          _SectionCard(
            delay: 150,
            children: [
              _ToggleTile(
                icon: PhosphorIcons.receipt(PhosphorIconsStyle.duotone),
                iconColor: AppColors.info,
                title: context.l10n.pushOrders,
                subtitle: context.l10n.pushOrdersSubtitle,
                value: prefs.orders,
                onChanged: prefs.pushEnabled && isAvailable
                    ? (v) => notifier.setOrders(v)
                    : null,
              ),
              const _Divider(),
              _ToggleTile(
                icon: PhosphorIcons.star(PhosphorIconsStyle.duotone),
                iconColor: AppColors.warning,
                title: context.l10n.pushReviews,
                subtitle: context.l10n.pushReviewsSubtitle,
                value: prefs.reviews,
                onChanged: prefs.pushEnabled && isAvailable
                    ? (v) => notifier.setReviews(v)
                    : null,
              ),
              const _Divider(),
              _ToggleTile(
                icon: PhosphorIcons.package(PhosphorIconsStyle.duotone),
                iconColor: AppColors.accent,
                title: context.l10n.pushStock,
                subtitle: context.l10n.pushStockSubtitle,
                value: prefs.stock,
                onChanged: prefs.pushEnabled && isAvailable
                    ? (v) => notifier.setStock(v)
                    : null,
              ),
              const _Divider(),
              _ToggleTile(
                icon: PhosphorIcons.gear(PhosphorIconsStyle.duotone),
                iconColor: AppColors.grey500,
                title: context.l10n.pushSystem,
                subtitle: context.l10n.pushSystemSubtitle,
                value: prefs.system,
                onChanged: prefs.pushEnabled && isAvailable
                    ? (v) => notifier.setSystem(v)
                    : null,
              ),
            ],
          ),

          // ── Nota informativa ──
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Text(
              context.l10n.pushFooterNote,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey400,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 300.ms),
        ],
      ),
    );
  }
}

// =============================================================================
// Widgets auxiliares
// =============================================================================

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  final int delay;

  const _SectionCard({required this.children, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: Duration(milliseconds: delay))
        .slideY(
          begin: 0.02,
          end: 0,
          duration: 300.ms,
          delay: Duration(milliseconds: delay),
        );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onChanged == null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: disabled ? AppColors.grey400 : AppColors.grey700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: disabled ? AppColors.grey300 : AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
            activeThumbColor: AppColors.white,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 68),
      child: Divider(height: 1, color: AppColors.grey100),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        0,
        AppTheme.spacingMd,
        AppTheme.spacingMd,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: color, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
