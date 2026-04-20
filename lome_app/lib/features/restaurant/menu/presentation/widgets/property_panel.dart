import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/canvas_element.dart';
import '../../domain/entities/menu_item_entity.dart';
import '../providers/canvas_provider.dart';

// ---------------------------------------------------------------------------
// PropertyPanel – edits the selected canvas element
// ---------------------------------------------------------------------------

class PropertyPanel extends ConsumerStatefulWidget {
  final CanvasElement element;
  final List<CategoryEntity> categories;

  const PropertyPanel({
    super.key,
    required this.element,
    required this.categories,
  });

  @override
  ConsumerState<PropertyPanel> createState() => _PropertyPanelState();
}

class _PropertyPanelState extends ConsumerState<PropertyPanel> {
  late TextEditingController _textCtrl;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.element.text);
  }

  @override
  void didUpdateWidget(covariant PropertyPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element.id != widget.element.id) {
      _textCtrl.text = widget.element.text;
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _update(CanvasElement Function(CanvasElement) fn) {
    ref.read(canvasProvider.notifier).updateElement(widget.element.id, fn);
  }

  @override
  Widget build(BuildContext context) {
    final el = widget.element;

    return Container(
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---- Header with actions -----------------------------------------
          _PanelHeader(
            element: el,
            onDelete: () =>
                ref.read(canvasProvider.notifier).removeElement(el.id),
            onDuplicate: () =>
                ref.read(canvasProvider.notifier).duplicateElement(el.id),
            onBringFront: () =>
                ref.read(canvasProvider.notifier).bringToFront(el.id),
            onSendBack: () =>
                ref.read(canvasProvider.notifier).sendToBack(el.id),
          ),

          const Divider(height: 1),

          // ---- Type-specific controls --------------------------------------
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  switch (el.type) {
                    'text' => _textControls(el),
                    'menuBlock' => _menuBlockControls(el),
                    'shape' => _shapeControls(el),
                    'divider' => _dividerControls(el),
                    _ => const SizedBox.shrink(),
                  },
                  const SizedBox(height: AppTheme.spacingMd),
                  _animationControls(el),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // Text controls
  // =========================================================================

  Widget _textControls(CanvasElement el) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text content
        TextField(
          controller: _textCtrl,
          decoration: const InputDecoration(
            labelText: 'Texto',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          onChanged: (v) => _update((e) => e.withProp('text', v)),
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Font size
        _SliderRow(
          label: 'Tamaño',
          value: el.fontSize,
          min: 8,
          max: 72,
          onChanged: (v) =>
              _update((e) => e.withProp('fontSize', v.roundToDouble())),
        ),

        // Font weight
        Row(
          children: [
            const Text('Estilo:', style: TextStyle(fontSize: 13)),
            const SizedBox(width: AppTheme.spacingSm),
            ChoiceChip(
              label: const Text('Normal'),
              selected: el.fontWeight == 'normal',
              onSelected: (_) =>
                  _update((e) => e.withProp('fontWeight', 'normal')),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            ChoiceChip(
              label: const Text('Negrita',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              selected: el.fontWeight == 'bold',
              onSelected: (_) =>
                  _update((e) => e.withProp('fontWeight', 'bold')),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // Text align
        Row(
          children: [
            const Text('Alinear:', style: TextStyle(fontSize: 13)),
            const SizedBox(width: AppTheme.spacingSm),
            _AlignButton(Icons.format_align_left, 'left',
                el.textAlign == 'left', (v) => _update((e) => e.withProp('textAlign', v))),
            _AlignButton(Icons.format_align_center, 'center',
                el.textAlign == 'center', (v) => _update((e) => e.withProp('textAlign', v))),
            _AlignButton(Icons.format_align_right, 'right',
                el.textAlign == 'right', (v) => _update((e) => e.withProp('textAlign', v))),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // Color
        _ColorRow(
          label: 'Color',
          hex: el.color,
          onChanged: (v) => _update((e) => e.withProp('color', v)),
        ),

        // Font family
        _FontFamilyRow(
          value: el.fontFamily,
          onChanged: (v) => _update((e) => e.withProp('fontFamily', v)),
        ),
      ],
    );
  }

  // =========================================================================
  // Menu block controls
  // =========================================================================

  Widget _menuBlockControls(CanvasElement el) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category selector
        DropdownButtonFormField<String>(
          initialValue: widget.categories.any((c) => c.id == el.categoryId)
              ? el.categoryId
              : null,
          decoration: const InputDecoration(
            labelText: 'Categoría',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: widget.categories
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
              .toList(),
          onChanged: (v) {
            if (v != null) _update((e) => e.withProp('categoryId', v));
          },
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Title font size
        _SliderRow(
          label: 'Tamaño título',
          value: el.titleFontSize,
          min: 10,
          max: 36,
          onChanged: (v) =>
              _update((e) => e.withProp('titleFontSize', v.roundToDouble())),
        ),

        // Item font size
        _SliderRow(
          label: 'Tamaño platos',
          value: el.itemFontSize,
          min: 8,
          max: 24,
          onChanged: (v) =>
              _update((e) => e.withProp('itemFontSize', v.roundToDouble())),
        ),

        // Toggles
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Mostrar precios', style: TextStyle(fontSize: 14)),
          value: el.showPrices,
          activeTrackColor: AppColors.primary,
          onChanged: (v) => _update((e) => e.withProp('showPrices', v)),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Mostrar descripciones',
              style: TextStyle(fontSize: 14)),
          value: el.showDescriptions,
          activeTrackColor: AppColors.primary,
          onChanged: (v) => _update((e) => e.withProp('showDescriptions', v)),
        ),

        // Colors
        _ColorRow(
          label: 'Color título',
          hex: el.titleColor,
          onChanged: (v) => _update((e) => e.withProp('titleColor', v)),
        ),
        _ColorRow(
          label: 'Color platos',
          hex: el.itemColor,
          onChanged: (v) => _update((e) => e.withProp('itemColor', v)),
        ),
        _ColorRow(
          label: 'Color precios',
          hex: el.priceColor,
          onChanged: (v) => _update((e) => e.withProp('priceColor', v)),
        ),
      ],
    );
  }

  // =========================================================================
  // Shape controls
  // =========================================================================

  Widget _shapeControls(CanvasElement el) {
    return Column(
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
    );
  }

  // =========================================================================
  // Divider controls
  // =========================================================================

  Widget _dividerControls(CanvasElement el) {
    return Column(
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
        Row(
          children: [
            const Text('Estilo:', style: TextStyle(fontSize: 13)),
            const SizedBox(width: AppTheme.spacingSm),
            ChoiceChip(
              label: const Text('Sólido'),
              selected: el.dividerStyle == 'solid',
              onSelected: (_) =>
                  _update((e) => e.withProp('style', 'solid')),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            ChoiceChip(
              label: const Text('Rayas'),
              selected: el.dividerStyle == 'dashed',
              onSelected: (_) =>
                  _update((e) => e.withProp('style', 'dashed')),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            ChoiceChip(
              label: const Text('Puntos'),
              selected: el.dividerStyle == 'dotted',
              onSelected: (_) =>
                  _update((e) => e.withProp('style', 'dotted')),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // Animation controls (shared by all element types)
  // =========================================================================

  static const _animationOptions = <String, String>{
    'none': 'Ninguna',
    'fadeIn': 'Aparecer',
    'slideUp': 'Deslizar ↑',
    'slideDown': 'Deslizar ↓',
    'slideLeft': 'Deslizar ←',
    'slideRight': 'Deslizar →',
    'scaleIn': 'Escalar',
    'bounce': 'Rebote',
    'flip': 'Voltear',
    'pulse': 'Pulso ∞',
    'shake': 'Vibrar ∞',
  };

  Widget _animationControls(CanvasElement el) {
    final current = el.animation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.duotone),
                size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            const Text('Animación',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // Animation type chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _animationOptions.entries.map((e) {
            final selected = current == e.key;
            return ChoiceChip(
              label: Text(e.value, style: const TextStyle(fontSize: 12)),
              selected: selected,
              selectedColor: AppColors.primarySoft,
              onSelected: (_) =>
                  _update((el) => el.withProp('animation', e.key)),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),

        // Duration & delay (only show if animation is not 'none')
        if (current != 'none') ...[
          const SizedBox(height: AppTheme.spacingSm),
          _SliderRow(
            label: 'Duración (ms)',
            value: el.animationDuration.toDouble(),
            min: 100,
            max: 2000,
            onChanged: (v) => _update(
                (e) => e.withProp('animationDuration', v.round())),
          ),
          _SliderRow(
            label: 'Retardo (ms)',
            value: el.animationDelay.toDouble(),
            min: 0,
            max: 2000,
            onChanged: (v) => _update(
                (e) => e.withProp('animationDelay', v.round())),
          ),
          if (current != 'pulse' && current != 'shake')
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Repetir en bucle',
                  style: TextStyle(fontSize: 14)),
              value: el.animationLoop,
              activeTrackColor: AppColors.primary,
              onChanged: (v) =>
                  _update((e) => e.withProp('animationLoop', v)),
            ),
        ],
      ],
    );
  }
}

// ===========================================================================
// Reusable rows
// ===========================================================================

class _PanelHeader extends StatelessWidget {
  final CanvasElement element;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onBringFront;
  final VoidCallback onSendBack;

  const _PanelHeader({
    required this.element,
    required this.onDelete,
    required this.onDuplicate,
    required this.onBringFront,
    required this.onSendBack,
  });

  String get _typeLabel => switch (element.type) {
    'text' => 'Texto',
    'menuBlock' => 'Bloque de menú',
    'shape' => 'Forma',
    'divider' => 'Línea',
    'image' => 'Imagen',
    _ => 'Elemento',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          Text(
            _typeLabel,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _ActionIcon(Icon(PhosphorIcons.copySimple()), 'Duplicar', onDuplicate),
          _ActionIcon(Icon(PhosphorIcons.arrowUp()), 'Traer al frente', onBringFront),
          _ActionIcon(Icon(PhosphorIcons.arrowDown()), 'Enviar atrás', onSendBack),
          _ActionIcon(Icon(PhosphorIcons.trash()), 'Eliminar', onDelete,
              color: AppColors.error),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final Widget icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const _ActionIcon(this.icon, this.tooltip, this.onTap, {this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: icon,
      tooltip: tooltip,
      iconSize: 18,
      color: color ?? AppColors.grey700,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
      onPressed: onTap,
    );
  }
}

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
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              activeColor: AppColors.primary,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1),
              style: const TextStyle(fontSize: 12, color: AppColors.grey600),
            ),
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
    '#000000', '#2D3436', '#636E72', '#B2BEC3', '#FFFFFF',
    '#E74C3C', '#E91E63', '#9B59B6', '#3498DB', '#1ABC9C',
    '#2ECC71', '#27AE60', '#F39C12', '#FF6B35', '#8B1A1A',
    '#D4AF37', '#1A1A2E', '#5D4037', '#FFF8F0', '#F5E6D3',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (allowTransparent)
                _colorDot('transparent', hex == 'transparent',
                    transparent: true),
              for (final c in _presets) _colorDot(c, c == hex),
            ],
          ),
        ],
      ),
    );
  }

  Widget _colorDot(String color, bool selected, {bool transparent = false}) {
    return GestureDetector(
      onTap: () => onChanged(color),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: transparent ? Colors.white : _hexToColor(color),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: transparent
            ? Icon(Icons.block, size: 14, color: Colors.grey[400])
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
    'Poppins', 'Roboto', 'Inter', 'Lato', 'Open Sans',
    'Montserrat', 'Playfair Display', 'Merriweather', 'Raleway', 'Nunito',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingSm),
      child: DropdownButtonFormField<String>(
        initialValue: _fonts.contains(value) ? value : _fonts.first,
        decoration: const InputDecoration(
          labelText: 'Fuente',
          isDense: true,
          border: OutlineInputBorder(),
        ),
        items: _fonts
            .map((f) => DropdownMenuItem(
                  value: f,
                  child: Text(f, style: TextStyle(fontFamily: f)),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _AlignButton extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool selected;
  final ValueChanged<String> onChanged;

  const _AlignButton(this.icon, this.value, this.selected, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      iconSize: 20,
      color: selected ? AppColors.primary : AppColors.grey600,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
      onPressed: () => onChanged(value),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared hex → Color
// ---------------------------------------------------------------------------

Color _hexToColor(String hex) {
  final h = hex.replaceFirst('#', '');
  if (h == 'transparent' || hex == 'transparent') return Colors.transparent;
  if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
  if (h.length == 8) return Color(int.parse(h, radix: 16));
  return Colors.black;
}
