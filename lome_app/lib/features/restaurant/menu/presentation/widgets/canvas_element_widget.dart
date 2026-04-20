import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/entities/canvas_element.dart';
import '../../domain/entities/menu_item_entity.dart';

// ---------------------------------------------------------------------------
// CanvasElementWidget – renders one element based on its type
// ---------------------------------------------------------------------------

class CanvasElementWidget extends StatelessWidget {
  final CanvasElement element;
  final List<CategoryEntity> categories;
  final List<MenuItemEntity> dishes;

  const CanvasElementWidget({
    super.key,
    required this.element,
    required this.categories,
    required this.dishes,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = switch (element.type) {
      'text' => _TextElement(element: element),
      'menuBlock' => _MenuBlockElement(
          element: element,
          categories: categories,
          dishes: dishes,
        ),
      'shape' => _ShapeElement(element: element),
      'divider' => _DividerElement(element: element),
      'image' => _ImageElement(element: element),
      _ => const SizedBox.shrink(),
    };

    return _applyAnimation(child, element);
  }
}

// ---------------------------------------------------------------------------
// Text element
// ---------------------------------------------------------------------------

class _TextElement extends StatelessWidget {
  final CanvasElement element;
  const _TextElement({required this.element});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: element.width,
      height: element.height,
      child: Text(
        element.text,
        textAlign: _parseAlign(element.textAlign),
        maxLines: (element.height / (element.fontSize * 1.4)).floor().clamp(1, 100),
        overflow: TextOverflow.clip,
        style: TextStyle(
          fontFamily: element.fontFamily,
          fontSize: element.fontSize,
          color: _hexToColor(element.color),
          fontWeight:
              element.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
          height: 1.3,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Menu block – auto-renders a category's dishes
// ---------------------------------------------------------------------------

class _MenuBlockElement extends StatelessWidget {
  final CanvasElement element;
  final List<CategoryEntity> categories;
  final List<MenuItemEntity> dishes;

  const _MenuBlockElement({
    required this.element,
    required this.categories,
    required this.dishes,
  });

  @override
  Widget build(BuildContext context) {
    final catId = element.categoryId;
    final category = catId != null
        ? categories.where((c) => c.id == catId).firstOrNull
        : null;
    final catDishes = catId != null
        ? dishes.where((d) => d.categoryId == catId && d.isAvailable).toList()
        : <MenuItemEntity>[];

    final titleStyle = TextStyle(
      fontFamily: element.fontFamily,
      fontSize: element.titleFontSize,
      fontWeight: FontWeight.bold,
      color: _hexToColor(element.titleColor),
      height: 1.3,
    );

    final itemStyle = TextStyle(
      fontFamily: element.fontFamily,
      fontSize: element.itemFontSize,
      color: _hexToColor(element.itemColor),
      height: 1.5,
    );

    final priceStyle = TextStyle(
      fontFamily: element.fontFamily,
      fontSize: element.itemFontSize,
      fontWeight: FontWeight.w600,
      color: _hexToColor(element.priceColor),
      height: 1.5,
    );

    if (category == null) {
      return Container(
        width: element.width,
        height: element.height,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          'Selecciona categoría',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return SizedBox(
      width: element.width,
      height: element.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category title
          Text(
            category.name.toUpperCase(),
            style: titleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Dishes
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: catDishes.length,
              itemBuilder: (_, i) {
                final dish = catDishes[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dish.name,
                              style: itemStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (element.showDescriptions &&
                                dish.description != null &&
                                dish.description!.isNotEmpty)
                              Text(
                                dish.description!,
                                style: itemStyle.copyWith(
                                  fontSize: element.itemFontSize - 2,
                                  color: _hexToColor(element.itemColor)
                                      .withValues(alpha: 0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      if (element.showPrices) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${dish.price.toStringAsFixed(2)} €',
                          style: priceStyle,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shape element
// ---------------------------------------------------------------------------

class _ShapeElement extends StatelessWidget {
  final CanvasElement element;
  const _ShapeElement({required this.element});

  @override
  Widget build(BuildContext context) {
    final fill = _hexToColor(element.fillColor);
    final stroke = _hexToColor(element.strokeColor);

    if (element.shapeType == 'circle') {
      return Container(
        width: element.width,
        height: element.height,
        decoration: BoxDecoration(
          color: fill.withValues(alpha: element.opacity),
          shape: BoxShape.circle,
          border: element.strokeWidth > 0
              ? Border.all(color: stroke, width: element.strokeWidth)
              : null,
        ),
      );
    }

    // Default rectangle
    return Container(
      width: element.width,
      height: element.height,
      decoration: BoxDecoration(
        color: fill.withValues(alpha: element.opacity),
        borderRadius: BorderRadius.circular(element.borderRadius),
        border: element.strokeWidth > 0
            ? Border.all(color: stroke, width: element.strokeWidth)
            : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Divider element
// ---------------------------------------------------------------------------

class _DividerElement extends StatelessWidget {
  final CanvasElement element;
  const _DividerElement({required this.element});

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(element.dividerColor);

    if (element.dividerStyle == 'dashed') {
      return CustomPaint(
        size: Size(element.width, element.thickness),
        painter: _DashedLinePainter(color: color, thickness: element.thickness),
      );
    }

    if (element.dividerStyle == 'dotted') {
      return CustomPaint(
        size: Size(element.width, element.thickness),
        painter: _DottedLinePainter(color: color, thickness: element.thickness),
      );
    }

    return Container(
      width: element.width,
      height: element.thickness.clamp(1, 20),
      color: color,
    );
  }
}

// ---------------------------------------------------------------------------
// Image element (placeholder until image upload is wired)
// ---------------------------------------------------------------------------

class _ImageElement extends StatelessWidget {
  final CanvasElement element;
  const _ImageElement({required this.element});

  @override
  Widget build(BuildContext context) {
    final url = element.imageUrl;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(element.borderRadius),
        child: Image.network(
          url,
          width: element.width,
          height: element.height,
          fit: BoxFit.cover,
          errorBuilder: (_, e, s) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: element.width,
      height: element.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Icon(Icons.image_outlined, color: Colors.grey[400], size: 28),
    );
  }
}

// ---------------------------------------------------------------------------
// Animation helper
// ---------------------------------------------------------------------------

Widget _applyAnimation(Widget child, CanvasElement element) {
  final anim = element.animation;
  if (anim == 'none' || anim.isEmpty) return child;

  final duration = Duration(milliseconds: element.animationDuration);
  final delay = Duration(milliseconds: element.animationDelay);
  final loop = element.animationLoop;

  // Key on animation config so it re-triggers when changed
  final animKey = ValueKey('${element.id}_${anim}_${element.animationDuration}_'
      '${element.animationDelay}_$loop');

  Animate animated;

  switch (anim) {
    case 'fadeIn':
      animated = child
          .animate(key: animKey, autoPlay: true)
          .fadeIn(duration: duration, delay: delay);
    case 'slideUp':
      animated = child
          .animate(key: animKey, autoPlay: true)
          .slideY(begin: 0.3, end: 0, duration: duration, delay: delay)
          .fadeIn(duration: duration, delay: delay);
    case 'slideDown':
      animated = child
          .animate(key: animKey, autoPlay: true)
          .slideY(begin: -0.3, end: 0, duration: duration, delay: delay)
          .fadeIn(duration: duration, delay: delay);
    case 'slideLeft':
      animated = child
          .animate(key: animKey, autoPlay: true)
          .slideX(begin: 0.3, end: 0, duration: duration, delay: delay)
          .fadeIn(duration: duration, delay: delay);
    case 'slideRight':
      animated = child
          .animate(key: animKey, autoPlay: true)
          .slideX(begin: -0.3, end: 0, duration: duration, delay: delay)
          .fadeIn(duration: duration, delay: delay);
    case 'scaleIn':
      animated = child
          .animate(key: animKey, autoPlay: true)
          .scale(
            begin: const Offset(0.5, 0.5),
            end: const Offset(1, 1),
            duration: duration,
            delay: delay,
            curve: Curves.elasticOut,
          )
          .fadeIn(duration: duration, delay: delay);
    case 'pulse':
      animated = child
          .animate(key: animKey, autoPlay: true, onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: duration,
            delay: delay,
          );
    case 'shake':
      animated = child
          .animate(key: animKey, autoPlay: true, onPlay: (c) => c.repeat())
          .shakeX(duration: duration, delay: delay, hz: 3, amount: 3);
    case 'bounce':
      animated = child
          .animate(key: animKey, autoPlay: true)
          .scale(
            begin: const Offset(0, 0),
            end: const Offset(1, 1),
            duration: duration,
            delay: delay,
            curve: Curves.bounceOut,
          );
    case 'flip':
      animated = child
          .animate(key: animKey, autoPlay: true)
          .flipH(
            begin: 1,
            end: 0,
            duration: duration,
            delay: delay,
            curve: Curves.easeInOut,
          )
          .fadeIn(duration: duration, delay: delay);
    default:
      return child;
  }

  // For pulse & shake, loop is implicit. For others, optionally loop.
  if (loop && anim != 'pulse' && anim != 'shake') {
    animated = animated.then().fadeOut(duration: 200.ms).then().callback(
        callback: (_) {}); // flutter_animate handles repeat via onPlay
  }

  return animated;
}

// ---------------------------------------------------------------------------
// Custom painters for line styles
// ---------------------------------------------------------------------------

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double thickness;
  _DashedLinePainter({required this.color, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;
    const dashW = 8.0;
    const gapW = 4.0;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + dashW).clamp(0, size.width), y),
        paint,
      );
      x += dashW + gapW;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DottedLinePainter extends CustomPainter {
  final Color color;
  final double thickness;
  _DottedLinePainter({required this.color, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    double x = 0;
    final y = size.height / 2;
    final r = thickness / 2;
    while (x < size.width) {
      canvas.drawCircle(Offset(x + r, y), r, paint);
      x += thickness * 3;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Shared hex → Color
// ---------------------------------------------------------------------------

TextAlign _parseAlign(String a) => switch (a) {
  'left' => TextAlign.left,
  'right' => TextAlign.right,
  'center' => TextAlign.center,
  _ => TextAlign.left,
};

Color _hexToColor(String hex) {
  final h = hex.replaceFirst('#', '');
  if (h == 'transparent' || hex == 'transparent') return Colors.transparent;
  if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
  if (h.length == 8) return Color(int.parse(h, radix: 16));
  return Colors.black;
}
