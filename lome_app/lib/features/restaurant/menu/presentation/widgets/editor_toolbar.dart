import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/canvas_element.dart';
import '../../domain/entities/menu_item_entity.dart';
import '../providers/canvas_provider.dart';

// ---------------------------------------------------------------------------
// EditorToolbar – bottom action bar for the canvas editor
// ---------------------------------------------------------------------------

class EditorToolbar extends ConsumerWidget {
  final List<CategoryEntity> categories;
  final VoidCallback onOpenTemplates;

  const EditorToolbar({
    super.key,
    required this.categories,
    required this.onOpenTemplates,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ToolButton(
              icon: Icon(PhosphorIcons.layout(PhosphorIconsStyle.duotone)),
              label: 'Plantilla',
              onTap: onOpenTemplates,
            ),
            _ToolButton(
              icon: Icon(PhosphorIcons.textT(PhosphorIconsStyle.duotone)),
              label: 'Texto',
              onTap: () => _addText(ref),
            ),
            _ToolButton(
              icon: Icon(PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone)),
              label: 'Menú',
              onTap: () => _addMenuBlock(context, ref),
            ),
            _ToolButton(
              icon: Icon(PhosphorIcons.shapes(PhosphorIconsStyle.duotone)),
              label: 'Forma',
              onTap: () => _showShapeSheet(context, ref),
            ),
            _ToolButton(
              icon: Icon(PhosphorIcons.lineSegment(PhosphorIconsStyle.duotone)),
              label: 'Línea',
              onTap: () => _addDivider(ref),
            ),
          ],
        ),
      ),
    );
  }

  void _addText(WidgetRef ref) {
    ref.read(canvasProvider.notifier).addElement(
      CanvasElement.text(
        x: kCanvasWidth / 2 - 100,
        y: kCanvasHeight / 2 - 20,
        width: 200,
        height: 40,
        text: 'Texto nuevo',
        fontSize: 18,
        zIndex: 100,
      ),
    );
  }

  void _addMenuBlock(BuildContext context, WidgetRef ref) {
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay categorías en tu menú')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (_) => _CategoryPickerSheet(
        categories: categories,
        onPick: (catId) {
          ref.read(canvasProvider.notifier).addElement(
            CanvasElement.menuBlock(
              categoryId: catId,
              x: 50,
              y: 200,
              width: kCanvasWidth - 100,
              height: 250,
              zIndex: 100,
            ),
          );
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showShapeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Añadir forma',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                _ShapeOption(
                  label: 'Rectángulo',
                  icon: Icon(PhosphorIcons.rectangle(PhosphorIconsStyle.duotone)),
                  onTap: () {
                    ref.read(canvasProvider.notifier).addElement(
                      CanvasElement.shape(
                        x: kCanvasWidth / 2 - 75,
                        y: kCanvasHeight / 2 - 50,
                        width: 150,
                        height: 100,
                        shapeType: 'rect',
                        fillColor: '#E8E8E8',
                        strokeColor: 'transparent',
                        strokeWidth: 0,
                        borderRadius: 8,
                        zIndex: 100,
                      ),
                    );
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: AppTheme.spacingMd),
                _ShapeOption(
                  label: 'Círculo',
                  icon: Icon(PhosphorIcons.circle(PhosphorIconsStyle.duotone)),
                  onTap: () {
                    ref.read(canvasProvider.notifier).addElement(
                      CanvasElement.shape(
                        x: kCanvasWidth / 2 - 50,
                        y: kCanvasHeight / 2 - 50,
                        width: 100,
                        height: 100,
                        shapeType: 'circle',
                        fillColor: '#E8E8E8',
                        strokeColor: 'transparent',
                        strokeWidth: 0,
                        zIndex: 100,
                      ),
                    );
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: AppTheme.spacingMd),
                _ShapeOption(
                  label: 'Marco',
                  icon: Icon(PhosphorIcons.squareHalf(PhosphorIconsStyle.duotone)),
                  onTap: () {
                    ref.read(canvasProvider.notifier).addElement(
                      CanvasElement.shape(
                        x: 30,
                        y: 30,
                        width: kCanvasWidth - 60,
                        height: kCanvasHeight - 60,
                        shapeType: 'rect',
                        fillColor: 'transparent',
                        strokeColor: '#2D3436',
                        strokeWidth: 2,
                        zIndex: 0,
                      ),
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
          ],
        ),
      ),
    );
  }

  void _addDivider(WidgetRef ref) {
    ref.read(canvasProvider.notifier).addElement(
      CanvasElement.divider(
        x: kCanvasWidth / 2 - 100,
        y: kCanvasHeight / 2,
        width: 200,
        color: '#B2BEC3',
        thickness: 1.5,
        zIndex: 100,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _ToolButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSm,
          vertical: AppTheme.spacingXs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme(
              data: const IconThemeData(size: 22, color: AppColors.grey700),
              child: icon,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.grey700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShapeOption extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  const _ShapeOption({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Column(
            children: [
              IconTheme(
                data: const IconThemeData(size: 28, color: AppColors.grey700),
                child: icon,
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPickerSheet extends StatelessWidget {
  final List<CategoryEntity> categories;
  final ValueChanged<String> onPick;

  const _CategoryPickerSheet({
    required this.categories,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona categoría',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          ...categories.map((c) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  PhosphorIcons.tag(PhosphorIconsStyle.duotone),
                  color: AppColors.primary,
                ),
                title: Text(c.name),
                subtitle:
                    c.description != null ? Text(c.description!) : null,
                onTap: () => onPick(c.id),
              )),
          const SizedBox(height: AppTheme.spacingSm),
        ],
      ),
    );
  }
}
