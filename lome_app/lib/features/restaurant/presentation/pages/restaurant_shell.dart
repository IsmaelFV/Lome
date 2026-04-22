import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

/// Shell principal de la aplicacion interna del restaurante.
///
/// Contiene la barra de navegacion inferior con las secciones principales:
/// Mesas, Pedidos, Cocina, Menu, Inventario.
/// Navegacion estilo BMW: indicador pill, crossfade suave, sombra consistente.
class RestaurantShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const RestaurantShell({super.key, required this.navigationShell});

  @override
  State<RestaurantShell> createState() => _RestaurantShellState();
}

class _RestaurantShellState extends State<RestaurantShell>
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
  void didUpdateWidget(covariant RestaurantShell oldWidget) {
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
    final currentIndex = widget.navigationShell.currentIndex;

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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF022C22)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: List.generate(5, (i) {
                final selected = currentIndex == i;
                final unselectedIcons = [
                  PhosphorIcons.gridFour(PhosphorIconsStyle.light),
                  PhosphorIcons.receipt(PhosphorIconsStyle.light),
                  PhosphorIcons.cookingPot(PhosphorIconsStyle.light),
                  PhosphorIcons.forkKnife(PhosphorIconsStyle.light),
                  PhosphorIcons.package(PhosphorIconsStyle.light),
                ];
                final selectedIcons = [
                  PhosphorIcons.gridFour(PhosphorIconsStyle.duotone),
                  PhosphorIcons.receipt(PhosphorIconsStyle.duotone),
                  PhosphorIcons.cookingPot(PhosphorIconsStyle.duotone),
                  PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
                  PhosphorIcons.package(PhosphorIconsStyle.duotone),
                ];
                final labels = [
                  context.l10n.tables,
                  context.l10n.orders,
                  context.l10n.kitchen,
                  context.l10n.menu,
                  context.l10n.inventory,
                ];

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.navigationShell.goBranch(
                      i,
                      initialLocation: i == currentIndex,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pill indicator
                        AnimatedContainer(
                          duration: AppTheme.durationFast,
                          curve: Curves.easeOutCubic,
                          height: 3,
                          width: selected ? 24 : 0,
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Icon with animated scale
                        AnimatedScale(
                          scale: selected ? 1.15 : 1.0,
                          duration: AppTheme.durationFast,
                          curve: Curves.easeOutCubic,
                          child: Icon(
                            selected ? selectedIcons[i] : unselectedIcons[i],
                            size: 24,
                            color: selected
                                ? AppColors.primaryLight
                                : AppColors.white.withValues(alpha: 0.45),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Label
                        AnimatedDefaultTextStyle(
                          duration: AppTheme.durationFast,
                          style: TextStyle(
                            fontSize: selected ? 10.5 : 10,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected
                                ? AppColors.primaryLight
                                : AppColors.white.withValues(alpha: 0.45),
                            letterSpacing: selected ? 0.3 : 0,
                          ),
                          child: Text(
                            labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
