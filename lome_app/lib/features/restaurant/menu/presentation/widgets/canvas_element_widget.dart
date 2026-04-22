import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
      'carousel' => _CarouselElement(element: element, dishes: dishes),
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
        maxLines: (element.height / (element.fontSize * 1.4)).floor().clamp(
          1,
          100,
        ),
        overflow: TextOverflow.clip,
        style: _fontStyle(
          element.fontFamily,
          TextStyle(
          fontSize: element.fontSize,
          color: _hexToColor(element.color),
          fontWeight: element.fontWeight == 'bold'
              ? FontWeight.bold
              : FontWeight.normal,
          height: 1.3,
          ),
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

    final titleStyle = _fontStyle(
  TextStyle _fontStyle(String family, TextStyle base) {
    try {
      return GoogleFonts.getFont(family, textStyle: base);
    } catch (_) {
      return base.copyWith(fontFamily: family);
    }
  }
      element.fontFamily,
      TextStyle(
        fontSize: element.titleFontSize,
        fontWeight: FontWeight.bold,
        color: _hexToColor(element.titleColor),
        height: 1.3,
      ),
    );

    final itemStyle = _fontStyle(
      element.fontFamily,
      TextStyle(
        fontSize: element.itemFontSize,
        color: _hexToColor(element.itemColor),
        height: 1.5,
      ),
    );

    final priceStyle = _fontStyle(
      element.fontFamily,
      TextStyle(
        fontSize: element.itemFontSize,
        fontWeight: FontWeight.w600,
        color: _hexToColor(element.priceColor),
        height: 1.5,
      ),
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
                                  color: _hexToColor(
                                    element.itemColor,
                                  ).withValues(alpha: 0.7),
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
// Image element
// ---------------------------------------------------------------------------

class _ImageElement extends StatelessWidget {
  final CanvasElement element;
  const _ImageElement({required this.element});

  bool get _isLocalPath {
    final url = element.imageUrl;
    if (url == null || url.isEmpty) return false;
    return !url.startsWith('http');
  }

  @override
  Widget build(BuildContext context) {
    final url = element.imageUrl;

    if (url != null && url.isNotEmpty) {
      Widget imageWidget;

      if (_isLocalPath && !kIsWeb) {
        imageWidget = Image.file(
          File(url),
          width: element.width,
          height: element.height,
          fit: BoxFit.cover,
          errorBuilder: (_, e, s) => _placeholder(),
        );
      } else if (url.startsWith('http')) {
        imageWidget = Image.network(
          url,
          width: element.width,
          height: element.height,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : Container(
                  width: element.width,
                  height: element.height,
                  color: Colors.grey[100],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
          errorBuilder: (_, e, s) => _placeholder(),
        );
      } else {
        return _placeholder();
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(element.borderRadius),
        child: Opacity(
          opacity: element.opacity.clamp(0.0, 1.0),
          child: imageWidget,
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
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(element.borderRadius.clamp(0, 50)),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.image(PhosphorIconsStyle.duotone),
            color: Colors.grey[400],
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            'Toca para cambiar',
            style: TextStyle(color: Colors.grey[400], fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carousel element – cycles through featured dishes
// ---------------------------------------------------------------------------

class _CarouselElement extends StatefulWidget {
  final CanvasElement element;
  final List<MenuItemEntity> dishes;

  const _CarouselElement({required this.element, required this.dishes});

  @override
  State<_CarouselElement> createState() => _CarouselElementState();
}

class _CarouselElementState extends State<_CarouselElement> {
  late Timer _timer;
  int _currentIndex = 0;

  List<MenuItemEntity> get _filteredDishes {
    final catId = widget.element.categoryId;
    if (catId != null && catId.isNotEmpty) {
      return widget.dishes
          .where((d) => d.categoryId == catId && d.isAvailable)
          .toList();
    }
    return widget.dishes.where((d) => d.isAvailable).toList();
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    final ms = widget.element.displayDuration;
    _timer = Timer.periodic(Duration(milliseconds: ms), (_) {
      final items = _filteredDishes;
      if (items.isNotEmpty) {
        setState(() => _currentIndex = (_currentIndex + 1) % items.length);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _CarouselElement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element.displayDuration != widget.element.displayDuration) {
      _timer.cancel();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredDishes;
    if (items.isEmpty) {
      return Container(
        width: widget.element.width,
        height: widget.element.height,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(widget.element.borderRadius),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.slideshow(PhosphorIconsStyle.duotone),
              color: Colors.grey[400],
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              'Sin platos disponibles',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      );
    }

    final item = items[_currentIndex % items.length];
    final bgColor = _hexToColor(
      widget.element.props['backgroundColor'] as String? ?? '#FFFFFF',
    );
    final txtColor = _hexToColor(widget.element.textColor);
    final prColor = _hexToColor(widget.element.priceColor);
    final fSize = widget.element.fontSize;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, anim) => SlideTransition(
        position: Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: Container(
        key: ValueKey(item.id),
        width: widget.element.width,
        height: widget.element.height,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(widget.element.borderRadius),
          border: Border.all(color: txtColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Star badge
            Row(
              children: [
                Icon(
                  PhosphorIcons.star(PhosphorIconsStyle.fill),
                  size: 14,
                  color: const Color(0xFFF39C12),
                ),
                const SizedBox(width: 4),
                Text(
                  'DESTACADO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: txtColor.withValues(alpha: 0.5),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.name,
              style: TextStyle(
                fontSize: fSize,
                fontWeight: FontWeight.bold,
                color: txtColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.element.showDescriptions &&
                item.description != null &&
                item.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  item.description!,
                  style: TextStyle(
                    fontSize: fSize - 3,
                    color: txtColor.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (widget.element.showPrices)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${item.price.toStringAsFixed(2)} €',
                  style: TextStyle(
                    fontSize: fSize + 2,
                    fontWeight: FontWeight.w700,
                    color: prColor,
                  ),
                ),
              ),
            const Spacer(),
            // Page indicator dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                items.length.clamp(0, 10),
                (i) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _currentIndex % items.length
                        ? txtColor
                        : txtColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
  final animKey = ValueKey(
    '${element.id}_${anim}_${element.animationDuration}_'
    '${element.animationDelay}_$loop',
  );

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
          .animate(
            key: animKey,
            autoPlay: true,
            onPlay: (c) => c.repeat(reverse: true),
          )
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
    animated = animated
        .then()
        .fadeOut(duration: 200.ms)
        .then()
        .callback(
          callback: (_) {},
        ); // flutter_animate handles repeat via onPlay
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
