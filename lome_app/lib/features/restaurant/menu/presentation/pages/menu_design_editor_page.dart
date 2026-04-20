import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../core/widgets/lome_loading.dart';
import '../../domain/entities/canvas_element.dart';
import '../../domain/entities/menu_item_entity.dart';
import '../providers/canvas_provider.dart';
import '../providers/menu_provider.dart';
import '../widgets/design_canvas.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/property_panel.dart';
import '../widgets/template_gallery.dart';
import '../../../../restaurant/settings/presentation/providers/restaurant_settings_provider.dart';

// ---------------------------------------------------------------------------
// MenuDesignEditorPage – Canva-like visual menu card editor
// ---------------------------------------------------------------------------

class MenuDesignEditorPage extends ConsumerStatefulWidget {
  const MenuDesignEditorPage({super.key});

  @override
  ConsumerState<MenuDesignEditorPage> createState() =>
      _MenuDesignEditorPageState();
}

class _MenuDesignEditorPageState extends ConsumerState<MenuDesignEditorPage> {
  bool _initialized = false;
  bool _saving = false;
  bool _showTemplateGallery = false;
  String? _designId;

  @override
  Widget build(BuildContext context) {
    final asyncDesign = ref.watch(menuDesignProvider);
    final asyncCategories = ref.watch(menuCategoriesProvider);
    final asyncDishes = ref.watch(menuDishesProvider);

    return asyncDesign.when(
      loading: () => const Scaffold(body: LomeLoading()),
      error: (e, _) => Scaffold(
        appBar: const LomeAppBar(title: 'Editor de carta', useGradient: true),
        body: Center(child: Text('Error: $e')),
      ),
      data: (design) {
        if (design == null) {
          return const Scaffold(
            appBar: LomeAppBar(title: 'Editor de carta', useGradient: true),
            body: Center(child: Text('No se pudo cargar el diseño')),
          );
        }

        // Load canvas state from design on first build
        if (!_initialized) {
          _designId = design.id;
          final canvasData =
              design.customStyles?['canvas'] as Map<String, dynamic>?;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (canvasData != null &&
                (canvasData['canvasElements'] as List?)?.isNotEmpty == true) {
              ref.read(canvasProvider.notifier).loadFromJson(canvasData);
            } else {
              setState(() => _showTemplateGallery = true);
            }
          });
          _initialized = true;
        }

        final categories =
            asyncCategories.valueOrNull ?? <CategoryEntity>[];
        final dishes = asyncDishes.valueOrNull ?? <MenuItemEntity>[];

        final restaurantName = ref
                .watch(restaurantSettingsProvider)
                .data
                ?.name ??
            'Mi Restaurante';

        // Show template gallery as full screen when no canvas data
        if (_showTemplateGallery) {
          return Scaffold(
            appBar: const LomeAppBar(
              title: 'Editor de carta',
              useGradient: true,
            ),
            body: TemplateGallery(
              categories: categories,
              dishes: dishes,
              restaurantName: restaurantName,
              isFullScreen: true,
              onTemplateApplied: () =>
                  setState(() => _showTemplateGallery = false),
            ).animate().fadeIn(duration: 300.ms),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => setState(() => _showTemplateGallery = false),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: Icon(PhosphorIcons.pencilSimple()),
              label: const Text('Empezar en blanco'),
            ),
          );
        }

        return _buildEditor(context, categories, dishes, restaurantName);
      },
    );
  }

  Widget _buildEditor(
    BuildContext context,
    List<CategoryEntity> categories,
    List<MenuItemEntity> dishes,
    String restaurantName,
  ) {
    final cs = ref.watch(canvasProvider);
    final selectedElement = cs.selectedElement;
    final notifier = ref.read(canvasProvider.notifier);

    return Scaffold(
      appBar: LomeAppBar(
        title: 'Editor de carta',
        useGradient: true,
        actions: [
          // Grid toggle
          IconButton(
            icon: Icon(
              cs.showGrid
                  ? PhosphorIcons.gridFour(PhosphorIconsStyle.fill)
                  : PhosphorIcons.gridFour(),
              color: Colors.white,
            ),
            tooltip: 'Cuadrícula',
            onPressed: notifier.toggleGrid,
          ),
          // Undo
          IconButton(
            icon: Icon(PhosphorIcons.arrowCounterClockwise(),
                color: notifier.canUndo
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.4)),
            tooltip: 'Deshacer',
            onPressed: notifier.canUndo ? notifier.undo : null,
          ),
          // Redo
          IconButton(
            icon: Icon(PhosphorIcons.arrowClockwise(),
                color: notifier.canRedo
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.4)),
            tooltip: 'Rehacer',
            onPressed: notifier.canRedo ? notifier.redo : null,
          ),
          // Save
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(PhosphorIcons.floppyDisk(),
                    color: cs.hasUnsavedChanges
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4)),
            tooltip: 'Guardar',
            onPressed:
                cs.hasUnsavedChanges && !_saving ? () => _save() : null,
          ),
          // Export PDF
          PopupMenuButton<String>(
            icon: Icon(PhosphorIcons.dotsThreeVertical(), color: Colors.white),
            onSelected: (v) {
              switch (v) {
                case 'pdf':
                  _exportPdf(categories, dishes);
                case 'template':
                  _openTemplates();
                case 'background':
                  _showBackgroundPicker();
                case 'clear':
                  _confirmClear();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(PhosphorIcons.filePdf(), size: 20),
                    const SizedBox(width: 8),
                    const Text('Exportar PDF'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'template',
                child: Row(
                  children: [
                    Icon(PhosphorIcons.layout(), size: 20),
                    const SizedBox(width: 8),
                    const Text('Cambiar plantilla'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'background',
                child: Row(
                  children: [
                    Icon(PhosphorIcons.palette(), size: 20),
                    const SizedBox(width: 8),
                    const Text('Color de fondo'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(PhosphorIcons.trash(), size: 20, color: AppColors.error),
                    const SizedBox(width: 8),
                    const Text('Limpiar todo',
                        style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Canvas area
          Expanded(
            child: DesignCanvas(
              categories: categories,
              dishes: dishes,
            ),
          ),

          // Property panel (visible when element is selected)
          if (selectedElement != null)
            PropertyPanel(
              key: ValueKey(selectedElement.id),
              element: selectedElement,
              categories: categories,
            ).animate().slideY(begin: 1, duration: 200.ms, curve: Curves.easeOut),

          // Bottom toolbar
          EditorToolbar(
            categories: categories,
            onOpenTemplates: _openTemplates,
          ),
        ],
      ),
    );
  }

  // ---------- Actions -------------------------------------------------------

  void _openTemplates() {
    final categories =
        ref.read(menuCategoriesProvider).valueOrNull ?? <CategoryEntity>[];
    final dishes =
        ref.read(menuDishesProvider).valueOrNull ?? <MenuItemEntity>[];
    final restaurantName =
        ref.read(restaurantSettingsProvider).data?.name ?? 'Mi Restaurante';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          child: TemplateGallery(
            categories: categories,
            dishes: dishes,
            restaurantName: restaurantName,
          ),
        ),
      ),
    );
    setState(() => _showTemplateGallery = false);
  }

  Future<void> _save() async {
    if (_designId == null) return;
    setState(() => _saving = true);

    try {
      final canvasJson = ref.read(canvasProvider.notifier).toJson();
      await ref.read(menuDesignCrudProvider.notifier).updateDesign(
        _designId!,
        {'custom_styles': {'canvas': canvasJson}},
      );
      ref.read(canvasProvider.notifier).markSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Text('Diseño guardado'),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _exportPdf(
    List<CategoryEntity> categories,
    List<MenuItemEntity> dishes,
  ) async {
    final cs = ref.read(canvasProvider);
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) {
          return pw.Stack(
            children: [
              // Background
              pw.Positioned.fill(
                child: pw.Container(
                  color: _pdfColor(cs.backgroundColor),
                ),
              ),
              // Elements
              for (final el in cs.sortedElements)
                pw.Positioned(
                  left: el.x,
                  top: el.y,
                  child: _buildPdfElement(el, categories, dishes),
                ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => doc.save(),
      name: 'menu_carta',
    );
  }

  pw.Widget _buildPdfElement(
    CanvasElement el,
    List<CategoryEntity> categories,
    List<MenuItemEntity> dishes,
  ) {
    switch (el.type) {
      case 'text':
        return pw.SizedBox(
          width: el.width,
          height: el.height,
          child: pw.Text(
            el.text,
            textAlign: _pdfAlign(el.textAlign),
            style: pw.TextStyle(
              fontSize: el.fontSize,
              color: _pdfColor(el.color),
              fontWeight: el.fontWeight == 'bold'
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
            ),
          ),
        );

      case 'menuBlock':
        final cat = categories.where((c) => c.id == el.categoryId).firstOrNull;
        final catDishes = dishes
            .where((d) => d.categoryId == el.categoryId && d.isAvailable)
            .toList();
        return pw.SizedBox(
          width: el.width,
          height: el.height,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                cat?.name.toUpperCase() ?? '',
                style: pw.TextStyle(
                  fontSize: el.titleFontSize,
                  fontWeight: pw.FontWeight.bold,
                  color: _pdfColor(el.titleColor),
                ),
              ),
              pw.SizedBox(height: 4),
              for (final dish in catDishes)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          dish.name,
                          style: pw.TextStyle(
                            fontSize: el.itemFontSize,
                            color: _pdfColor(el.itemColor),
                          ),
                        ),
                      ),
                      if (el.showPrices)
                        pw.Text(
                          '${dish.price.toStringAsFixed(2)} €',
                          style: pw.TextStyle(
                            fontSize: el.itemFontSize,
                            fontWeight: pw.FontWeight.bold,
                            color: _pdfColor(el.priceColor),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );

      case 'shape':
        final fill = _pdfColor(el.fillColor);
        return pw.Container(
          width: el.width,
          height: el.height,
          decoration: pw.BoxDecoration(
            color: fill,
            border: el.strokeWidth > 0
                ? pw.Border.all(
                    color: _pdfColor(el.strokeColor),
                    width: el.strokeWidth,
                  )
                : null,
            borderRadius: el.shapeType == 'circle'
                ? null
                : pw.BorderRadius.circular(el.borderRadius),
            shape: el.shapeType == 'circle'
                ? pw.BoxShape.circle
                : pw.BoxShape.rectangle,
          ),
        );

      case 'divider':
        return pw.Container(
          width: el.width,
          height: el.thickness.clamp(1, 20),
          color: _pdfColor(el.dividerColor),
        );

      default:
        return pw.SizedBox(width: el.width, height: el.height);
    }
  }

  PdfColor _pdfColor(String hex) {
    final h = hex.replaceFirst('#', '');
    if (h == 'transparent' || hex == 'transparent') {
      return const PdfColor(0, 0, 0, 0);
    }
    if (h.length == 6) {
      final v = int.parse(h, radix: 16);
      return PdfColor.fromInt(0xFF000000 | v);
    }
    return PdfColors.black;
  }

  pw.TextAlign _pdfAlign(String a) => switch (a) {
    'center' => pw.TextAlign.center,
    'right' => pw.TextAlign.right,
    _ => pw.TextAlign.left,
  };

  void _showBackgroundPicker() {
    const colors = [
      '#FFFFFF', '#FFF8F0', '#F5E6D3', '#FAFAFA', '#F0F0F0',
      '#1A1A2E', '#2D3436', '#0D1B2A', '#1B1B1B', '#F5F5DC',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Color de fondo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colors.map((c) {
                final selected =
                    ref.read(canvasProvider).backgroundColor == c;
                return GestureDetector(
                  onTap: () {
                    ref.read(canvasProvider.notifier).setBackground(c);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _widgetHexToColor(c),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.grey300,
                        width: selected ? 2.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.spacingMd),
          ],
        ),
      ),
    );
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Limpiar todo'),
        content: const Text(
            '¿Estás seguro? Se eliminarán todos los elementos del canvas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(canvasProvider.notifier).clearCanvas();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  Color _widgetHexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    if (h == 'transparent' || hex == 'transparent') return Colors.transparent;
    if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    if (h.length == 8) return Color(int.parse(h, radix: 16));
    return Colors.white;
  }
}
