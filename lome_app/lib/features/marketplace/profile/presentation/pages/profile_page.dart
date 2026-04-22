import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';

/// Pagina de perfil del cliente en el marketplace.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(
        title: context.l10n.marketplaceProfileTitle,
        showBack: false,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          // — Avatar hero card —
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXl),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withValues(alpha: 0.2),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.5),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      user?.fullName.isNotEmpty == true
                          ? user!.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  user?.fullName ?? context.l10n.marketplaceProfileUser,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

          const SizedBox(height: AppTheme.spacingLg),

          // — Menu section —
          Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  children: [
                    _ProfileMenuItem(
                      icon: PhosphorIcons.receipt(PhosphorIconsStyle.duotone),
                      iconColor: AppColors.primary,
                      label: context.l10n.marketplaceCustomerOrdersTitle,
                      onTap: () => context.push(RoutePaths.customerOrders),
                      isFirst: true,
                    ),
                    _buildDivider(),
                    _ProfileMenuItem(
                      icon: PhosphorIcons.heart(PhosphorIconsStyle.duotone),
                      iconColor: AppColors.error,
                      label: context.l10n.favorites,
                      onTap: () => context.push(RoutePaths.customerFavorites),
                    ),
                    _buildDivider(),
                    _ProfileMenuItem(
                      icon: PhosphorIcons.mapPin(PhosphorIconsStyle.duotone),
                      iconColor: AppColors.accent,
                      label: context.l10n.marketplaceProfileAddresses,
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _ProfileMenuItem(
                      icon: PhosphorIcons.gear(PhosphorIconsStyle.duotone),
                      iconColor: AppColors.grey500,
                      label: context.l10n.settings,
                      onTap: () {},
                      isLast: true,
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideY(begin: 0.05, end: 0),

          const SizedBox(height: AppTheme.spacingLg),

          // — Sign out —
          TactileWrapper(
                onTap: () async {
                  await ref.read(authActionsProvider.notifier).signOut();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingSm + 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.signOut(),
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Text(
                        context.l10n.marketplaceProfileSignOut,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.05, end: 0),

          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      child: Divider(height: 1, color: AppColors.grey100),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _ProfileMenuItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return TactileWrapper(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppTheme.spacingMd,
          right: AppTheme.spacingSm,
          top: isFirst ? AppTheme.spacingSm : AppTheme.spacingXs,
          bottom: isLast ? AppTheme.spacingSm : AppTheme.spacingXs,
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
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(
              PhosphorIcons.caretRight(),
              size: 18,
              color: AppColors.grey400,
            ),
          ],
        ),
      ),
    );
  }
}
