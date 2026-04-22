import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import 'notification_settings_page.dart';

/// Pagina de configuracion del restaurante.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(title: context.l10n.settingsTitle),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          _SettingsSection(
            title: context.l10n.settingsSectionRestaurant,
            delay: 0,
            items: [
              _SettingsItem(
                icon: PhosphorIcons.storefront(PhosphorIconsStyle.duotone),
                iconColor: AppColors.primary,
                title: context.l10n.settingsRestaurantData,
                subtitle: context.l10n.settingsRestaurantDataSubtitle,
                onTap: () => context.push(RoutePaths.restaurantSettings),
              ),
              _SettingsItem(
                icon: PhosphorIcons.clock(PhosphorIconsStyle.duotone),
                iconColor: AppColors.info,
                title: context.l10n.settingsHours,
                subtitle: context.l10n.settingsHoursSubtitle,
                onTap: () => context.push(RoutePaths.restaurantHours),
              ),
              _SettingsItem(
                icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.duotone),
                iconColor: AppColors.success,
                title: context.l10n.settingsCustomRoles,
                subtitle: context.l10n.settingsCustomRolesSubtitle,
                onTap: () => context.push(RoutePaths.customRoles),
              ),
              _SettingsItem(
                icon: PhosphorIcons.clockCounterClockwise(
                  PhosphorIconsStyle.duotone,
                ),
                iconColor: AppColors.warning,
                title: context.l10n.settingsActivityLogs,
                subtitle: context.l10n.settingsActivityLogsSubtitle,
                onTap: () => context.push(RoutePaths.activityLogs),
              ),
              _SettingsItem(
                icon: PhosphorIcons.palette(PhosphorIconsStyle.duotone),
                iconColor: AppColors.accent,
                title: context.l10n.settingsAppearance,
                subtitle: context.l10n.settingsAppearanceSubtitle,
                onTap: () {},
              ),
              _SettingsItem(
                icon: PhosphorIcons.storefront(PhosphorIconsStyle.duotone),
                iconColor: AppColors.accentDark,
                title: context.l10n.settingsMarketplace,
                subtitle: context.l10n.settingsMarketplaceSubtitle,
                onTap: () {},
                showDivider: false,
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingLg),

          _SettingsSection(
            title: context.l10n.settingsSectionSystem,
            delay: 100,
            items: [
              _SettingsItem(
                icon: PhosphorIcons.bell(PhosphorIconsStyle.duotone),
                iconColor: AppColors.info,
                title: context.l10n.notifications,
                subtitle: context.l10n.settingsNotificationsSubtitle,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsPage(),
                  ),
                ),
              ),
              _SettingsItem(
                icon: PhosphorIcons.printer(PhosphorIconsStyle.duotone),
                iconColor: AppColors.grey500,
                title: context.l10n.settingsPrinting,
                subtitle: context.l10n.settingsPrintingSubtitle,
                onTap: () {},
              ),
              _SettingsItem(
                icon: PhosphorIcons.creditCard(PhosphorIconsStyle.duotone),
                iconColor: AppColors.success,
                title: context.l10n.settingsPayments,
                subtitle: context.l10n.settingsPaymentsSubtitle,
                onTap: () {},
                showDivider: false,
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingLg),

          _SettingsSection(
            title: context.l10n.settingsSectionAccount,
            delay: 200,
            items: [
              _SettingsItem(
                icon: PhosphorIcons.user(PhosphorIconsStyle.duotone),
                iconColor: AppColors.primary,
                title: context.l10n.settingsMyProfile,
                subtitle: context.l10n.settingsMyProfileSubtitle,
                onTap: () => context.push(RoutePaths.editProfile),
              ),
              _SettingsItem(
                icon: PhosphorIcons.lock(PhosphorIconsStyle.duotone),
                iconColor: AppColors.warning,
                title: context.l10n.settingsSecurity,
                subtitle: context.l10n.settingsSecuritySubtitle,
                onTap: () {},
              ),
              _SettingsItem(
                icon: PhosphorIcons.signOut(PhosphorIconsStyle.duotone),
                iconColor: AppColors.error,
                title: context.l10n.settingsSignOut,
                subtitle: context.l10n.settingsSignOutSubtitle,
                isDestructive: true,
                onTap: () async {
                  await ref.read(authActionsProvider.notifier).signOut();
                },
                showDivider: false,
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingXl),

          Center(
            child: Column(
              children: [
                Text(
                  context.l10n.settingsAppVersion,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.settingsTagline,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey300,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 300.ms),

          const SizedBox(height: AppTheme.spacingLg),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;
  final int delay;

  const _SettingsSection({
    required this.title,
    required this.items,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppTheme.spacingXs,
                bottom: AppTheme.spacingSm,
              ),
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey400,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppShadows.card,
              ),
              child: Column(children: items),
            ),
          ],
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: delay),
          duration: AppTheme.durationMedium,
        )
        .slideY(
          begin: 0.03,
          end: 0,
          delay: Duration(milliseconds: delay),
          curve: AppTheme.curveSlideIn,
        );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool showDivider;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor = AppColors.grey600,
    this.isDestructive = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : iconColor;

    return Column(
      children: [
        TactileWrapper(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: 14,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withAlpha(isDestructive ? 20 : 25),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDestructive
                              ? AppColors.error
                              : AppColors.grey800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  PhosphorIcons.caretRight(),
                  size: 18,
                  color: AppColors.grey300,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            child: Divider(height: 1, color: AppColors.grey100),
          ),
      ],
    );
  }
}
