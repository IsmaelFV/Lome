import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

/// Shell principal del marketplace para clientes.
class MarketplaceShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MarketplaceShell({super.key, required this.navigationShell});

  @override
  State<MarketplaceShell> createState() => _MarketplaceShellState();
}

class _MarketplaceShellState extends State<MarketplaceShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late final Animation<double> _scaleAnim;
  int _prevIndex = 0;
  bool _goingRight = true;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..value = 1.0;
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _scaleAnim = Tween<double>(
      begin: 0.94,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MarketplaceShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIndex = widget.navigationShell.currentIndex;
    if (newIndex != _prevIndex) {
      _goingRight = newIndex > _prevIndex;
      _prevIndex = newIndex;
      _slideAnim = Tween<Offset>(
        begin: Offset(_goingRight ? 0.08 : -0.08, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
      _animCtrl.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: widget.navigationShell,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          boxShadow: AppShadows.navigation,
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: widget.navigationShell.currentIndex,
            animationDuration: AppTheme.durationMedium,
            onDestinationSelected: (index) {
              widget.navigationShell.goBranch(
                index,
                initialLocation: index == widget.navigationShell.currentIndex,
              );
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            indicatorColor: AppColors.primarySoft,
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            height: 64,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(
                  PhosphorIcons.house(),
                  size: 22,
                  color: AppColors.grey400,
                ),
                selectedIcon: Icon(
                  PhosphorIcons.house(PhosphorIconsStyle.fill),
                  size: 22,
                  color: AppColors.primary,
                ),
                label: context.l10n.home,
              ),
              NavigationDestination(
                icon: Icon(
                  PhosphorIcons.magnifyingGlass(),
                  size: 22,
                  color: AppColors.grey400,
                ),
                selectedIcon: Icon(
                  PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.fill),
                  size: 22,
                  color: AppColors.primary,
                ),
                label: context.l10n.search,
              ),
              NavigationDestination(
                icon: Icon(
                  PhosphorIcons.shoppingBag(),
                  size: 22,
                  color: AppColors.grey400,
                ),
                selectedIcon: Icon(
                  PhosphorIcons.shoppingBag(PhosphorIconsStyle.fill),
                  size: 22,
                  color: AppColors.primary,
                ),
                label: context.l10n.cart,
              ),
              NavigationDestination(
                icon: Icon(
                  PhosphorIcons.userCircle(),
                  size: 22,
                  color: AppColors.grey400,
                ),
                selectedIcon: Icon(
                  PhosphorIcons.userCircle(PhosphorIconsStyle.fill),
                  size: 22,
                  color: AppColors.primary,
                ),
                label: context.l10n.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
