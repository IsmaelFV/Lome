import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/canvas_element.dart';
import '../../domain/entities/menu_item_entity.dart';
import '../providers/canvas_provider.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// PropertyPanel â€“ compact 64-px action bar; controls open as bottom sheets
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class PropertyPanel extends ConsumerWidget {
  final CanvasElement element;
  final List<CategoryEntity> categories;

  const PropertyPanel({
    super.key,
    required this.element,
    required this.categories,
  });

  // â”€â”€ Type metadata â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static String _label(String type) => switch (type) {
    'text' => 'Texto',
    'menuBlock' => 'MenÃº',
    'shape' => 'Forma',
    'divider' => 'LÃ­nea',
    'image' => 'Imagen',
    'carousel' => 'Destacados',
    _ => 'Elemento',
  };

  static Color _accent(String type) => switch (type) {
    'text' => const Color(0xFF2563EB),
    'menuBlock' => const Color(0xFF059669),
    'shape' => const Color(0xFFDB2777),
    'divider' => const Color(0xFF0891B2),
    'image' => const Color(0xFFD97706),
    'carousel' => const Color(0xFFEA580C),
    _ => AppColors.primary,
  };

  static IconData _icon(String type) => switch (type) {
    'text' => PhosphorIconsDuotone.textT,
    'menuBlock' => PhosphorIconsDuotone.forkKnife,
    'shape' => PhosphorIconsDuotone.shapes,
    'divider' => PhosphorIconsDuotone.lineSegment,
    'image' => PhosphorIconsDuotone.image,
    'carousel' => PhosphorIconsDuotone.slideshow,
    _ => PhosphorIconsDuotone.squaresFour,
  };

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Always read fresh element so bar stays in sync
    final el =
        ref
            .watch(canvasProvider)
            .elements
            .where((e) => e.id == element.id)
            .firstOrNull ??
        element;

    final accent = _accent(el.type);
    final notifier = ref.read(canvasProvider.notifier);

    void update(CanvasElement Function(CanvasElement) fn) =>
        notifier.updateElement(el.id, fn);

    void openSheet(String section) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ControlSheet(
          section: section,
          elementId: el.id,
          categories: categories,
          onUpdate: update,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // â”€â”€ Type badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _TypeBadge(
              label: _label(el.type),
              icon: _icon(el.type),
              accent: accent,
            ),
            _vDivider(),

            // â”€â”€ Context-sensitive actions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            ..._typeChips(el, accent, openSheet),
            _vDivider(),

            // â”€â”€ Universal actions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _Chip(
              icon: PhosphorIcons.copySimple(),
              label: 'Duplicar',
              onTap: () => notifier.duplicateElement(el.id),
            ),
            _Chip(
              icon: PhosphorIcons.arrowUp(),
              label: 'Al frente',
              onTap: () => notifier.bringToFront(el.id),
            ),
            _Chip(
              icon: PhosphorIcons.arrowDown(),
              label: 'AtrÃ¡s',
              onTap: () => notifier.sendToBack(el.id),
            ),
            _vDivider(),
            _Chip(
              icon: PhosphorIcons.trash(),
              label: 'Borrar',
              accent: const Color(0xFFEF4444),
              onTap: () => notifier.removeElement(el.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 1,
    height: 32,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: Colors.white.withValues(alpha: 0.1),
  );

  // Type-specific action chips
  List<Widget> _typeChips(
    CanvasElement el,
    Color accent,
    void Function(String) open,
  ) {
    return switch (el.type) {
      'text' => [
        _Chip(
          icon: PhosphorIcons.arrowsOutCardinal(),
          label: 'Mover',
          accent: accent,
          onTap: () => open('transform'),
        ),
        _Chip(
          icon: PhosphorIcons.textT(),
          label: 'Editar',
          accent: accent,
          onTap: () => open('text_edit'),
        ),
        _Chip(
          icon: PhosphorIcons.palette(),
          label: 'Color',
          accent: accent,
          onTap: () => open('text_color'),
        ),
        _Chip(
          icon: PhosphorIcons.textAa(),
          label: 'Fuente',
          accent: accent,
          onTap: () => open('text_font'),
        ),
        _Chip(
          icon: PhosphorIcons.sparkle(),
          label: 'Anim.',
          accent: accent,
          onTap: () => open('animation'),
        ),
      ],
      'menuBlock' => [
        _Chip(
          icon: PhosphorIcons.arrowsOutCardinal(),
          label: 'Mover',
          accent: accent,
          onTap: () => open('transform'),
        ),
        _Chip(
          icon: PhosphorIcons.tag(),
          label: 'CategorÃ­a',
          accent: accent,
          onTap: () => open('menu_cat'),
        ),
        _Chip(
          icon: PhosphorIcons.textAa(),
          label: 'TamaÃ±os',
          accent: accent,
          onTap: () => open('menu_sizes'),
        ),
        _Chip(
          icon: PhosphorIcons.palette(),
          label: 'Colores',
          accent: accent,
          onTap: () => open('menu_colors'),
        ),
        _Chip(
          icon: PhosphorIcons.eye(),
          label: 'Mostrar',
          accent: accent,
          onTap: () => open('menu_visibility'),
        ),
      ],
      'shape' => [
        _Chip(
          icon: PhosphorIcons.arrowsOutCardinal(),
          label: 'Mover',
          accent: accent,
          onTap: () => open('transform'),
        ),
        _Chip(
          icon: PhosphorIcons.palette(),
          label: 'Colores',
          accent: accent,
          onTap: () => open('shape_colors'),
        ),
        _Chip(
          icon: PhosphorIcons.sliders(),
          label: 'Estilo',
          accent: accent,
          onTap: () => open('shape_style'),
        ),
        _Chip(
          icon: PhosphorIcons.sparkle(),
          label: 'Anim.',
          accent: accent,
          onTap: () => open('animation'),
        ),
      ],
      'divider' => [
        _Chip(
          icon: PhosphorIcons.arrowsOutCardinal(),
          label: 'Mover',
          accent: accent,
          onTap: () => open('transform'),
        ),
        _Chip(
          icon: PhosphorIcons.palette(),
          label: 'Color',
          accent: accent,
          onTap: () => open('divider_color'),
        ),
        _Chip(
          icon: PhosphorIcons.sliders(),
          label: 'Estilo',
          accent: accent,
          onTap: () => open('divider_style'),
        ),
      ],
      'image' => [
        _Chip(
          icon: PhosphorIcons.arrowsOutCardinal(),
          label: 'Mover',
          accent: accent,
          onTap: () => open('transform'),
        ),
        _Chip(
          icon: PhosphorIcons.images(),
          label: 'Imagen',
          accent: accent,
          onTap: () => open('image_pick'),
        ),
        _Chip(
          icon: PhosphorIcons.sliders(),
          label: 'Estilo',
          accent: accent,
          onTap: () => open('image_style'),
        ),
        _Chip(
          icon: PhosphorIcons.sparkle(),
          label: 'Anim.',
          accent: accent,
          onTap: () => open('animation'),
        ),
      ],
      'carousel' => [
        _Chip(
          icon: PhosphorIcons.arrowsOutCardinal(),
          label: 'Mover',
          accent: accent,
          onTap: () => open('transform'),
        ),
        _Chip(
          icon: PhosphorIcons.tag(),
          label: 'CategorÃ­a',
          accent: accent,
          onTap: () => open('carousel_cat'),
        ),
        _Chip(
          icon: PhosphorIcons.palette(),
          label: 'Colores',
          accent: accent,
          onTap: () => open('carousel_colors'),
        ),
        _Chip(
          icon: PhosphorIcons.sliders(),
          label: 'Opciones',
          accent: accent,
          onTap: () => open('carousel_opts'),
        ),
      ],
      _ => [],
    };
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// _TypeBadge
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TypeBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  const _TypeBadge({
    required this.label,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: accent),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// _Chip â€“ action button in the bar
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accent;
  final VoidCallback onTap;
  const _Chip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Colors.white.withValues(alpha: 0.55);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: color.withValues(alpha: 0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// _ControlSheet â€“ bottom sheet opened by action chips
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ControlSheet extends ConsumerStatefulWidget {
  final String section;
  final String elementId;
  final List<CategoryEntity> categories;
  final void Function(CanvasElement Function(CanvasElement)) onUpdate;

  const _ControlSheet({
    required this.section,
    required this.elementId,
    required this.categories,
    required this.onUpdate,
  });

  @override
  ConsumerState<_ControlSheet> createState() => _ControlSheetState();
}

class _ControlSheetState extends ConsumerState<_ControlSheet> {
  late TextEditingController _textCtrl;

  @override
  void initState() {
    super.initState();
    final el = _el;
    _textCtrl = TextEditingController(text: el.text);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  CanvasElement get _el => ref
      .read(canvasProvider)
      .elements
      .firstWhere((e) => e.id == widget.elementId);

  void _update(CanvasElement Function(CanvasElement) fn) => widget.onUpdate(fn);

  @override
  Widget build(BuildContext context) {
    final el = ref
        .watch(canvasProvider)
        .elements
        .firstWhere((e) => e.id == widget.elementId);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // â”€â”€ Handle + Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SheetHeader(section: widget.section),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),

          // â”€â”€ Scrollable content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: Theme(
              data: _darkTheme(),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 28,
                ),
                child: _buildContent(el),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(CanvasElement el) {
    return switch (widget.section) {
      // â”€â”€ Text â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      'text_edit' => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Contenido'),
          TextField(
            controller: _textCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            onChanged: (v) => _update((e) => e.withProp('text', v)),
            decoration: _inputDeco('Escribe aquÃ­...'),
          ),
          const SizedBox(height: 16),
          _label('TamaÃ±o'),
          _SliderRow(
            label: 'TamaÃ±o fuente',
            value: el.fontSize,
            min: 8,
            max: 72,
            onChanged: (v) =>
                _update((e) => e.withProp('fontSize', v.roundToDouble())),
          ),
          _label('Peso'),
          _StyleToggle(
            options: const ['normal', 'bold'],
            labels: const ['Normal', 'Negrita'],
            selected: el.fontWeight,
            onChanged: (v) => _update((e) => e.withProp('fontWeight', v)),
          ),
          const SizedBox(height: 12),
          _label('AlineaciÃ³n'),
          _AlignRow(
            value: el.textAlign,
            onChanged: (v) => _update((e) => e.withProp('textAlign', v)),
          ),
        ],
      ),

      'text_color' => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ColorRow(
            label: 'Color del texto',
            hex: el.color,
            onChanged: (v) => _update((e) => e.withProp('color', v)),
          ),
        ],
      ),

      'text_font' => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FontFamilyRow(
            value: el.fontFamily,
            onChanged: (v) => _update((e) => e.withProp('fontFamily', v)),
          ),
          const SizedBox(height: 12),
          _SliderRow(
            label: 'Opacidad',
            value: el.opacity,
            min: 0,
            max: 1,
            onChanged: (v) => _update((e) => e.withProp('opacity', v)),
          ),
        ],
      ),

      'transform' => _TransformSection(el: el, onUpdate: _update),

      // â”€â”€ Menu block â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      'menu_cat' => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('CategorÃ­a mostrada'),
          _CategoryDropdown(
            value: widget.categories.any((c) => c.id == el.categoryId)
                ? el.categoryId
                : null,
            categories: widget.categories,
            onChanged: (v) => _update((e) => e.withProp('categoryId', v)),
          ),
        ],
      ),

      'menu_sizes' => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SliderRow(
            label: 'TÃ­tulo',
            value: el.titleFontSize,
            min: 10,
            max: 36,
            onChanged: (v) =>
                _update((e) => e.withProp('titleFontSize', v.roundToDouble())),
          ),
          _SliderRow(
            label: 'Platos',
            value: el.itemFontSize,
            min: 8,
            max: 24,
            onChanged: (v) =>
                _update((e) => e.withProp('itemFontSize', v.roundToDouble())),
          ),
        ],
      ),

      'menu_colors' => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ColorRow(
            label: 'TÃ­tulo',
            hex: el.titleColor,
            onChanged: (v) => _update((e) => e.withProp('titleColor', v)),
          ),
          _ColorRow(
            label: 'Platos',
            hex: el.itemColor,
            onChanged: (v) => _update((e) => e.withProp('itemColor', v)),
          ),
          _ColorRow(
            label: 'Precios',
            hex: el.priceColor,
            onChanged: (v) => _update((e) => e.withProp('priceColor', v)),
          ),
        ],
      ),

      'menu_visibility' => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SwitchRow(
            label: 'Mostrar precios',
            value: el.showPrices,
            onChanged: (v) => _update((e) => e.withProp('showPrices', v)),
          ),
          _SwitchRow(
            label: 'Mostrar descripciones',
            value: el.showDescriptions,
            onChanged: (v) => _update((e) => e.withProp('showDescriptions', v)),
          ),
        ],
      ),

      // â”€â”€ Shape â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      'shape_colors' => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ColorRow(
            label: 'Relleno',
            hex: el.fillColor,
            allowTransparent: true,
            onChanged: (v) => _update((e) => e.withProp('fillColor', v)),
          ),
          _ColorRow(
            label: 'Borde',
            hex: el.strokeColor,
            allowTransparent: true,
            onChanged: (v) => _update((e) => e.withProp('strokeColor', v)),
          ),
        ],
      ),

      'shape_style' => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SliderRow(
            label: 'Grosor borde',
            value: el.strokeWidth,
            min: 0,
            max: 10,
            onChanged: (v) => _update((e) => e.withProp('strokeWidth', v)),
          ),
          if (el.shapeType == 'rect')
            _SliderRow(
              label: 'Radio esquinas',
              value: el.borderRadius,
              min: 0,
              max: 50,
              onChanged: (v) => _update((e) => e.withProp('borderRadius', v)),
            ),
          _SliderRow(
            label: 'Opacidad',
            value: el.opacity,
            min: 0,
            max: 1,
            onChanged: (v) => _update((e) => e.withProp('opacity', v)),
          ),
        ],
      ),

      // â”€â”€ Divider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      'divider_color' => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ColorRow(
            label: 'Color',
            hex: el.dividerColor,
            onChanged: (v) => _update((e) => e.withProp('color', v)),
          ),
          _SliderRow(
            label: 'Grosor',
            value: el.thickness,
            min: 0.5,
            max: 8,
            onChanged: (v) => _update((e) => e.withProp('thickness', v)),
          ),
        ],
      ),

      'divider_style' => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Estilo de lÃ­nea'),
          _StyleToggle(
            options: const ['solid', 'dashed', 'dotted'],
            labels: const ['SÃ³lido', 'Rayas', 'Puntos'],
            selected: el.dividerStyle,
            onChanged: (v) => _update((e) => e.withProp('style', v)),
          ),
        ],
      ),

      // â”€â”€ Image â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      'image_pick' => _ImagePickSection(el: el, onUpdate: _update),

      'image_style' => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SliderRow(
            label: 'Radio esquinas',
            value: el.borderRadius,
            min: 0,
            max: 50,
            onChanged: (v) => _update((e) => e.withProp('borderRadius', v)),
          ),
          _SliderRow(
            label: 'Opacidad',
            value: el.opacity,
            min: 0,
            max: 1,
            onChanged: (v) => _update((e) => e.withProp('opacity', v)),
          ),
        ],
      ),

      // â”€â”€ Carousel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      'carousel_cat' => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('CategorÃ­a destacada'),
          _CategoryDropdown(
            value: widget.categories.any((c) => c.id == el.categoryId)
                ? el.categoryId
                : null,
            categories: widget.categories,
            onChanged: (v) => _update((e) => e.withProp('categoryId', v)),
          ),
          const SizedBox(height: 16),
          _SliderRow(
            label: 'Velocidad (seg)',
            value: el.displayDuration / 1000,
            min: 1,
            max: 10,
            onChanged: (v) => _update(
              (e) => e.withProp('displayDuration', (v * 1000).round()),
            ),
          ),
        ],
      ),

      'carousel_colors' => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ColorRow(
            label: 'Fondo',
            hex: el.props['backgroundColor'] as String? ?? '#FFFFFF',
            onChanged: (v) => _update((e) => e.withProp('backgroundColor', v)),
          ),
          _ColorRow(
            label: 'Texto',
            hex: el.textColor,
            onChanged: (v) => _update((e) => e.withProp('textColor', v)),
          ),
          _ColorRow(
            label: 'Precios',
            hex: el.priceColor,
            onChanged: (v) => _update((e) => e.withProp('priceColor', v)),
          ),
        ],
      ),

      'carousel_opts' => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SwitchRow(
            label: 'Mostrar precios',
            value: el.showPrices,
            onChanged: (v) => _update((e) => e.withProp('showPrices', v)),
          ),
          _SwitchRow(
            label: 'Mostrar descripciones',
            value: el.showDescriptions,
            onChanged: (v) => _update((e) => e.withProp('showDescriptions', v)),
          ),
          _SliderRow(
            label: 'TamaÃ±o texto',
            value: el.fontSize,
            min: 10,
            max: 32,
            onChanged: (v) =>
                _update((e) => e.withProp('fontSize', v.roundToDouble())),
          ),
          _SliderRow(
            label: 'Radio esquinas',
            value: el.borderRadius,
            min: 0,
            max: 30,
            onChanged: (v) => _update((e) => e.withProp('borderRadius', v)),
          ),
        ],
      ),

      // â”€â”€ Animation (shared) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      'animation' => _AnimationSection(el: el, onUpdate: _update),

      _ => const SizedBox.shrink(),
    };
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// _SheetHeader
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SheetHeader extends StatelessWidget {
  final String section;
  const _SheetHeader({required this.section});

  static ({String title, IconData icon}) _meta(
    String section,
  ) => switch (section) {
    'text_edit' => (title: 'Editar texto', icon: PhosphorIconsDuotone.textT),
    'text_color' => (
      title: 'Color del texto',
      icon: PhosphorIconsDuotone.palette,
    ),
    'text_font' => (title: 'TipografÃ­a', icon: PhosphorIconsDuotone.textAa),
    'transform' => (title: 'PosiciÃ³n y tamaÃ±o', icon: PhosphorIconsDuotone.arrowsOutCardinal),
    'menu_cat' => (title: 'CategorÃ­a', icon: PhosphorIconsDuotone.tag),
    'menu_sizes' => (title: 'TamaÃ±os', icon: PhosphorIconsDuotone.textAa),
    'menu_colors' => (title: 'Colores', icon: PhosphorIconsDuotone.palette),
    'menu_visibility' => (
      title: 'Mostrar / ocultar',
      icon: PhosphorIconsDuotone.eye,
    ),
    'shape_colors' => (
      title: 'Colores de la forma',
      icon: PhosphorIconsDuotone.palette,
    ),
    'shape_style' => (
      title: 'Estilo de la forma',
      icon: PhosphorIconsDuotone.sliders,
    ),
    'divider_color' => (
      title: 'Color de la lÃ­nea',
      icon: PhosphorIconsDuotone.palette,
    ),
    'divider_style' => (
      title: 'Estilo de la lÃ­nea',
      icon: PhosphorIconsDuotone.lineSegment,
    ),
    'image_pick' => (title: 'Cambiar imagen', icon: PhosphorIconsDuotone.image),
    'image_style' => (
      title: 'Estilo de imagen',
      icon: PhosphorIconsDuotone.sliders,
    ),
    'carousel_cat' => (
      title: 'CategorÃ­a destacada',
      icon: PhosphorIconsDuotone.slideshow,
    ),
    'carousel_colors' => (
      title: 'Colores del carrusel',
      icon: PhosphorIconsDuotone.palette,
    ),
    'carousel_opts' => (
      title: 'Opciones del carrusel',
      icon: PhosphorIconsDuotone.sliders,
    ),
    'animation' => (title: 'AnimaciÃ³n', icon: PhosphorIconsDuotone.sparkle),
    _ => (title: 'Editar', icon: PhosphorIconsDuotone.pencilSimple),
  };

  @override
  Widget build(BuildContext context) {
    final m = _meta(section);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
      child: Row(
        children: [
          // Drag handle centered
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Icon(m.icon, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      m.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              PhosphorIcons.x(),
              color: Colors.white.withValues(alpha: 0.5),
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// _ImagePickSection â€“ gallery / camera / URL inside control sheet
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ImagePickSection extends StatelessWidget {
  final CanvasElement el;
  final void Function(CanvasElement Function(CanvasElement)) onUpdate;
  const _ImagePickSection({required this.el, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _ImageSourceButton(
                icon: PhosphorIcons.images(PhosphorIconsStyle.duotone),
                label: 'GalerÃ­a',
                color: const Color(0xFF2563EB),
                onTap: () async {
                  final f = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                    maxWidth: 1200,
                  );
                  if (f != null)
                    onUpdate((e) => e.withProp('imageUrl', f.path));
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ImageSourceButton(
                icon: PhosphorIcons.camera(PhosphorIconsStyle.duotone),
                label: 'CÃ¡mara',
                color: const Color(0xFF059669),
                onTap: () async {
                  final f = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                    maxWidth: 1200,
                  );
                  if (f != null)
                    onUpdate((e) => e.withProp('imageUrl', f.path));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _label('O usa una URL'),
        const SizedBox(height: 6),
        TextField(
          key: ValueKey(el.id),
          controller: TextEditingController(text: el.imageUrl ?? ''),
          style: const TextStyle(color: Colors.white),
          decoration: _inputDeco('https://...').copyWith(
            prefixIcon: Icon(
              PhosphorIcons.link(),
              size: 16,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          keyboardType: TextInputType.url,
          onChanged: (v) => onUpdate((e) => e.withProp('imageUrl', v)),
        ),
      ],
    );
  }
}

class _ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// _AnimationSection
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AnimationSection extends StatelessWidget {
  final CanvasElement el;
  final void Function(CanvasElement Function(CanvasElement)) onUpdate;
  const _AnimationSection({required this.el, required this.onUpdate});

  static const _animationOptions = <String, String>{
    'none': 'Ninguna',
    'fadeIn': 'Aparecer',
    'slideUp': 'Deslizar â†‘',
    'slideDown': 'Deslizar â†“',
    'slideLeft': 'Deslizar â†',
    'slideRight': 'Deslizar â†’',
    'scaleIn': 'Escalar',
    'bounce': 'Rebote',
    'flip': 'Voltear',
    'pulse': 'Pulso âˆž',
    'shake': 'Vibrar âˆž',
  };

  @override
  Widget build(BuildContext context) {
    final current = el.animation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Tipo de animaciÃ³n'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _animationOptions.entries.map((e) {
            final sel = current == e.key;
            return GestureDetector(
              onTap: () => onUpdate((el) => el.withProp('animation', e.key)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: sel
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 12,
                    color: sel
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.7),
                    fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (current != 'none') ...[
          const SizedBox(height: 16),
          _SliderRow(
            label: 'DuraciÃ³n (ms)',
            value: el.animationDuration.toDouble(),
            min: 100,
            max: 2000,
            onChanged: (v) =>
                onUpdate((e) => e.withProp('animationDuration', v.round())),
          ),
          _SliderRow(
            label: 'Retardo (ms)',
            value: el.animationDelay.toDouble(),
            min: 0,
            max: 2000,
            onChanged: (v) =>
                onUpdate((e) => e.withProp('animationDelay', v.round())),
          ),
          if (current != 'pulse' && current != 'shake')
            _SwitchRow(
              label: 'Repetir en bucle',
              value: el.animationLoop,
              onChanged: (v) => onUpdate((e) => e.withProp('animationLoop', v)),
            ),
        ],
      ],
    );
  }
}

class _TransformSection extends StatelessWidget {
  final CanvasElement el;
  final void Function(CanvasElement Function(CanvasElement)) onUpdate;

  const _TransformSection({required this.el, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    void nudge(double dx, double dy) {
      onUpdate(
        (e) => e.copyWith(
          x: (e.x + dx).clamp(-e.width / 2, kCanvasWidth - e.width / 2),
          y: (e.y + dy).clamp(-e.height / 2, kCanvasHeight - e.height / 2),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Ajuste fino'),
        const SizedBox(height: 8),
        _NudgePad(onMove: nudge),
        const SizedBox(height: 18),
        _SliderRow(
          label: 'PosiciÃ³n X',
          value: el.x,
          min: -el.width / 2,
          max: kCanvasWidth - el.width / 2,
          onChanged: (v) => onUpdate((e) => e.copyWith(x: v)),
        ),
        _SliderRow(
          label: 'PosiciÃ³n Y',
          value: el.y,
          min: -el.height / 2,
          max: kCanvasHeight - el.height / 2,
          onChanged: (v) => onUpdate((e) => e.copyWith(y: v)),
        ),
        _SliderRow(
          label: 'Ancho',
          value: el.width,
          min: 30,
          max: kCanvasWidth,
          onChanged: (v) => onUpdate((e) => e.copyWith(width: v)),
        ),
        _SliderRow(
          label: 'Alto',
          value: el.height,
          min: 20,
          max: kCanvasHeight,
          onChanged: (v) => onUpdate((e) => e.copyWith(height: v)),
        ),
        _SliderRow(
          label: 'RotaciÃ³n',
          value: el.rotation,
          min: 0,
          max: 360,
          onChanged: (v) => onUpdate((e) => e.copyWith(rotation: v)),
        ),
      ],
    );
  }
}

class _NudgePad extends StatelessWidget {
  final void Function(double dx, double dy) onMove;

  const _NudgePad({required this.onMove});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 180,
        child: Column(
          children: [
            _NudgeButton(
              icon: PhosphorIcons.arrowUp(),
              onTap: () => onMove(0, -1),
              onLongPress: () => onMove(0, -8),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NudgeButton(
                  icon: PhosphorIcons.arrowLeft(),
                  onTap: () => onMove(-1, 0),
                  onLongPress: () => onMove(-8, 0),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Text(
                    '1 px\nMantÃ©n: 8 px',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.65),
                      height: 1.2,
                    ),
                  ),
                ),
                _NudgeButton(
                  icon: PhosphorIcons.arrowRight(),
                  onTap: () => onMove(1, 0),
                  onLongPress: () => onMove(8, 0),
                ),
              ],
            ),
            _NudgeButton(
              icon: PhosphorIcons.arrowDown(),
              onTap: () => onMove(0, 1),
              onLongPress: () => onMove(0, 8),
            ),
          ],
        ),
      ),
    );
  }
}

class _NudgeButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NudgeButton({
    required this.icon,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// _CategoryDropdown
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CategoryDropdown extends StatelessWidget {
  final String? value;
  final List<CategoryEntity> categories;
  final ValueChanged<String> onChanged;
  const _CategoryDropdown({
    required this.value,
    required this.categories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _inputDeco('Selecciona categorÃ­a'),
      dropdownColor: const Color(0xFF1E2D4E),
      style: const TextStyle(color: Colors.white),
      items: categories
          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// _StyleToggle â€“ horizontal button group
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _StyleToggle extends StatelessWidget {
  final List<String> options;
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onChanged;
  const _StyleToggle({
    required this.options,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(options.length, (i) {
        final sel = selected == options[i];
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(options[i]),
            child: Container(
              margin: EdgeInsets.only(right: i < options.length - 1 ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: sel
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sel
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: sel
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.7),
                  fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// _AlignRow
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AlignRow extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _AlignRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const opts = [
      (Icons.format_align_left, 'left'),
      (Icons.format_align_center, 'center'),
      (Icons.format_align_right, 'right'),
    ];
    return Row(
      children: opts.map((o) {
        final sel = value == o.$2;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(o.$2),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: sel
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sel
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Icon(
                o.$1,
                size: 18,
                color: sel
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Reusable small widgets
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                activeTrackColor: AppColors.primary,
                thumbColor: AppColors.primary,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                overlayColor: AppColors.primary.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1),
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.45),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final String label;
  final String hex;
  final bool allowTransparent;
  final ValueChanged<String> onChanged;

  const _ColorRow({
    required this.label,
    required this.hex,
    required this.onChanged,
    this.allowTransparent = false,
  });

  static const _presets = [
    '#FFFFFF',
    '#000000',
    '#1A1A2E',
    '#2D3436',
    '#636E72',
    '#B2BEC3',
    '#E74C3C',
    '#E91E63',
    '#9B59B6',
    '#3498DB',
    '#1ABC9C',
    '#2ECC71',
    '#F39C12',
    '#FF6B35',
    '#D4AF37',
    '#8B1A1A',
    '#FFF8F0',
    '#F5E6D3',
    '#5D4037',
    '#0A0A0F',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              if (allowTransparent)
                _dot('transparent', hex == 'transparent', transparent: true),
              for (final c in _presets)
                _dot(c, c.toLowerCase() == hex.toLowerCase()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(String color, bool selected, {bool transparent = false}) {
    return GestureDetector(
      onTap: () => onChanged(color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: transparent ? Colors.transparent : _hexToColor(color),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.2),
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: transparent
            ? Icon(
                Icons.block,
                size: 14,
                color: Colors.white.withValues(alpha: 0.4),
              )
            : null,
      ),
    );
  }
}

class _FontFamilyRow extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _FontFamilyRow({required this.value, required this.onChanged});

  static const _fonts = [
    'Poppins',
    'Roboto',
    'Inter',
    'Lato',
    'Open Sans',
    'Montserrat',
    'Playfair Display',
    'Merriweather',
    'Raleway',
    'Nunito',
    'Oswald',
    'Bebas Neue',
    'Dancing Script',
    'Pacifico',
    'Cinzel',
    'Bitter',
    'Rubik',
    'Manrope',
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _fonts.contains(value) ? value : _fonts.first,
      decoration: _inputDeco('Fuente'),
      dropdownColor: const Color(0xFF1E2D4E),
      style: const TextStyle(color: Colors.white),
      items: _fonts
          .map(
            (f) => DropdownMenuItem(
              value: f,
              child: Text(f, style: _fontPreviewStyle(f)),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

TextStyle _fontPreviewStyle(String family) {
  try {
    return GoogleFonts.getFont(family, textStyle: const TextStyle(color: Colors.white));
  } catch (_) {
    return TextStyle(fontFamily: family, color: Colors.white.withValues(alpha: 0.9));
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Helpers
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

Widget _label(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(
    text,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: Colors.white.withValues(alpha: 0.45),
      letterSpacing: 0.8,
    ),
  ),
);

InputDecoration _inputDeco(String hint) => InputDecoration(
  hintText: hint,
  isDense: true,
  filled: true,
  fillColor: Colors.white.withValues(alpha: 0.07),
  hintStyle: TextStyle(
    color: Colors.white.withValues(alpha: 0.3),
    fontSize: 13,
  ),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.primary),
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
);

ThemeData _darkTheme() => ThemeData.dark().copyWith(
  colorScheme: const ColorScheme.dark(primary: AppColors.primary),
);

Color _hexToColor(String hex) {
  final h = hex.replaceFirst('#', '');
  if (h == 'transparent' || hex == 'transparent') return Colors.transparent;
  if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
  if (h.length == 8) return Color(int.parse(h, radix: 16));
  return Colors.black;
}
