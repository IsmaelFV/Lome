import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/canvas_element.dart';
import '../../domain/entities/menu_item_entity.dart';
import '../providers/canvas_provider.dart';
import 'canvas_element_widget.dart';

// ---------------------------------------------------------------------------
// DesignCanvas – interactive canvas with zoom, pan, select, drag
// ---------------------------------------------------------------------------

class DesignCanvas extends ConsumerStatefulWidget {
  final List<CategoryEntity> categories;
  final List<MenuItemEntity> dishes;

  const DesignCanvas({
    super.key,
    required this.categories,
    required this.dishes,
  });

  @override
  ConsumerState<DesignCanvas> createState() => _DesignCanvasState();
}

class _DesignCanvasState extends ConsumerState<DesignCanvas> {
  final _transformCtrl = TransformationController();

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
      ..scale(scale, scale, 1.0);
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  double get _currentScale {
    final m = _transformCtrl.value;
    return m.getMaxScaleOnAxis();
  }

  @override
  Widget build(BuildContext context) {
    final cs = ref.watch(canvasProvider);
    final sorted = cs.sortedElements;
    final bgColor = _hexToColor(cs.backgroundColor);

    return GestureDetector(
      onTap: () => ref.read(canvasProvider.notifier).selectElement(null),
      child: Container(
        color: AppColors.grey100,
        child: InteractiveViewer(
          transformationController: _transformCtrl,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(200),
          minScale: 0.25,
          maxScale: 3.0,
          child: SizedBox(
            width: kCanvasWidth,
            height: kCanvasHeight,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // ---- Canvas background ------------------------------------
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),

                // ---- Grid overlay -----------------------------------------
                if (cs.showGrid)
                  Positioned.fill(
                    child: CustomPaint(painter: _GridPainter()),
                  ),

                // ---- Elements ---------------------------------------------
                for (final el in sorted) _buildElement(el, cs.selectedElementId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildElement(CanvasElement el, String? selectedId) {
    final isSelected = el.id == selectedId;

    return Positioned(
      left: el.x,
      top: el.y,
      width: el.width,
      height: el.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(canvasProvider.notifier).selectElement(el.id),
        onPanStart: el.locked
            ? null
            : (_) {
                ref.read(canvasProvider.notifier).selectElement(el.id);
                ref.read(canvasProvider.notifier).beginDrag();
              },
        onPanUpdate: el.locked
            ? null
            : (d) {
                final scale = _currentScale;
                ref.read(canvasProvider.notifier).moveElement(
                      el.id,
                      d.delta.dx / scale,
                      d.delta.dy / scale,
                    );
              },
        onPanEnd: el.locked
            ? null
            : (_) {},
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Element content
            CanvasElementWidget(
              element: el,
              categories: widget.categories,
              dishes: widget.dishes,
            ),

            // Selection overlay
            if (isSelected)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primary,
                        width: 1.5 / _currentScale.clamp(0.5, 2.0),
                      ),
                    ),
                  ),
                ),
              ),

            // Resize handles
            if (isSelected && !el.locked) ..._buildHandles(el),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHandles(CanvasElement el) {
    const handleSize = 10.0;
    final hs = handleSize / _currentScale.clamp(0.5, 2.0);

    Widget handle(Alignment align, void Function(DragUpdateDetails) onDrag) {
      double left, top;
      switch (align) {
        case Alignment.topLeft:
          left = -hs / 2;
          top = -hs / 2;
        case Alignment.topRight:
          left = el.width - hs / 2;
          top = -hs / 2;
        case Alignment.bottomLeft:
          left = -hs / 2;
          top = el.height - hs / 2;
        case Alignment.bottomRight:
          left = el.width - hs / 2;
          top = el.height - hs / 2;
        default:
          left = 0;
          top = 0;
      }
      return Positioned(
        left: left,
        top: top,
        width: hs,
        height: hs,
        child: GestureDetector(
          onPanStart: (_) => ref.read(canvasProvider.notifier).beginDrag(),
          onPanUpdate: onDrag,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.primary, width: 1.5),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    return [
      // Bottom-right (main resize)
      handle(Alignment.bottomRight, (d) {
        final scale = _currentScale;
        ref.read(canvasProvider.notifier).resizeElement(
              el.id,
              el.width + d.delta.dx / scale,
              el.height + d.delta.dy / scale,
            );
      }),
      // Top-left corner
      handle(Alignment.topLeft, (d) {
        final scale = _currentScale;
        final newW = el.width - d.delta.dx / scale;
        final newH = el.height - d.delta.dy / scale;
        if (newW > 30 && newH > 20) {
          ref.read(canvasProvider.notifier).moveElement(
                el.id,
                d.delta.dx / scale,
                d.delta.dy / scale,
              );
          ref.read(canvasProvider.notifier).resizeElement(el.id, newW, newH);
        }
      }),
      // Top-right
      handle(Alignment.topRight, (d) {
        final scale = _currentScale;
        final newW = el.width + d.delta.dx / scale;
        final newH = el.height - d.delta.dy / scale;
        if (newW > 30 && newH > 20) {
          ref.read(canvasProvider.notifier).moveElement(
                el.id, 0, d.delta.dy / scale);
          ref.read(canvasProvider.notifier).resizeElement(el.id, newW, newH);
        }
      }),
      // Bottom-left
      handle(Alignment.bottomLeft, (d) {
        final scale = _currentScale;
        final newW = el.width - d.delta.dx / scale;
        final newH = el.height + d.delta.dy / scale;
        if (newW > 30 && newH > 20) {
          ref.read(canvasProvider.notifier).moveElement(
                el.id, d.delta.dx / scale, 0);
          ref.read(canvasProvider.notifier).resizeElement(el.id, newW, newH);
        }
      }),
    ];
  }
}

// ---------------------------------------------------------------------------
// Grid painter
// ---------------------------------------------------------------------------

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Hex → Color helper
// ---------------------------------------------------------------------------

Color _hexToColor(String hex) {
  final h = hex.replaceFirst('#', '');
  if (h == 'transparent' || hex == 'transparent') return Colors.transparent;
  if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
  if (h.length == 8) return Color(int.parse(h, radix: 16));
  return Colors.white;
}
