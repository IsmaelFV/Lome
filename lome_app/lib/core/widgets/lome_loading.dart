import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Indicador de carga principal de LOME.
///
/// Usa un anillo verde con pulso suave para indicar carga.
class LomeLoading extends StatelessWidget {
  final double size;
  final Color? color;

  const LomeLoading({super.key, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child:
          SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color ?? AppColors.primary,
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(
                begin: 0.95,
                end: 1.05,
                duration: 800.ms,
                curve: Curves.easeInOut,
              )
              .then()
              .scaleXY(
                begin: 1.05,
                end: 0.95,
                duration: 800.ms,
                curve: Curves.easeInOut,
              ),
    );
  }

  /// Pantalla completa de carga con logo LOME y mensaje.
  static Widget fullScreen({String? message}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador con branding
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Center(child: LomeLoading(size: 36)),
          ),
          if (message != null) ...[
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.grey500,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          ],
        ],
      ),
    );
  }
}

/// Skeleton loading para listas y cards.
///
/// Usa shimmer con los colores del tema (claro/oscuro).
class LomeSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const LomeSkeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.grey800 : AppColors.grey200,
      highlightColor: isDark ? AppColors.grey700 : AppColors.grey50,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius:
              borderRadius ?? BorderRadius.circular(AppTheme.radiusSm),
        ),
      ),
    );
  }

  /// Skeleton para un item de lista (avatar + 2 líneas).
  static Widget listItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          const LomeSkeleton(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.all(Radius.circular(AppTheme.radiusMd)),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LomeSkeleton(
                  height: 14,
                  width: 160,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 10),
                LomeSkeleton(
                  height: 12,
                  width: 100,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Skeleton para una card completa.
  static Widget card() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: LomeSkeleton(
        height: 120,
        borderRadius: BorderRadius.all(Radius.circular(AppTheme.radiusMd)),
      ),
    );
  }

  /// Skeleton para una grilla de KPIs (2×2).
  static Widget kpiGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppTheme.spacingSm,
      crossAxisSpacing: AppTheme.spacingSm,
      childAspectRatio: 1.6,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: List.generate(
        4,
        (_) => const LomeSkeleton(
          height: 100,
          borderRadius: BorderRadius.all(Radius.circular(AppTheme.radiusMd)),
        ),
      ),
    );
  }

  /// Skeleton para una sección con título + 3 items.
  static Widget section() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LomeSkeleton(
            height: 16,
            width: 140,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          ...List.generate(3, (_) => listItem()),
        ],
      ),
    );
  }
}
