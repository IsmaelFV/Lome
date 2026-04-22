import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/canvas_element.dart';
import '../../domain/entities/menu_item_entity.dart';
import '../providers/canvas_provider.dart';
import 'canvas_element_widget.dart';

// ── Constants ────────────────────────────────────────────────────────────────
const double _kHit = 44.0;
const double _kVis = 14.0;
const double _kOv  = _kHit / 2 + 4;
const double _kRotHandleOffset = 38.0;
const double _kSnapThresh = 8.0;
const _kQuickFonts = <String>[
  'Poppins',
  'Roboto',
  'Montserrat',
  'Playfair Display',
  'Bebas Neue',
  'Oswald',
  'Pacifico',
  'Manrope',
];

enum _SnapAxis { none, h, v, both }

typedef _SnapResult = ({double x, double y, double? guideX, double? guideY});
typedef _GapGuide = ({
  Axis axis,
  double start,
  double end,
  double cross,
  double gap,
});

class DesignCanvas extends ConsumerStatefulWidget {
  final List<CategoryEntity> categories;
  final List<MenuItemEntity> dishes;
  const DesignCanvas({super.key, required this.categories, required this.dishes});
  @override
  ConsumerState<DesignCanvas> createState() => _DesignCanvasState();
}

class _DesignCanvasState extends ConsumerState<DesignCanvas> {
  final _transformCtrl = TransformationController();
  Set<String> _selectedIds = <String>{};

  bool _isDragging = false;
  bool _isResizing = false;
  bool _isRotating = false;
  double _liveW = 0, _liveH = 0;
  double _liveX = 0, _liveY = 0;
  double _liveRot = 0;
  Offset? _marqueeStart;
  Rect? _marqueeRect;
  _SnapAxis _snapAxis = _SnapAxis.none;
  double? _guideX;
  double? _guideY;
  List<_GapGuide> _gapGuides = const [];
  Offset? _rotCenterGlobal;
  double _rotStartAngle = 0;
  double _rotStartEl = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitToScreen());
  }

  void _fitToScreen() {
    final rBox = context.findRenderObject() as RenderBox?;
    if (rBox == null) return;
    final size = rBox.size;
    final scaleX = (size.width - 32) / kCanvasWidth;
    final scaleY = (size.height - 32) / kCanvasHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final dx = (size.width - kCanvasWidth * scale) / 2;
    final dy = (size.height - kCanvasHeight * scale) / 2;
    _transformCtrl.value = Matrix4.identity()
      ..setTranslationRaw(dx, dy, 0)
      ..scaleByDouble(scale, scale, 1.0, 1.0);
  }

  void _setZoom(double nextScale) {
    final rBox = context.findRenderObject() as RenderBox?;
    if (rBox == null) return;
    final viewportSize = rBox.size;
    final viewportCenter = viewportSize.center(Offset.zero);
    final sceneCenter = _transformCtrl.toScene(viewportCenter);
    final targetScale = nextScale.clamp(0.25, 3.0);
    final dx = viewportCenter.dx - sceneCenter.dx * targetScale;
    final dy = viewportCenter.dy - sceneCenter.dy * targetScale;

    _transformCtrl.value = Matrix4.identity()
      ..setTranslationRaw(dx, dy, 0)
      ..scaleByDouble(targetScale, targetScale, 1.0, 1.0);
  }

  void _stepZoom(double delta) => _setZoom(_scale + delta);

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  double get _scale => _transformCtrl.value.getMaxScaleOnAxis();
  double _sd(double d) => d / _scale;

  Set<String> _selectionFor(CanvasState cs) {
    final validLocal = _selectedIds
        .where((id) => cs.elements.any((e) => e.id == id))
        .toSet();
    if (validLocal.isNotEmpty) return validLocal;
    if (cs.selectedElementId != null) return {cs.selectedElementId!};
    return <String>{};
  }

  Rect? _selectionBounds(Iterable<CanvasElement> elements) {
    final list = elements.toList();
    if (list.isEmpty) return null;
    var left = list.first.x;
    var top = list.first.y;
    var right = list.first.x + list.first.width;
    var bottom = list.first.y + list.first.height;
    for (final el in list.skip(1)) {
      left = math.min(left, el.x);
      top = math.min(top, el.y);
      right = math.max(right, el.x + el.width);
      bottom = math.max(bottom, el.y + el.height);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  List<_GapGuide> _computeGapGuides(Rect bounds, Set<String> activeIds) {
    final others = ref
        .read(canvasProvider)
        .elements
        .where((e) => !activeIds.contains(e.id))
        .toList();

    _GapGuide? bestHorizontal;
    _GapGuide? bestVertical;

    for (final other in others) {
      final otherRect = Rect.fromLTWH(other.x, other.y, other.width, other.height);

      final verticalOverlap = math.min(bounds.bottom, otherRect.bottom) -
          math.max(bounds.top, otherRect.top);
      if (verticalOverlap > 12) {
        if (otherRect.right <= bounds.left) {
          final gap = bounds.left - otherRect.right;
          if (bestHorizontal == null || gap < bestHorizontal.gap) {
            bestHorizontal = (
              axis: Axis.horizontal,
              start: otherRect.right,
              end: bounds.left,
              cross: math.max(bounds.top, otherRect.top) + verticalOverlap / 2,
              gap: gap,
            );
          }
        }
        if (otherRect.left >= bounds.right) {
          final gap = otherRect.left - bounds.right;
          if (bestHorizontal == null || gap < bestHorizontal.gap) {
            bestHorizontal = (
              axis: Axis.horizontal,
              start: bounds.right,
              end: otherRect.left,
              cross: math.max(bounds.top, otherRect.top) + verticalOverlap / 2,
              gap: gap,
            );
          }
        }
      }

      final horizontalOverlap = math.min(bounds.right, otherRect.right) -
          math.max(bounds.left, otherRect.left);
      if (horizontalOverlap > 12) {
        if (otherRect.bottom <= bounds.top) {
          final gap = bounds.top - otherRect.bottom;
          if (bestVertical == null || gap < bestVertical.gap) {
            bestVertical = (
              axis: Axis.vertical,
              start: otherRect.bottom,
              end: bounds.top,
              cross: math.max(bounds.left, otherRect.left) + horizontalOverlap / 2,
              gap: gap,
            );
          }
        }
        if (otherRect.top >= bounds.bottom) {
          final gap = otherRect.top - bounds.bottom;
          if (bestVertical == null || gap < bestVertical.gap) {
            bestVertical = (
              axis: Axis.vertical,
              start: bounds.bottom,
              end: otherRect.top,
              cross: math.max(bounds.left, otherRect.left) + horizontalOverlap / 2,
              gap: gap,
            );
          }
        }
      }
    }

    return [
      if (bestHorizontal != null) bestHorizontal,
      if (bestVertical != null) bestVertical,
    ];
  }

  void _clearSelection() {
    ref.read(canvasProvider.notifier).selectElement(null);
    setState(() {
      _selectedIds.clear();
      _gapGuides = const [];
    });
  }

  void _selectSingle(String id) {
    ref.read(canvasProvider.notifier).selectElement(id);
    setState(() => _selectedIds = {id});
  }

  void _toggleSelection(String id, CanvasState cs) {
    final current = _selectionFor(cs);
    final next = {...current};
    if (next.contains(id)) {
      if (next.length == 1) {
        _clearSelection();
        return;
      }
      next.remove(id);
    } else {
      next.add(id);
    }

    final primary = next.isEmpty ? null : next.last;
    ref.read(canvasProvider.notifier).selectElement(primary);
    setState(() => _selectedIds = next);
  }

  void _openQuickTextEditor(CanvasElement el) {
    final notifier = ref.read(canvasProvider.notifier);
    final controller = TextEditingController(text: el.text);
    var fontSize = el.fontSize;
    var fontFamily = el.fontFamily;
    var fontWeight = el.fontWeight;
    var textAlign = el.textAlign;

    notifier.beginDrag();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF16213E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const Text(
                        'Edición rápida de texto',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Escribe aquí...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.07),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                        onChanged: (value) => notifier.updateElementLive(
                          el.id,
                          (e) => e.withProp('text', value),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _QuickLabel('Fuente'),
                      DropdownButtonFormField<String>(
                        value: _kQuickFonts.contains(fontFamily)
                            ? fontFamily
                            : _kQuickFonts.first,
                        dropdownColor: const Color(0xFF1E2D4E),
                        style: const TextStyle(color: Colors.white),
                        decoration: _quickInputDeco(),
                        items: _kQuickFonts
                            .map(
                              (font) => DropdownMenuItem(
                                value: font,
                                child: Text(font),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => fontFamily = value);
                          notifier.updateElementLive(
                            el.id,
                            (e) => e.withProp('fontFamily', value),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _QuickLabel('Tamaño'),
                      Slider(
                        value: fontSize.clamp(8, 96),
                        min: 8,
                        max: 96,
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          setSheetState(() => fontSize = value);
                          notifier.updateElementLive(
                            el.id,
                            (e) => e.withProp('fontSize', value.roundToDouble()),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _QuickLabel('Peso'),
                      Row(
                        children: [
                          _QuickToggle(
                            label: 'Normal',
                            selected: fontWeight == 'normal',
                            onTap: () {
                              setSheetState(() => fontWeight = 'normal');
                              notifier.updateElementLive(
                                el.id,
                                (e) => e.withProp('fontWeight', 'normal'),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          _QuickToggle(
                            label: 'Negrita',
                            selected: fontWeight == 'bold',
                            onTap: () {
                              setSheetState(() => fontWeight = 'bold');
                              notifier.updateElementLive(
                                el.id,
                                (e) => e.withProp('fontWeight', 'bold'),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _QuickLabel('Alineación'),
                      Row(
                        children: [
                          _QuickIconToggle(
                            icon: Icons.format_align_left,
                            selected: textAlign == 'left',
                            onTap: () {
                              setSheetState(() => textAlign = 'left');
                              notifier.updateElementLive(
                                el.id,
                                (e) => e.withProp('textAlign', 'left'),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          _QuickIconToggle(
                            icon: Icons.format_align_center,
                            selected: textAlign == 'center',
                            onTap: () {
                              setSheetState(() => textAlign = 'center');
                              notifier.updateElementLive(
                                el.id,
                                (e) => e.withProp('textAlign', 'center'),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          _QuickIconToggle(
                            icon: Icons.format_align_right,
                            selected: textAlign == 'right',
                            onTap: () {
                              setSheetState(() => textAlign = 'right');
                              notifier.updateElementLive(
                                el.id,
                                (e) => e.withProp('textAlign', 'right'),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(controller.dispose);
  }

  void _openArrangeSheet(List<CanvasElement> selection) {
    final ids = selection.map((e) => e.id).toList();
    final notifier = ref.read(canvasProvider.notifier);
    if (ids.length < 2) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF16213E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Alinear y distribuir',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ArrangeAction(label: 'Izquierda', icon: Icons.align_horizontal_left_rounded, onTap: () { notifier.alignElementsLeft(ids); Navigator.pop(context); }),
                      _ArrangeAction(label: 'Centro X', icon: Icons.align_horizontal_center_rounded, onTap: () { notifier.alignElementsCenterX(ids); Navigator.pop(context); }),
                      _ArrangeAction(label: 'Derecha', icon: Icons.align_horizontal_right_rounded, onTap: () { notifier.alignElementsRight(ids); Navigator.pop(context); }),
                      _ArrangeAction(label: 'Arriba', icon: Icons.vertical_align_top_rounded, onTap: () { notifier.alignElementsTop(ids); Navigator.pop(context); }),
                      _ArrangeAction(label: 'Centro Y', icon: Icons.vertical_align_center_rounded, onTap: () { notifier.alignElementsMiddleY(ids); Navigator.pop(context); }),
                      _ArrangeAction(label: 'Abajo', icon: Icons.vertical_align_bottom_rounded, onTap: () { notifier.alignElementsBottom(ids); Navigator.pop(context); }),
                      _ArrangeAction(label: 'Distribuir H', icon: Icons.view_week_outlined, onTap: () { notifier.distributeElementsHorizontally(ids); Navigator.pop(context); }),
                      _ArrangeAction(label: 'Distribuir V', icon: Icons.view_agenda_outlined, onTap: () { notifier.distributeElementsVertically(ids); Navigator.pop(context); }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _startMarqueeSelection(Offset localPosition) {
    setState(() {
      _marqueeStart = localPosition;
      _marqueeRect = Rect.fromPoints(localPosition, localPosition);
      _snapAxis = _SnapAxis.none;
      _guideX = null;
      _guideY = null;
      _gapGuides = const [];
    });
  }

  void _updateMarqueeSelection(Offset localPosition) {
    final start = _marqueeStart;
    if (start == null) return;
    setState(() {
      _marqueeRect = Rect.fromPoints(start, localPosition);
    });
  }

  void _finishMarqueeSelection(CanvasState cs) {
    final rect = _marqueeRect;
    final isTapLike = rect == null || (rect.width < 12 && rect.height < 12);

    if (isTapLike) {
      setState(() {
        _marqueeStart = null;
        _marqueeRect = null;
      });
      return;
    }

    final selected = cs.elements
        .where(
          (e) => rect.overlaps(Rect.fromLTWH(e.x, e.y, e.width, e.height)),
        )
        .map((e) => e.id)
        .toSet();
    final primary = selected.isEmpty ? null : selected.last;

    ref.read(canvasProvider.notifier).selectElement(primary);
    setState(() {
      _selectedIds = selected;
      _marqueeStart = null;
      _marqueeRect = null;
    });
  }

  _SnapResult _snap(
    double x,
    double y,
    double w,
    double h,
    Set<String> activeIds,
  ) {
    final cx = x + w / 2;
    final cy = y + h / 2;
    double nx = x, ny = y;
    bool sh = false, sv = false;
    double? guideX;
    double? guideY;

    if ((x).abs() < _kSnapThresh) {
      nx = 0;
      sh = true;
      guideX = 0;
    }
    if ((x + w - kCanvasWidth).abs() < _kSnapThresh) {
      nx = kCanvasWidth - w;
      sh = true;
      guideX = kCanvasWidth;
    }
    if ((y).abs() < _kSnapThresh) {
      ny = 0;
      sv = true;
      guideY = 0;
    }
    if ((y + h - kCanvasHeight).abs() < _kSnapThresh) {
      ny = kCanvasHeight - h;
      sv = true;
      guideY = kCanvasHeight;
    }

    if ((cx - kCanvasWidth / 2).abs() < _kSnapThresh) { nx = kCanvasWidth / 2 - w / 2; sh = true; }
    if ((cy - kCanvasHeight / 2).abs() < _kSnapThresh) { ny = kCanvasHeight / 2 - h / 2; sv = true; }

    if (sh) guideX = kCanvasWidth / 2;
    if (sv) guideY = kCanvasHeight / 2;

    final elements = ref.read(canvasProvider).elements;
    for (final other in elements) {
      if (activeIds.contains(other.id)) continue;

      final otherCenterX = other.x + other.width / 2;
      final otherCenterY = other.y + other.height / 2;
      final otherLeft = other.x;
      final otherRight = other.x + other.width;
      final otherTop = other.y;
      final otherBottom = other.y + other.height;

      if (!sh && (cx - otherCenterX).abs() < _kSnapThresh) {
        nx = otherCenterX - w / 2;
        sh = true;
        guideX = otherCenterX;
      }
      if (!sh && (x - otherLeft).abs() < _kSnapThresh) {
        nx = otherLeft;
        sh = true;
        guideX = otherLeft;
      }
      if (!sh && (x + w - otherRight).abs() < _kSnapThresh) {
        nx = otherRight - w;
        sh = true;
        guideX = otherRight;
      }
      if (!sh && (x - otherRight).abs() < _kSnapThresh) {
        nx = otherRight;
        sh = true;
        guideX = otherRight;
      }
      if (!sh && (x + w - otherLeft).abs() < _kSnapThresh) {
        nx = otherLeft - w;
        sh = true;
        guideX = otherLeft;
      }

      if (!sv && (cy - otherCenterY).abs() < _kSnapThresh) {
        ny = otherCenterY - h / 2;
        sv = true;
        guideY = otherCenterY;
      }
      if (!sv && (y - otherTop).abs() < _kSnapThresh) {
        ny = otherTop;
        sv = true;
        guideY = otherTop;
      }
      if (!sv && (y + h - otherBottom).abs() < _kSnapThresh) {
        ny = otherBottom - h;
        sv = true;
        guideY = otherBottom;
      }
      if (!sv && (y - otherBottom).abs() < _kSnapThresh) {
        ny = otherBottom;
        sv = true;
        guideY = otherBottom;
      }
      if (!sv && (y + h - otherTop).abs() < _kSnapThresh) {
        ny = otherTop - h;
        sv = true;
        guideY = otherTop;
      }
    }

    _snapAxis = sh && sv ? _SnapAxis.both : sh ? _SnapAxis.h : sv ? _SnapAxis.v : _SnapAxis.none;
    return (x: nx, y: ny, guideX: guideX, guideY: guideY);
  }

  @override
  Widget build(BuildContext context) {
    final cs = ref.watch(canvasProvider);
    final sorted = cs.sortedElements;
    final bgColor = _hexToColor(cs.backgroundColor);
    final selectionIds = _selectionFor(cs);
    final selectedElements = cs.elements
        .where((e) => selectionIds.contains(e.id))
        .toList();
    final selectedEl = selectionIds.length == 1 ? selectedElements.firstOrNull : null;
    final selectionBounds = _selectionBounds(selectedElements);

    return GestureDetector(
      onTap: _clearSelection,
      child: Container(
        color: const Color(0xFFEEF0F3),
        child: InteractiveViewer(
          transformationController: _transformCtrl,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(200),
          minScale: 0.25,
          maxScale: 3.0,
          panEnabled: !_isDragging && !_isResizing && !_isRotating,
          scaleEnabled: !_isDragging && !_isResizing && !_isRotating,
          child: SizedBox(
            width: kCanvasWidth,
            height: kCanvasHeight,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 32, spreadRadius: 2, offset: const Offset(0, 6)),
                        BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _clearSelection,
                    onDoubleTap: _fitToScreen,
                    onLongPressStart: (details) =>
                        _startMarqueeSelection(details.localPosition),
                    onLongPressMoveUpdate: (details) =>
                        _updateMarqueeSelection(details.localPosition),
                    onLongPressEnd: (_) => _finishMarqueeSelection(cs),
                  ),
                ),
                if (cs.showGrid)
                  Positioned.fill(child: CustomPaint(painter: _GridPainter(bgColor))),
                if (_isDragging && (_guideX != null || _guideY != null))
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _SnapGuidePainter(
                          axis: _snapAxis,
                          guideX: _guideX,
                          guideY: _guideY,
                        ),
                      ),
                    ),
                  ),
                if (_isDragging && _gapGuides.isNotEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _GapGuidePainter(_gapGuides),
                      ),
                    ),
                  ),
                for (final el in sorted) _buildElement(el, selectionIds, cs),
                if (_marqueeRect != null)
                  Positioned(
                    left: _marqueeRect!.left,
                    top: _marqueeRect!.top,
                    width: _marqueeRect!.width,
                    height: _marqueeRect!.height,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.95),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                _buildCanvasHud(),
                if (selectionBounds != null)
                  _buildContextToolbar(selectionBounds, selectedElements),
                if (selectionBounds != null && selectionIds.length > 1)
                  _buildGroupBounds(selectionBounds, selectionIds.length),
                if (_isResizing && selectedEl != null)
                  _DimensionTooltip(x: selectedEl.x, y: selectedEl.y, w: _liveW, h: _liveH),
                if (_isDragging && !_isResizing && selectedEl != null)
                  _PositionTooltip(x: _liveX, y: _liveY),
                if (_isRotating && selectedEl != null)
                  _RotationTooltip(angleDeg: _liveRot, cx: selectedEl.x + selectedEl.width / 2, cy: selectedEl.y + selectedEl.height / 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasHud() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: ValueListenableBuilder<Matrix4>(
        valueListenable: _transformCtrl,
        builder: (context, value, child) {
          final zoom = (_scale * 100).round();
          return DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF101827).withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CanvasHudButton(
                    icon: Icons.remove_rounded,
                    onTap: () => _stepZoom(-0.15),
                  ),
                  GestureDetector(
                    onTap: _fitToScreen,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 76),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$zoom%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Ajustar',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _CanvasHudButton(
                    icon: Icons.add_rounded,
                    onTap: () => _stepZoom(0.15),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildElement(CanvasElement el, Set<String> selectionIds, CanvasState cs) {
    final isSelected = selectionIds.contains(el.id);
    final showHandles = selectionIds.length == 1 && isSelected && !el.locked;
    final touchH = math.max(el.height, 28.0);
    final vPad = (touchH - el.height) / 2;
    final ov = showHandles ? _kOv : 0.0;
    final contentLeft = ov;
    final contentTop  = ov + vPad;
    final rotRad = el.rotation * math.pi / 180.0;

    return Positioned(
      left: el.x - ov,
      top:  el.y - ov - vPad,
      width:  el.width + ov * 2,
      height: touchH   + ov * 2,
      child: Transform.rotate(
        angle: rotRad,
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: contentLeft, top: contentTop,
              width: el.width, height: el.height,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _selectSingle(el.id),
                onLongPress: () => _toggleSelection(el.id, cs),
                onDoubleTap: el.type == 'text'
                    ? () => _openQuickTextEditor(el)
                    : null,
                onPanStart: el.locked ? null : (d) {
                  final groupDrag = isSelected && selectionIds.length > 1;
                  ref.read(canvasProvider.notifier).selectElement(el.id);
                  ref.read(canvasProvider.notifier).beginDrag();
                  final bounds = groupDrag
                      ? _selectionBounds(
                          ref.read(canvasProvider).elements.where(
                                (e) => selectionIds.contains(e.id),
                              ),
                        )
                      : null;
                  setState(() {
                    _isDragging = true;
                    _liveX = bounds?.left ?? el.x;
                    _liveY = bounds?.top ?? el.y;
                    _snapAxis = _SnapAxis.none;
                    _guideX = null;
                    _guideY = null;
                    _gapGuides = const [];
                  });
                },
                onPanUpdate: el.locked ? null : (d) {
                  final notifier = ref.read(canvasProvider.notifier);
                  if (isSelected && selectionIds.length > 1) {
                    notifier.moveElements(
                      selectionIds.toList(),
                      _sd(d.delta.dx),
                      _sd(d.delta.dy),
                    );

                    final currentSelection = ref
                        .read(canvasProvider)
                        .elements
                        .where((e) => selectionIds.contains(e.id));
                    final currentBounds = _selectionBounds(currentSelection);
                    if (currentBounds == null) return;
                    final snapped = _snap(
                      currentBounds.left,
                      currentBounds.top,
                      currentBounds.width,
                      currentBounds.height,
                      selectionIds,
                    );
                    notifier.moveElements(
                      selectionIds.toList(),
                      snapped.x - currentBounds.left,
                      snapped.y - currentBounds.top,
                    );

                    setState(() {
                      _liveX = snapped.x;
                      _liveY = snapped.y;
                      _guideX = snapped.guideX;
                      _guideY = snapped.guideY;
                      _gapGuides = _computeGapGuides(
                        Rect.fromLTWH(
                          snapped.x,
                          snapped.y,
                          currentBounds.width,
                          currentBounds.height,
                        ),
                        selectionIds,
                      );
                    });
                    return;
                  }

                  notifier.moveElement(el.id, _sd(d.delta.dx), _sd(d.delta.dy));

                  final current = ref
                      .read(canvasProvider)
                      .elements
                      .firstWhere((e) => e.id == el.id);
                  final snapped = _snap(
                    current.x,
                    current.y,
                    current.width,
                    current.height,
                    {el.id},
                  );
                  notifier.moveElement(
                    el.id,
                    snapped.x - current.x,
                    snapped.y - current.y,
                  );

                  setState(() {
                    _liveX = snapped.x;
                    _liveY = snapped.y;
                    _guideX = snapped.guideX;
                    _guideY = snapped.guideY;
                    _gapGuides = _computeGapGuides(
                      Rect.fromLTWH(
                        snapped.x,
                        snapped.y,
                        current.width,
                        current.height,
                      ),
                      {el.id},
                    );
                  });
                },
                onPanEnd: el.locked ? null : (_) => setState(() {
                  _isDragging = false;
                  _snapAxis = _SnapAxis.none;
                  _guideX = null;
                  _guideY = null;
                  _gapGuides = const [];
                }),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CanvasElementWidget(element: el, categories: widget.categories, dishes: widget.dishes),
                    if (isSelected)
                      Positioned.fill(child: IgnorePointer(child: _SelectionOverlay(scale: _scale, locked: el.locked))),
                  ],
                ),
              ),
            ),
            if (vPad > 0) ...[
              Positioned(
                left: contentLeft, top: ov, width: el.width, height: vPad,
                child: GestureDetector(behavior: HitTestBehavior.opaque,
                    onTap: () => _selectSingle(el.id)),
              ),
              Positioned(
                left: contentLeft, top: contentTop + el.height, width: el.width, height: vPad,
                child: GestureDetector(behavior: HitTestBehavior.opaque,
                    onTap: () => _selectSingle(el.id)),
              ),
            ],
            if (showHandles) ...[
              ..._buildResizeHandles(el, contentLeft, contentTop),
              _buildRotationHandle(el, contentLeft, contentTop),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContextToolbar(Rect bounds, List<CanvasElement> selection) {
    final ids = selection.map((e) => e.id).toList();
    final isSingleText = selection.length == 1 && selection.first.type == 'text';
    final barWidth = selection.length > 1 ? 236.0 : (isSingleText ? 232.0 : 192.0);
    final left = (bounds.center.dx - barWidth / 2).clamp(
      8.0,
      kCanvasWidth - barWidth - 8.0,
    );
    final top = math.max(bounds.top - 56, 8.0);
    final notifier = ref.read(canvasProvider.notifier);

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF101827),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSingleText)
                _ContextAction(
                  icon: Icons.edit_rounded,
                  onTap: () => _openQuickTextEditor(selection.first),
                ),
              _ContextAction(
                icon: Icons.copy_rounded,
                onTap: () {
                  final newIds = notifier.duplicateElements(ids);
                  setState(() => _selectedIds = newIds.toSet());
                },
                onPanStart: selection.isEmpty
                    ? null
                    : (_) {
                        final newIds = notifier.duplicateElements(ids);
                        final newSelection = newIds.toSet();
                        final duplicated = ref
                            .read(canvasProvider)
                            .elements
                            .where((e) => newSelection.contains(e.id))
                            .toList();
                        final duplicatedBounds = _selectionBounds(duplicated);
                        setState(() {
                          _selectedIds = newSelection;
                          _isDragging = true;
                          _snapAxis = _SnapAxis.none;
                          _guideX = null;
                          _guideY = null;
                          _gapGuides = const [];
                          _liveX = duplicatedBounds?.left ?? 0;
                          _liveY = duplicatedBounds?.top ?? 0;
                        });
                      },
                onPanUpdate: selection.isEmpty
                    ? null
                    : (d) {
                        final activeIds = _selectedIds.toList();
                        notifier.moveElements(activeIds, _sd(d.delta.dx), _sd(d.delta.dy));
                        final currentSelection = ref
                            .read(canvasProvider)
                            .elements
                            .where((e) => _selectedIds.contains(e.id));
                        final currentBounds = _selectionBounds(currentSelection);
                        if (currentBounds == null) return;
                        final snapped = _snap(
                          currentBounds.left,
                          currentBounds.top,
                          currentBounds.width,
                          currentBounds.height,
                          _selectedIds,
                        );
                        notifier.moveElements(
                          activeIds,
                          snapped.x - currentBounds.left,
                          snapped.y - currentBounds.top,
                        );
                        setState(() {
                          _liveX = snapped.x;
                          _liveY = snapped.y;
                          _guideX = snapped.guideX;
                          _guideY = snapped.guideY;
                          _gapGuides = _computeGapGuides(
                            Rect.fromLTWH(
                              snapped.x,
                              snapped.y,
                              currentBounds.width,
                              currentBounds.height,
                            ),
                            _selectedIds,
                          );
                        });
                      },
                onPanEnd: selection.isEmpty
                    ? null
                    : (_) {
                        setState(() {
                          _isDragging = false;
                          _snapAxis = _SnapAxis.none;
                          _guideX = null;
                          _guideY = null;
                          _gapGuides = const [];
                        });
                      },
              ),
              if (selection.length > 1)
                _ContextAction(
                  icon: Icons.space_dashboard_outlined,
                  onTap: () => _openArrangeSheet(selection),
                ),
              _ContextAction(
                icon: Icons.vertical_align_top_rounded,
                onTap: () => notifier.bringToFrontMany(ids),
              ),
              _ContextAction(
                icon: Icons.vertical_align_bottom_rounded,
                onTap: () => notifier.sendToBackMany(ids),
              ),
              _ContextAction(
                icon: Icons.delete_outline_rounded,
                destructive: true,
                onTap: () {
                  notifier.removeElements(ids);
                  setState(() => _selectedIds.clear());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupBounds(Rect bounds, int count) {
    return Positioned(
      left: bounds.left - 4,
      top: bounds.top - 4,
      width: bounds.width + 8,
      height: bounds.height + 8,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.9),
              width: 1.4,
            ),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Transform.translate(
              offset: const Offset(-2, -24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count seleccionados',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRotationHandle(CanvasElement el, double cLeft, double cTop) {
    final cx = cLeft + el.width / 2;
    final cy = cTop  - _kRotHandleOffset;
    return Positioned(
      left: cx - _kHit / 2,
      top:  cy - _kHit / 2,
      width: _kHit, height: _kHit,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) {
          ref.read(canvasProvider.notifier).beginDrag();
          setState(() {
            _isRotating = true;
            _liveRot = el.rotation;
            final box = context.findRenderObject() as RenderBox?;
            final centerCanvas = Offset(
              el.x + el.width / 2,
              el.y + el.height / 2,
            );
            _rotCenterGlobal = box?.localToGlobal(centerCanvas) ?? d.globalPosition;
            _rotStartAngle = math.atan2(
              d.globalPosition.dy - _rotCenterGlobal!.dy,
              d.globalPosition.dx - _rotCenterGlobal!.dx,
            );
            _rotStartEl = el.rotation;
          });
        },
        onPanUpdate: (d) {
          if (_rotCenterGlobal == null) return;
          final cur = math.atan2(
            d.globalPosition.dy - _rotCenterGlobal!.dy,
            d.globalPosition.dx - _rotCenterGlobal!.dx,
          );
          final delta = (cur - _rotStartAngle) * 180 / math.pi;
          final newAngle = (_rotStartEl + delta) % 360;
          ref.read(canvasProvider.notifier).rotateElement(el.id, newAngle);
          setState(() => _liveRot = newAngle);
        },
        onPanEnd: (_) => setState(() {
          _isRotating = false;
          _rotCenterGlobal = null;
        }),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: _kHit / 2,
              left: _kHit / 2 - 0.5,
              child: Container(
                width: 1,
                height: _kRotHandleOffset - _kVis / 2 - 2,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            Container(
              width: _kVis + 4, height: _kVis + 4,
              decoration: BoxDecoration(
                color: Colors.white, shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: Icon(Icons.rotate_right_rounded, size: 11, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResizeHandles(CanvasElement el, double cLeft, double cTop) {
    final s = _scale;
    final lx = cLeft; final rx = cLeft + el.width;
    final ty = cTop;  final by = cTop  + el.height;
    final mx = cLeft + el.width / 2;
    final my = cTop  + el.height / 2;

    Widget h({required double cx, required double cy, required _HandleKind kind, required Axis? axis, required void Function(DragUpdateDetails) onUpdate}) {
      return Positioned(
        left: cx - _kHit / 2, top: cy - _kHit / 2,
        width: _kHit, height: _kHit,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) {
            ref.read(canvasProvider.notifier).beginDrag();
            setState(() { _isResizing = true; _liveW = el.width; _liveH = el.height; });
          },
          onPanUpdate: (d) {
            onUpdate(d);
            final updated = ref.read(canvasProvider).elements.firstWhere((e) => e.id == el.id);
            setState(() { _liveW = updated.width; _liveH = updated.height; });
          },
          onPanEnd: (_) => setState(() => _isResizing = false),
          child: Center(child: _HandleWidget(kind: kind, axis: axis, scale: s)),
        ),
      );
    }

    double dw(double dx) => dx / s;
    double dh(double dy) => dy / s;
    final n = ref.read(canvasProvider.notifier);
    void resize(double w, double hh) => n.resizeElement(el.id, w, hh);
    void move(double dx, double dy) => n.moveElement(el.id, dx, dy);
    CanvasElement currentEl() => ref.read(canvasProvider).elements.firstWhere((e) => e.id == el.id);
    bool lockAspect(CanvasElement current) =>
        current.type == 'image' ||
      current.type == 'carousel' ||
        (current.type == 'shape' && current.shapeType == 'circle');

    void resizeCornerLocked(String corner, DragUpdateDetails d) {
      final current = currentEl();
      final deltaX = dw(d.delta.dx);
      final deltaY = dh(d.delta.dy);

      if (!lockAspect(current)) {
        switch (corner) {
          case 'br':
            resize(
              math.max(30.0, current.width + deltaX),
              math.max(20.0, current.height + deltaY),
            );
          case 'bl':
            final nw = math.max(30.0, current.width - deltaX);
            if (nw > 30.0) move(deltaX, 0);
            resize(nw, math.max(20.0, current.height + deltaY));
          case 'tr':
            final nh = math.max(20.0, current.height - deltaY);
            if (nh > 20.0) move(0, deltaY);
            resize(math.max(30.0, current.width + deltaX), nh);
          case 'tl':
            final nw = math.max(30.0, current.width - deltaX);
            final nh = math.max(20.0, current.height - deltaY);
            if (nw > 30.0) move(deltaX, 0);
            if (nh > 20.0) move(0, deltaY);
            resize(nw, nh);
        }
        return;
      }

      final ratio = current.width / current.height;
      final widthDelta = switch (corner) {
        'br' || 'tr' => deltaX,
        _ => -deltaX,
      };
      final heightDelta = switch (corner) {
        'br' || 'bl' => deltaY,
        _ => -deltaY,
      };

      double nw;
      double nh;

      if (widthDelta.abs() >= heightDelta.abs() * ratio) {
        nw = math.max(30.0, current.width + widthDelta);
        nh = math.max(20.0, nw / ratio);
        nw = nh * ratio;
      } else {
        nh = math.max(20.0, current.height + heightDelta);
        nw = math.max(30.0, nh * ratio);
        nh = nw / ratio;
      }

      final moveX = (corner == 'bl' || corner == 'tl')
          ? current.width - nw
          : 0.0;
      final moveY = (corner == 'tr' || corner == 'tl')
          ? current.height - nh
          : 0.0;

      if (moveX != 0 || moveY != 0) {
        move(moveX, moveY);
      }
      resize(nw, nh);
    }

    return [
      h(cx: rx, cy: by, kind: _HandleKind.corner, axis: null, onUpdate: (d) => resizeCornerLocked('br', d)),
      h(cx: lx, cy: by, kind: _HandleKind.corner, axis: null, onUpdate: (d) => resizeCornerLocked('bl', d)),
      h(cx: rx, cy: ty, kind: _HandleKind.corner, axis: null, onUpdate: (d) => resizeCornerLocked('tr', d)),
      h(cx: lx, cy: ty, kind: _HandleKind.corner, axis: null, onUpdate: (d) => resizeCornerLocked('tl', d)),
      h(cx: rx, cy: my, kind: _HandleKind.mid, axis: Axis.vertical, onUpdate: (d) { final current = currentEl(); resize(math.max(30.0, current.width + dw(d.delta.dx)), current.height); }),
      h(cx: lx, cy: my, kind: _HandleKind.mid, axis: Axis.vertical, onUpdate: (d) { final current = currentEl(); final nw = math.max(30.0, current.width - dw(d.delta.dx)); if (nw > 30.0) move(dw(d.delta.dx), 0); resize(nw, current.height); }),
      h(cx: mx, cy: by, kind: _HandleKind.mid, axis: Axis.horizontal, onUpdate: (d) { final current = currentEl(); resize(current.width, math.max(20.0, current.height + dh(d.delta.dy))); }),
      h(cx: mx, cy: ty, kind: _HandleKind.mid, axis: Axis.horizontal, onUpdate: (d) { final current = currentEl(); final nh = math.max(20.0, current.height - dh(d.delta.dy)); if (nh > 20.0) move(0, dh(d.delta.dy)); resize(current.width, nh); }),
    ];
  }
}

class _QuickLabel extends StatelessWidget {
  final String text;
  const _QuickLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.55),
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _CanvasHudButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CanvasHudButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _ContextAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;

  const _ContextAction({
    required this.icon,
    required this.onTap,
    this.destructive = false,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFEF4444) : Colors.white;
    return GestureDetector(
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: destructive ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

class _ArrangeAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ArrangeAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 148,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _quickInputDeco() => InputDecoration(
  isDense: true,
  filled: true,
  fillColor: Colors.white.withValues(alpha: 0.07),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
  ),
  focusedBorder: const OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: AppColors.primary),
  ),
);

class _QuickToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.15),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.primary : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickIconToggle extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _QuickIconToggle({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: selected ? AppColors.primary : Colors.white,
        ),
      ),
    );
  }
}

// ── Grid painter ──────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final Color canvasBg;
  const _GridPainter(this.canvasBg);
  Color get _dotColor => canvasBg.computeLuminance() > 0.5
      ? Colors.black.withValues(alpha: 0.12)
      : Colors.white.withValues(alpha: 0.15);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _dotColor..strokeCap = StrokeCap.round..strokeWidth = 1.5;
    const step = 30.0;
    for (double x = step; x < size.width; x += step)
      for (double y = step; y < size.height; y += step)
        canvas.drawCircle(Offset(x, y), 1.0, paint);
  }
  @override
  bool shouldRepaint(_GridPainter old) => old.canvasBg != canvasBg;
}

// ── Snap guide painter ────────────────────────────────────────────────────────
class _SnapGuidePainter extends CustomPainter {
  final _SnapAxis axis;
  final double? guideX;
  final double? guideY;

  const _SnapGuidePainter({
    required this.axis,
    required this.guideX,
    required this.guideY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF2196F3)..strokeWidth = 1.0;
    if ((axis == _SnapAxis.h || axis == _SnapAxis.both) && guideX != null) {
      canvas.drawLine(Offset(guideX!, 0), Offset(guideX!, size.height), paint);
    }
    if ((axis == _SnapAxis.v || axis == _SnapAxis.both) && guideY != null) {
      canvas.drawLine(Offset(0, guideY!), Offset(size.width, guideY!), paint);
    }
  }
  @override
  bool shouldRepaint(_SnapGuidePainter old) =>
      old.axis != axis || old.guideX != guideX || old.guideY != guideY;
}

class _GapGuidePainter extends CustomPainter {
  final List<_GapGuide> guides;
  const _GapGuidePainter(this.guides);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 1.2;
    final capPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 1.0;

    for (final guide in guides) {
      if (guide.axis == Axis.horizontal) {
        canvas.drawLine(
          Offset(guide.start, guide.cross),
          Offset(guide.end, guide.cross),
          linePaint,
        );
        canvas.drawLine(
          Offset(guide.start, guide.cross - 6),
          Offset(guide.start, guide.cross + 6),
          capPaint,
        );
        canvas.drawLine(
          Offset(guide.end, guide.cross - 6),
          Offset(guide.end, guide.cross + 6),
          capPaint,
        );

        _paintLabel(
          canvas,
          Offset((guide.start + guide.end) / 2, guide.cross - 12),
          guide.gap,
        );
      } else {
        canvas.drawLine(
          Offset(guide.cross, guide.start),
          Offset(guide.cross, guide.end),
          linePaint,
        );
        canvas.drawLine(
          Offset(guide.cross - 6, guide.start),
          Offset(guide.cross + 6, guide.start),
          capPaint,
        );
        canvas.drawLine(
          Offset(guide.cross - 6, guide.end),
          Offset(guide.cross + 6, guide.end),
          capPaint,
        );

        _paintLabel(
          canvas,
          Offset(guide.cross + 12, (guide.start + guide.end) / 2),
          guide.gap,
        );
      }
    }
  }

  void _paintLabel(Canvas canvas, Offset center, double gap) {
    final painter = TextPainter(
      text: TextSpan(
        text: gap.round().toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: painter.width + 10,
        height: painter.height + 6,
      ),
      const Radius.circular(999),
    );

    canvas.drawRRect(
      rect,
      Paint()..color = const Color(0xFFF59E0B),
    );
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_GapGuidePainter old) => old.guides != guides;
}

// ── Selection overlay ─────────────────────────────────────────────────────────
class _SelectionOverlay extends StatelessWidget {
  final double scale;
  final bool locked;
  const _SelectionOverlay({required this.scale, required this.locked});
  @override
  Widget build(BuildContext context) {
    final bw = (2.0 / scale).clamp(1.0, 2.5);
    final color = locked ? Colors.orange : AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color, width: bw),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 8 / scale, spreadRadius: 1 / scale)],
      ),
    );
  }
}

// ── Handle kind & widget ──────────────────────────────────────────────────────
enum _HandleKind { corner, mid }

class _HandleWidget extends StatelessWidget {
  final _HandleKind kind;
  final Axis? axis;
  final double scale;
  const _HandleWidget({required this.kind, required this.axis, required this.scale});
  @override
  Widget build(BuildContext context) {
    final vis = (_kVis / scale.clamp(0.5, 1.5)).clamp(10.0, 20.0);
    if (kind == _HandleKind.corner) {
      return Container(
        width: vis, height: vis,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: AppColors.primary, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 5, offset: const Offset(0, 2))],
        ),
      );
    }
    final isH = axis == Axis.horizontal;
    return Container(
      width: isH ? vis * 1.6 : vis * 0.65,
      height: isH ? vis * 0.65 : vis * 1.6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 3, offset: const Offset(0, 1))],
      ),
    );
  }
}

// ── Tooltips ──────────────────────────────────────────────────────────────────
class _DimensionTooltip extends StatelessWidget {
  final double x, y, w, h;
  const _DimensionTooltip({required this.x, required this.y, required this.w, required this.h});
  @override
  Widget build(BuildContext context) =>
      Positioned(left: x + w / 2 - 48, top: y + h + 8, child: _InfoPill('${w.round()} × ${h.round()}'));
}

class _PositionTooltip extends StatelessWidget {
  final double x, y;
  const _PositionTooltip({required this.x, required this.y});
  @override
  Widget build(BuildContext context) =>
      Positioned(left: x - 4, top: y - 28, child: _InfoPill('${x.round()}, ${y.round()}'));
}

class _RotationTooltip extends StatelessWidget {
  final double angleDeg, cx, cy;
  const _RotationTooltip({required this.angleDeg, required this.cx, required this.cy});
  @override
  Widget build(BuildContext context) =>
      Positioned(left: cx - 30, top: cy - 50, child: _InfoPill('${angleDeg.round()}°'));
}

class _InfoPill extends StatelessWidget {
  final String text;
  const _InfoPill(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6)],
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()])),
    );
  }
}

// ── Hex → Color ───────────────────────────────────────────────────────────────
Color _hexToColor(String hex) {
  final h = hex.replaceFirst('#', '');
  if (h == 'transparent' || hex == 'transparent') return Colors.transparent;
  if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
  if (h.length == 8) return Color(int.parse(h, radix: 16));
  return Colors.white;
}