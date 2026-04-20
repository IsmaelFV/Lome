import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/menu_item_entity.dart';
import '../providers/canvas_provider.dart';
import 'menu_template.dart';

// ---------------------------------------------------------------------------
// TemplateGallery – full-screen or bottom-sheet grid of templates
// ---------------------------------------------------------------------------

class TemplateGallery extends ConsumerWidget {
  final List<CategoryEntity> categories;
  final List<MenuItemEntity> dishes;
  final String restaurantName;
  final bool isFullScreen;
  final VoidCallback? onTemplateApplied;

  const TemplateGallery({
    super.key,
    required this.categories,
    required this.dishes,
    required this.restaurantName,
    this.isFullScreen = false,
    this.onTemplateApplied,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = MenuTemplate.templates;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingLg,
            AppTheme.spacingLg,
            AppTheme.spacingLg,
            AppTheme.spacingSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    PhosphorIcons.layout(PhosphorIconsStyle.duotone),
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  const Expanded(
                    child: Text(
                      'Elige una plantilla base',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (!isFullScreen)
                    IconButton(
                      icon: Icon(PhosphorIcons.x()),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Se rellenará con los platos de tu menú',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Template grid
        Flexible(
          child: GridView.builder(
            shrinkWrap: !isFullScreen,
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppTheme.spacingMd,
              crossAxisSpacing: AppTheme.spacingMd,
              childAspectRatio: 0.65,
            ),
            itemCount: templates.length,
            itemBuilder: (_, i) {
              final t = templates[i];
              return _TemplateCard(
                template: t,
                onTap: () {
                  final elements = generateTemplateElements(
                    template: t,
                    categories: categories,
                    dishes: dishes,
                    restaurantName: restaurantName,
                  );
                  ref
                      .read(canvasProvider.notifier)
                      .applyTemplate(elements, t.backgroundColor);
                  if (isFullScreen) {
                    onTemplateApplied?.call();
                  } else {
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),
      ],
    );

    if (isFullScreen) {
      return Scaffold(
        body: SafeArea(child: content),
      );
    }
    return content;
  }
}

// ---------------------------------------------------------------------------
// Template card – mini preview of a template
// ---------------------------------------------------------------------------

class _TemplateCard extends StatelessWidget {
  final MenuTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = _hexToColor(template.backgroundColor);
    final primary = _hexToColor(template.primaryColor);
    final secondary = _hexToColor(template.secondaryColor);
    final accent = _hexToColor(template.accentColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.grey200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Mini canvas preview
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusMd),
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: _MiniPreview(
                  primary: primary,
                  secondary: secondary,
                  accent: accent,
                  bg: bg,
                  templateId: template.id,
                ),
              ),
            ),

            // Label
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
                vertical: AppTheme.spacingSm,
              ),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppTheme.radiusMd),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    template.description,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mini preview – abstract representation of the template layout
// ---------------------------------------------------------------------------

class _MiniPreview extends StatelessWidget {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color bg;
  final String templateId;

  const _MiniPreview({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.bg,
    required this.templateId,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          children: [
            // Title bar
            Positioned(
              left: w * 0.15,
              top: h * 0.05,
              width: w * 0.7,
              height: 3,
              child: Container(color: accent),
            ),
            // Title text mock
            Positioned(
              left: w * 0.1,
              top: h * 0.1,
              width: w * 0.8,
              height: h * 0.08,
              child: Container(
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Subtitle mock
            Positioned(
              left: w * 0.25,
              top: h * 0.2,
              width: w * 0.5,
              height: 2,
              child: Container(color: accent.withValues(alpha: 0.5)),
            ),

            // Category blocks
            Positioned(
              left: w * 0.08,
              top: h * 0.3,
              width: w * 0.35,
              height: h * 0.25,
              child: _mockCategory(primary, secondary),
            ),
            Positioned(
              left: w * 0.55,
              top: h * 0.3,
              width: w * 0.35,
              height: h * 0.25,
              child: _mockCategory(primary, secondary),
            ),
            Positioned(
              left: w * 0.08,
              top: h * 0.6,
              width: w * 0.35,
              height: h * 0.3,
              child: _mockCategory(primary, secondary),
            ),
            Positioned(
              left: w * 0.55,
              top: h * 0.6,
              width: w * 0.35,
              height: h * 0.3,
              child: _mockCategory(primary, secondary),
            ),

            // Frame for certain templates
            if (templateId == 'classica' || templateId == 'elegante' || templateId == 'rustica')
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: primary.withValues(alpha: 0.4),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(
                        templateId == 'rustica' ? 4 : 0),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _mockCategory(Color title, Color items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 3,
          decoration: BoxDecoration(
            color: title,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(height: 4),
        for (int i = 0; i < 3; i++) ...[
          Container(
            width: double.infinity,
            height: 2,
            margin: const EdgeInsets.only(bottom: 3),
            decoration: BoxDecoration(
              color: items.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hex → Color
// ---------------------------------------------------------------------------

Color _hexToColor(String hex) {
  final h = hex.replaceFirst('#', '');
  if (h == 'transparent' || hex == 'transparent') return Colors.transparent;
  if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
  if (h.length == 8) return Color(int.parse(h, radix: 16));
  return Colors.white;
}
