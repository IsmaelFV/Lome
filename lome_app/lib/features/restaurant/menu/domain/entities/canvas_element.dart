import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Virtual A4 canvas dimensions (72 DPI PDF points).
const double kCanvasWidth = 595;
const double kCanvasHeight = 842;

// ---------------------------------------------------------------------------
// CanvasElement – single element on the menu card canvas
// ---------------------------------------------------------------------------

class CanvasElement {
  final String id;
  final String type; // text, menuBlock, shape, divider, image
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final int zIndex;
  final bool locked;
  final Map<String, dynamic> props;

  const CanvasElement({
    required this.id,
    required this.type,
    this.x = 0,
    this.y = 0,
    this.width = 100,
    this.height = 50,
    this.rotation = 0,
    this.zIndex = 0,
    this.locked = false,
    this.props = const {},
  });

  // ---- Factory constructors ------------------------------------------------

  factory CanvasElement.text({
    double x = 0,
    double y = 0,
    double width = 200,
    double height = 40,
    String text = 'Texto',
    String fontFamily = 'Poppins',
    double fontSize = 16,
    String color = '#2D3436',
    String fontWeight = 'normal',
    String textAlign = 'center',
    int zIndex = 0,
  }) {
    return CanvasElement(
      id: _uuid.v4(),
      type: 'text',
      x: x,
      y: y,
      width: width,
      height: height,
      zIndex: zIndex,
      props: {
        'text': text,
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'color': color,
        'fontWeight': fontWeight,
        'textAlign': textAlign,
      },
    );
  }

  factory CanvasElement.menuBlock({
    required String categoryId,
    double x = 0,
    double y = 0,
    double width = 250,
    double height = 200,
    String titleColor = '#2D3436',
    String itemColor = '#636E72',
    String priceColor = '#27AE60',
    double titleFontSize = 18,
    double itemFontSize = 13,
    String fontFamily = 'Poppins',
    bool showPrices = true,
    bool showDescriptions = false,
    int zIndex = 0,
  }) {
    return CanvasElement(
      id: _uuid.v4(),
      type: 'menuBlock',
      x: x,
      y: y,
      width: width,
      height: height,
      zIndex: zIndex,
      props: {
        'categoryId': categoryId,
        'titleColor': titleColor,
        'itemColor': itemColor,
        'priceColor': priceColor,
        'titleFontSize': titleFontSize,
        'itemFontSize': itemFontSize,
        'fontFamily': fontFamily,
        'showPrices': showPrices,
        'showDescriptions': showDescriptions,
      },
    );
  }

  factory CanvasElement.shape({
    double x = 0,
    double y = 0,
    double width = 100,
    double height = 100,
    String shapeType = 'rect',
    String fillColor = '#FFFFFF',
    String strokeColor = '#2D3436',
    double strokeWidth = 1,
    double borderRadius = 0,
    double opacity = 1,
    int zIndex = 0,
  }) {
    return CanvasElement(
      id: _uuid.v4(),
      type: 'shape',
      x: x,
      y: y,
      width: width,
      height: height,
      zIndex: zIndex,
      props: {
        'shapeType': shapeType,
        'fillColor': fillColor,
        'strokeColor': strokeColor,
        'strokeWidth': strokeWidth,
        'borderRadius': borderRadius,
        'opacity': opacity,
      },
    );
  }

  factory CanvasElement.divider({
    double x = 0,
    double y = 0,
    double width = 400,
    double thickness = 1,
    String color = '#DFE6E9',
    String style = 'solid', // solid, dashed, dotted
    int zIndex = 0,
  }) {
    return CanvasElement(
      id: _uuid.v4(),
      type: 'divider',
      x: x,
      y: y,
      width: width,
      height: thickness,
      zIndex: zIndex,
      props: {'color': color, 'thickness': thickness, 'style': style},
    );
  }

  factory CanvasElement.image({
    double x = 0,
    double y = 0,
    double width = 200,
    double height = 150,
    String? imageUrl,
    double borderRadius = 0,
    double opacity = 1,
    int zIndex = 0,
  }) {
    return CanvasElement(
      id: _uuid.v4(),
      type: 'image',
      x: x,
      y: y,
      width: width,
      height: height,
      zIndex: zIndex,
      props: {
        'imageUrl': imageUrl,
        'borderRadius': borderRadius,
        'opacity': opacity,
      },
    );
  }

  factory CanvasElement.carousel({
    double x = 0,
    double y = 0,
    double width = 400,
    double height = 150,
    String? categoryId,
    int displayDuration = 3000,
    String backgroundColor = '#FFFFFF',
    String textColor = '#2D3436',
    String priceColor = '#27AE60',
    double fontSize = 16,
    bool showPrices = true,
    bool showDescriptions = false,
    double borderRadius = 8,
    int zIndex = 0,
  }) {
    return CanvasElement(
      id: _uuid.v4(),
      type: 'carousel',
      x: x,
      y: y,
      width: width,
      height: height,
      zIndex: zIndex,
      props: {
        'categoryId': categoryId,
        'displayDuration': displayDuration,
        'backgroundColor': backgroundColor,
        'textColor': textColor,
        'priceColor': priceColor,
        'fontSize': fontSize,
        'showPrices': showPrices,
        'showDescriptions': showDescriptions,
        'borderRadius': borderRadius,
      },
    );
  }

  // ---- Serialization -------------------------------------------------------

  factory CanvasElement.fromJson(Map<String, dynamic> json) {
    return CanvasElement(
      id: json['id'] as String,
      type: json['type'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      zIndex: json['zIndex'] as int? ?? 0,
      locked: json['locked'] as bool? ?? false,
      props: Map<String, dynamic>.from(json['props'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'rotation': rotation,
    'zIndex': zIndex,
    'locked': locked,
    'props': props,
  };

  // ---- Copy helpers --------------------------------------------------------

  CanvasElement copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    int? zIndex,
    bool? locked,
    Map<String, dynamic>? props,
  }) {
    return CanvasElement(
      id: id,
      type: type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      locked: locked ?? this.locked,
      props: props ?? Map<String, dynamic>.from(this.props),
    );
  }

  CanvasElement withProp(String key, dynamic value) {
    final p = Map<String, dynamic>.from(props);
    p[key] = value;
    return copyWith(props: p);
  }

  CanvasElement withProps(Map<String, dynamic> updates) {
    final p = Map<String, dynamic>.from(props);
    p.addAll(updates);
    return copyWith(props: p);
  }

  // ---- Convenience getters -------------------------------------------------

  String get text => props['text'] as String? ?? '';
  String get fontFamily => props['fontFamily'] as String? ?? 'Poppins';
  double get fontSize => (props['fontSize'] as num?)?.toDouble() ?? 16;
  String get color => props['color'] as String? ?? '#2D3436';
  String get fontWeight => props['fontWeight'] as String? ?? 'normal';
  String get textAlign => props['textAlign'] as String? ?? 'left';

  String? get categoryId => props['categoryId'] as String?;
  String get titleColor => props['titleColor'] as String? ?? '#2D3436';
  String get itemColor => props['itemColor'] as String? ?? '#636E72';
  String get priceColor => props['priceColor'] as String? ?? '#27AE60';
  double get titleFontSize =>
      (props['titleFontSize'] as num?)?.toDouble() ?? 18;
  double get itemFontSize => (props['itemFontSize'] as num?)?.toDouble() ?? 13;
  bool get showPrices => props['showPrices'] as bool? ?? true;
  bool get showDescriptions => props['showDescriptions'] as bool? ?? false;

  String get shapeType => props['shapeType'] as String? ?? 'rect';
  String get fillColor => props['fillColor'] as String? ?? '#FFFFFF';
  String get strokeColor => props['strokeColor'] as String? ?? '#2D3436';
  double get strokeWidth => (props['strokeWidth'] as num?)?.toDouble() ?? 1;
  double get borderRadius => (props['borderRadius'] as num?)?.toDouble() ?? 0;
  double get opacity => (props['opacity'] as num?)?.toDouble() ?? 1;

  String get dividerColor => props['color'] as String? ?? '#DFE6E9';
  double get thickness => (props['thickness'] as num?)?.toDouble() ?? 1;
  String get dividerStyle => props['style'] as String? ?? 'solid';

  String? get imageUrl => props['imageUrl'] as String?;

  // Animation props
  String get animation => props['animation'] as String? ?? 'none';
  int get animationDuration =>
      (props['animationDuration'] as num?)?.toInt() ?? 500;
  int get animationDelay => (props['animationDelay'] as num?)?.toInt() ?? 0;
  bool get animationLoop => props['animationLoop'] as bool? ?? false;

  // Carousel props
  int get displayDuration =>
      (props['displayDuration'] as num?)?.toInt() ?? 3000;
  String get textColor => props['textColor'] as String? ?? '#2D3436';
}
