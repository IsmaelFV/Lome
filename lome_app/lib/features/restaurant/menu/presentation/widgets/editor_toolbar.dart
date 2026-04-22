import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              _ToolButton(
                icon: PhosphorIcons.layout(PhosphorIconsStyle.duotone),
                label: 'Plantilla',
                accent: const Color(0xFF7C3AED),
                onTap: onOpenTemplates,
              ),
              _divider(),
              _ToolButton(
                icon: PhosphorIcons.textT(PhosphorIconsStyle.duotone),
                label: 'Texto',
                accent: const Color(0xFF2563EB),
                onTap: () => _addText(ref),
              ),
              _ToolButton(
                icon: PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
                label: 'Menú',
                accent: const Color(0xFF059669),
                onTap: () => _addMenuBlock(context, ref),
              ),
              _ToolButton(
                icon: PhosphorIcons.image(PhosphorIconsStyle.duotone),
                label: 'Imagen',
                accent: const Color(0xFFD97706),
                onTap: () => _addImage(context, ref),
              ),
              _divider(),
              _ToolButton(
                icon: PhosphorIcons.shapes(PhosphorIconsStyle.duotone),
                label: 'Forma',
                accent: const Color(0xFFDB2777),
                onTap: () => _showShapeSheet(context, ref),
              ),
              _ToolButton(
                icon: PhosphorIcons.lineSegment(PhosphorIconsStyle.duotone),
                label: 'Línea',
                accent: const Color(0xFF0891B2),
                onTap: () => _addDivider(ref),
              ),
              _divider(),
              _ToolButton(
                icon: PhosphorIcons.slideshow(PhosphorIconsStyle.duotone),
                label: 'Destacados',
                accent: const Color(0xFFEA580C),
                onTap: () => _addCarousel(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.white.withValues(alpha: 0.12),
    );
  }

  void _addText(WidgetRef ref) {
    ref
        .read(canvasProvider.notifier)
        .addElement(
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (_) => _CategoryPickerSheet(
        categories: categories,
        onPick: (catId) {
          ref
              .read(canvasProvider.notifier)
              .addElement(
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
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
                  icon: Icon(
                    PhosphorIcons.rectangle(PhosphorIconsStyle.duotone),
                  ),
                  onTap: () {
                    ref
                        .read(canvasProvider.notifier)
                        .addElement(
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
                    ref
                        .read(canvasProvider.notifier)
                        .addElement(
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
                  icon: Icon(
                    PhosphorIcons.squareHalf(PhosphorIconsStyle.duotone),
                  ),
                  onTap: () {
                    ref
                        .read(canvasProvider.notifier)
                        .addElement(
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
    ref
        .read(canvasProvider.notifier)
        .addElement(
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

  void _addImage(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (ctx) => _ImagePickerSheet(
        onImagePicked: (path) {
          ref
              .read(canvasProvider.notifier)
              .addElement(
                CanvasElement.image(
                  x: kCanvasWidth / 2 - 100,
                  y: kCanvasHeight / 2 - 75,
                  width: 200,
                  height: 150,
                  imageUrl: path,
                  zIndex: 100,
                ),
              );
        },
      ),
    );
  }

  void _addCarousel(BuildContext context, WidgetRef ref) {
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay categorías en tu menú')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (_) => _CategoryPickerSheet(
        categories: categories,
        title: 'Destacados: selecciona categoría',
        onPick: (catId) {
          ref
              .read(canvasProvider.notifier)
              .addElement(
                CanvasElement.carousel(
                  categoryId: catId,
                  x: 50,
                  y: kCanvasHeight / 2 - 75,
                  width: kCanvasWidth - 100,
                  height: 150,
                  zIndex: 100,
                ),
              );
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: accent.withValues(alpha: 0.2),
          highlightColor: accent.withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: accent),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
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
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.spacingMd,
            horizontal: AppTheme.spacingSm,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.08),
                AppColors.primary.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              IconTheme(
                data: IconThemeData(size: 28, color: AppColors.primary),
                child: icon,
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
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
  final String title;

  const _CategoryPickerSheet({
    required this.categories,
    required this.onPick,
    this.title = 'Selecciona categoría',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          ...categories.map(
            (c) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                PhosphorIcons.tag(PhosphorIconsStyle.duotone),
                color: AppColors.primary,
              ),
              title: Text(c.name),
              subtitle: c.description != null ? Text(c.description!) : null,
              onTap: () => onPick(c.id),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Image picker sheet – gallery / camera / URL
// ---------------------------------------------------------------------------

class _ImagePickerSheet extends StatefulWidget {
  final ValueChanged<String> onImagePicked;

  const _ImagePickerSheet({required this.onImagePicked});

  @override
  State<_ImagePickerSheet> createState() => _ImagePickerSheetState();
}

class _ImagePickerSheetState extends State<_ImagePickerSheet> {
  final _picker = ImagePicker();
  final _urlCtrl = TextEditingController();
  bool _showUrl = false;
  bool _loading = false;

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _loading = true);
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (file != null && mounted) {
        widget.onImagePicked(file.path);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo acceder: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingLg,
        right: AppTheme.spacingLg,
        top: AppTheme.spacingLg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  PhosphorIcons.image(PhosphorIconsStyle.duotone),
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              const Text(
                'Añadir imagen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),

          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingLg),
                child: CircularProgressIndicator(),
              ),
            )
          else if (!_showUrl) ...[
            // Option tiles
            _OptionTile(
              icon: PhosphorIcons.images(PhosphorIconsStyle.duotone),
              title: 'Galería de fotos',
              subtitle: 'Elige desde tu álbum',
              color: const Color(0xFF1565C0),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _OptionTile(
              icon: PhosphorIcons.camera(PhosphorIconsStyle.duotone),
              title: 'Cámara',
              subtitle: 'Haz una foto ahora',
              color: const Color(0xFF2E7D32),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _OptionTile(
              icon: PhosphorIcons.link(PhosphorIconsStyle.duotone),
              title: 'URL de internet',
              subtitle: 'Pega un enlace de imagen',
              color: AppColors.primary,
              onTap: () => setState(() => _showUrl = true),
            ),
          ] else ...[
            // URL input
            Row(
              children: [
                IconButton(
                  icon: Icon(PhosphorIcons.arrowLeft()),
                  onPressed: () => setState(() => _showUrl = false),
                ),
                const Text(
                  'URL de imagen',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _urlCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'https://...',
                isDense: true,
                border: const OutlineInputBorder(),
                prefixIcon: Icon(PhosphorIcons.link(), size: 18),
                suffixIcon: IconButton(
                  icon: Icon(PhosphorIcons.x(), size: 16),
                  onPressed: () => _urlCtrl.clear(),
                ),
              ),
              keyboardType: TextInputType.url,
              onSubmitted: (_) => _confirmUrl(),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _confirmUrl,
                icon: Icon(PhosphorIcons.plus()),
                label: const Text('Añadir imagen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingMd,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingSm),
        ],
      ),
    );
  }

  void _confirmUrl() {
    final url = _urlCtrl.text.trim();
    if (url.isNotEmpty) {
      widget.onImagePicked(url);
      Navigator.pop(context);
    }
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingMd,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(PhosphorIcons.caretRight(), size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
