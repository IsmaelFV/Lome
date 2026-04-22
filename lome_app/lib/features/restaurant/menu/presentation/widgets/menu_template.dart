import '../../domain/entities/canvas_element.dart';
import '../../domain/entities/menu_item_entity.dart';

// ---------------------------------------------------------------------------
// MenuTemplate – pre-designed base layouts for the card editor
// ---------------------------------------------------------------------------

class MenuTemplate {
  final String id;
  final String name;
  final String description;
  final String backgroundColor;
  final String primaryColor;
  final String secondaryColor;
  final String accentColor;
  final String fontFamily;
  final String headerFontFamily;

  const MenuTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.backgroundColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.fontFamily,
    required this.headerFontFamily,
  });

  static const templates = [
    classica,
    moderna,
    elegante,
    minimalista,
    rustica,
    noche,
    mediterranea,
    cafe,
    tropical,
  ];

  // ---- Built-in templates --------------------------------------------------

  static const classica = MenuTemplate(
    id: 'classica',
    name: 'Clásica',
    description: 'Diseño tradicional con tipografía serif y líneas decorativas',
    backgroundColor: '#FFF8F0',
    primaryColor: '#8B1A1A',
    secondaryColor: '#2D3436',
    accentColor: '#B8860B',
    fontFamily: 'Lato',
    headerFontFamily: 'Playfair Display',
  );

  static const moderna = MenuTemplate(
    id: 'moderna',
    name: 'Moderna',
    description: 'Limpio y minimalista con acentos de color vivos',
    backgroundColor: '#FFFFFF',
    primaryColor: '#008080',
    secondaryColor: '#2D3436',
    accentColor: '#FF6B35',
    fontFamily: 'Inter',
    headerFontFamily: 'Montserrat',
  );

  static const elegante = MenuTemplate(
    id: 'elegante',
    name: 'Elegante',
    description: 'Fondo oscuro con detalles dorados para restaurantes premium',
    backgroundColor: '#1A1A2E',
    primaryColor: '#D4AF37',
    secondaryColor: '#F5F5F5',
    accentColor: '#C0A36E',
    fontFamily: 'Raleway',
    headerFontFamily: 'Playfair Display',
  );

  static const minimalista = MenuTemplate(
    id: 'minimalista',
    name: 'Minimalista',
    description: 'Diseño limpio con mucho espacio y tipografía sans-serif',
    backgroundColor: '#FFFFFF',
    primaryColor: '#111111',
    secondaryColor: '#555555',
    accentColor: '#999999',
    fontFamily: 'Inter',
    headerFontFamily: 'Inter',
  );

  static const rustica = MenuTemplate(
    id: 'rustica',
    name: 'Rústica',
    description: 'Tonos cálidos y terrosos, ideal para cocina artesanal',
    backgroundColor: '#F5E6D3',
    primaryColor: '#5D4037',
    secondaryColor: '#3E2723',
    accentColor: '#8D6E63',
    fontFamily: 'Nunito',
    headerFontFamily: 'Merriweather',
  );

  static const noche = MenuTemplate(
    id: 'noche',
    name: 'Noche',
    description:
        'Fondo negro profundo con neón azul, perfecto para bares y cocktails',
    backgroundColor: '#0A0A0F',
    primaryColor: '#00D4FF',
    secondaryColor: '#E0E0E0',
    accentColor: '#7B61FF',
    fontFamily: 'Raleway',
    headerFontFamily: 'Montserrat',
  );

  static const mediterranea = MenuTemplate(
    id: 'mediterranea',
    name: 'Mediterránea',
    description: 'Blanco y azul mar con detalles en oliva, evoca la costa',
    backgroundColor: '#F7F9FC',
    primaryColor: '#1565C0',
    secondaryColor: '#37474F',
    accentColor: '#558B2F',
    fontFamily: 'Lato',
    headerFontFamily: 'Playfair Display',
  );

  static const cafe = MenuTemplate(
    id: 'cafe',
    name: 'Café',
    description: 'Tonos espresso y crema, tipografía limpia para cafeterías',
    backgroundColor: '#F9F5F0',
    primaryColor: '#3E2723',
    secondaryColor: '#5D4037',
    accentColor: '#FF8F00',
    fontFamily: 'Nunito',
    headerFontFamily: 'Merriweather',
  );

  static const tropical = MenuTemplate(
    id: 'tropical',
    name: 'Tropical',
    description:
        'Colores vibrantes de playa, ideal para bares de playa y chiringuitos',
    backgroundColor: '#FFFFFF',
    primaryColor: '#00897B',
    secondaryColor: '#1A237E',
    accentColor: '#FF7043',
    fontFamily: 'Nunito',
    headerFontFamily: 'Montserrat',
  );
}

// ---------------------------------------------------------------------------
// Template element generation
// ---------------------------------------------------------------------------

List<CanvasElement> generateTemplateElements({
  required MenuTemplate template,
  required List<CategoryEntity> categories,
  required List<MenuItemEntity> dishes,
  String restaurantName = 'Mi Restaurante',
}) {
  switch (template.id) {
    case 'classica':
      return _generateClassica(template, categories, dishes, restaurantName);
    case 'moderna':
      return _generateModerna(template, categories, dishes, restaurantName);
    case 'elegante':
      return _generateElegante(template, categories, dishes, restaurantName);
    case 'minimalista':
      return _generateMinimalista(template, categories, dishes, restaurantName);
    case 'rustica':
      return _generateRustica(template, categories, dishes, restaurantName);
    case 'noche':
      return _generateNoche(template, categories, dishes, restaurantName);
    case 'mediterranea':
      return _generateMediterranea(
        template,
        categories,
        dishes,
        restaurantName,
      );
    case 'cafe':
      return _generateCafe(template, categories, dishes, restaurantName);
    case 'tropical':
      return _generateTropical(template, categories, dishes, restaurantName);
    default:
      return _generateClassica(template, categories, dishes, restaurantName);
  }
}

// ---- Clásica ---------------------------------------------------------------

List<CanvasElement> _generateClassica(
  MenuTemplate t,
  List<CategoryEntity> categories,
  List<MenuItemEntity> dishes,
  String name,
) {
  final elements = <CanvasElement>[];
  int z = 0;

  // Background frame
  elements.add(
    CanvasElement.shape(
      x: 20,
      y: 20,
      width: kCanvasWidth - 40,
      height: kCanvasHeight - 40,
      fillColor: 'transparent',
      strokeColor: t.primaryColor,
      strokeWidth: 2,
      borderRadius: 0,
      zIndex: z++,
    ),
  );

  // Top decorative line
  elements.add(
    CanvasElement.divider(
      x: 100,
      y: 70,
      width: kCanvasWidth - 200,
      color: t.accentColor,
      thickness: 2,
      zIndex: z++,
    ),
  );

  // Restaurant name
  elements.add(
    CanvasElement.text(
      x: 50,
      y: 85,
      width: kCanvasWidth - 100,
      height: 50,
      text: name.toUpperCase(),
      fontFamily: t.headerFontFamily,
      fontSize: 32,
      color: t.primaryColor,
      fontWeight: 'bold',
      textAlign: 'center',
      zIndex: z++,
    ),
  );

  // Subtitle
  elements.add(
    CanvasElement.text(
      x: 100,
      y: 140,
      width: kCanvasWidth - 200,
      height: 25,
      text: 'Nuestra Carta',
      fontFamily: t.fontFamily,
      fontSize: 14,
      color: t.secondaryColor,
      fontWeight: 'normal',
      textAlign: 'center',
      zIndex: z++,
    ),
  );

  // Bottom decorative line
  elements.add(
    CanvasElement.divider(
      x: 100,
      y: 170,
      width: kCanvasWidth - 200,
      color: t.accentColor,
      thickness: 2,
      zIndex: z++,
    ),
  );

  // Category blocks
  final blocks = _layoutCategoryBlocks(
    categories: categories,
    dishes: dishes,
    startY: 200,
    leftMargin: 50,
    contentWidth: kCanvasWidth - 100,
    titleColor: t.primaryColor,
    itemColor: t.secondaryColor,
    priceColor: t.accentColor,
    fontFamily: t.fontFamily,
    titleFontSize: 18,
    itemFontSize: 12,
    startZIndex: z,
  );
  elements.addAll(blocks);

  return elements;
}

// ---- Moderna ---------------------------------------------------------------

List<CanvasElement> _generateModerna(
  MenuTemplate t,
  List<CategoryEntity> categories,
  List<MenuItemEntity> dishes,
  String name,
) {
  final elements = <CanvasElement>[];
  int z = 0;

  // Accent bar at top
  elements.add(
    CanvasElement.shape(
      x: 0,
      y: 0,
      width: kCanvasWidth,
      height: 8,
      fillColor: t.accentColor,
      strokeColor: 'transparent',
      strokeWidth: 0,
      zIndex: z++,
    ),
  );

  // Restaurant name
  elements.add(
    CanvasElement.text(
      x: 40,
      y: 30,
      width: kCanvasWidth - 80,
      height: 45,
      text: name,
      fontFamily: t.headerFontFamily,
      fontSize: 28,
      color: t.secondaryColor,
      fontWeight: 'bold',
      textAlign: 'left',
      zIndex: z++,
    ),
  );

  // Thin divider
  elements.add(
    CanvasElement.divider(
      x: 40,
      y: 85,
      width: 80,
      color: t.primaryColor,
      thickness: 3,
      zIndex: z++,
    ),
  );

  // Subtitle
  elements.add(
    CanvasElement.text(
      x: 40,
      y: 100,
      width: kCanvasWidth - 80,
      height: 22,
      text: 'Menú del día',
      fontFamily: t.fontFamily,
      fontSize: 13,
      color: t.primaryColor,
      fontWeight: 'normal',
      textAlign: 'left',
      zIndex: z++,
    ),
  );

  // Category blocks in two columns if ≥4 categories
  if (categories.length >= 4) {
    final halfW = (kCanvasWidth - 100) / 2;
    final left = categories.sublist(0, (categories.length / 2).ceil());
    final right = categories.sublist(left.length);

    elements.addAll(
      _layoutCategoryBlocks(
        categories: left,
        dishes: dishes,
        startY: 145,
        leftMargin: 40,
        contentWidth: halfW,
        titleColor: t.primaryColor,
        itemColor: t.secondaryColor,
        priceColor: t.accentColor,
        fontFamily: t.fontFamily,
        titleFontSize: 16,
        itemFontSize: 11,
        startZIndex: z,
      ),
    );
    z += left.length;

    elements.addAll(
      _layoutCategoryBlocks(
        categories: right,
        dishes: dishes,
        startY: 145,
        leftMargin: 40 + halfW + 20,
        contentWidth: halfW,
        titleColor: t.primaryColor,
        itemColor: t.secondaryColor,
        priceColor: t.accentColor,
        fontFamily: t.fontFamily,
        titleFontSize: 16,
        itemFontSize: 11,
        startZIndex: z,
      ),
    );
  } else {
    elements.addAll(
      _layoutCategoryBlocks(
        categories: categories,
        dishes: dishes,
        startY: 145,
        leftMargin: 40,
        contentWidth: kCanvasWidth - 80,
        titleColor: t.primaryColor,
        itemColor: t.secondaryColor,
        priceColor: t.accentColor,
        fontFamily: t.fontFamily,
        titleFontSize: 16,
        itemFontSize: 11,
        startZIndex: z,
      ),
    );
  }

  return elements;
}

// ---- Elegante --------------------------------------------------------------

List<CanvasElement> _generateElegante(
  MenuTemplate t,
  List<CategoryEntity> categories,
  List<MenuItemEntity> dishes,
  String name,
) {
  final elements = <CanvasElement>[];
  int z = 0;

  // Full background shape (dark)
  elements.add(
    CanvasElement.shape(
      x: 0,
      y: 0,
      width: kCanvasWidth,
      height: kCanvasHeight,
      fillColor: t.backgroundColor,
      strokeColor: 'transparent',
      strokeWidth: 0,
      zIndex: z++,
    ),
  );

  // Gold inner frame
  elements.add(
    CanvasElement.shape(
      x: 30,
      y: 30,
      width: kCanvasWidth - 60,
      height: kCanvasHeight - 60,
      fillColor: 'transparent',
      strokeColor: t.primaryColor,
      strokeWidth: 1.5,
      borderRadius: 0,
      zIndex: z++,
    ),
  );

  // Decorative line top
  elements.add(
    CanvasElement.divider(
      x: 150,
      y: 80,
      width: kCanvasWidth - 300,
      color: t.primaryColor,
      thickness: 1,
      zIndex: z++,
    ),
  );

  // Restaurant name
  elements.add(
    CanvasElement.text(
      x: 50,
      y: 95,
      width: kCanvasWidth - 100,
      height: 50,
      text: name.toUpperCase(),
      fontFamily: t.headerFontFamily,
      fontSize: 30,
      color: t.primaryColor,
      fontWeight: 'bold',
      textAlign: 'center',
      zIndex: z++,
    ),
  );

  // Subtitle
  elements.add(
    CanvasElement.text(
      x: 100,
      y: 150,
      width: kCanvasWidth - 200,
      height: 22,
      text: '— Carta —',
      fontFamily: t.fontFamily,
      fontSize: 13,
      color: t.accentColor,
      fontWeight: 'normal',
      textAlign: 'center',
      zIndex: z++,
    ),
  );

  // Decorative line bottom of header
  elements.add(
    CanvasElement.divider(
      x: 150,
      y: 180,
      width: kCanvasWidth - 300,
      color: t.primaryColor,
      thickness: 1,
      zIndex: z++,
    ),
  );

  // Category blocks
  elements.addAll(
    _layoutCategoryBlocks(
      categories: categories,
      dishes: dishes,
      startY: 210,
      leftMargin: 60,
      contentWidth: kCanvasWidth - 120,
      titleColor: t.primaryColor,
      itemColor: t.secondaryColor,
      priceColor: t.accentColor,
      fontFamily: t.fontFamily,
      titleFontSize: 17,
      itemFontSize: 12,
      startZIndex: z,
    ),
  );

  return elements;
}

// ---- Minimalista -----------------------------------------------------------

List<CanvasElement> _generateMinimalista(
  MenuTemplate t,
  List<CategoryEntity> categories,
  List<MenuItemEntity> dishes,
  String name,
) {
  final elements = <CanvasElement>[];
  int z = 0;

  // Restaurant name
  elements.add(
    CanvasElement.text(
      x: 60,
      y: 60,
      width: kCanvasWidth - 120,
      height: 40,
      text: name,
      fontFamily: t.headerFontFamily,
      fontSize: 24,
      color: t.primaryColor,
      fontWeight: 'bold',
      textAlign: 'center',
      zIndex: z++,
    ),
  );

  // Simple line
  elements.add(
    CanvasElement.divider(
      x: (kCanvasWidth - 60) / 2,
      y: 110,
      width: 60,
      color: t.primaryColor,
      thickness: 2,
      zIndex: z++,
    ),
  );

  // Category blocks with generous spacing
  elements.addAll(
    _layoutCategoryBlocks(
      categories: categories,
      dishes: dishes,
      startY: 140,
      leftMargin: 60,
      contentWidth: kCanvasWidth - 120,
      titleColor: t.primaryColor,
      itemColor: t.secondaryColor,
      priceColor: t.accentColor,
      fontFamily: t.fontFamily,
      titleFontSize: 15,
      itemFontSize: 12,
      startZIndex: z,
      spacing: 30,
    ),
  );

  return elements;
}

// ---- Rústica ---------------------------------------------------------------

List<CanvasElement> _generateRustica(
  MenuTemplate t,
  List<CategoryEntity> categories,
  List<MenuItemEntity> dishes,
  String name,
) {
  final elements = <CanvasElement>[];
  int z = 0;

  // Background texture shape
  elements.add(
    CanvasElement.shape(
      x: 0,
      y: 0,
      width: kCanvasWidth,
      height: kCanvasHeight,
      fillColor: t.backgroundColor,
      strokeColor: 'transparent',
      strokeWidth: 0,
      zIndex: z++,
    ),
  );

  // Rustic frame
  elements.add(
    CanvasElement.shape(
      x: 25,
      y: 25,
      width: kCanvasWidth - 50,
      height: kCanvasHeight - 50,
      fillColor: 'transparent',
      strokeColor: t.primaryColor,
      strokeWidth: 3,
      borderRadius: 8,
      zIndex: z++,
    ),
  );

  // Inner frame
  elements.add(
    CanvasElement.shape(
      x: 30,
      y: 30,
      width: kCanvasWidth - 60,
      height: kCanvasHeight - 60,
      fillColor: 'transparent',
      strokeColor: t.primaryColor,
      strokeWidth: 1,
      borderRadius: 6,
      zIndex: z++,
    ),
  );

  // Restaurant name
  elements.add(
    CanvasElement.text(
      x: 50,
      y: 60,
      width: kCanvasWidth - 100,
      height: 50,
      text: name,
      fontFamily: t.headerFontFamily,
      fontSize: 28,
      color: t.primaryColor,
      fontWeight: 'bold',
      textAlign: 'center',
      zIndex: z++,
    ),
  );

  // Decorative dots divider
  elements.add(
    CanvasElement.text(
      x: 100,
      y: 115,
      width: kCanvasWidth - 200,
      height: 20,
      text: '• • •',
      fontFamily: t.fontFamily,
      fontSize: 14,
      color: t.accentColor,
      fontWeight: 'normal',
      textAlign: 'center',
      zIndex: z++,
    ),
  );

  // Subtitle
  elements.add(
    CanvasElement.text(
      x: 100,
      y: 140,
      width: kCanvasWidth - 200,
      height: 22,
      text: 'Cocina artesanal',
      fontFamily: t.fontFamily,
      fontSize: 13,
      color: t.accentColor,
      fontWeight: 'normal',
      textAlign: 'center',
      zIndex: z++,
    ),
  );

  // Category blocks
  elements.addAll(
    _layoutCategoryBlocks(
      categories: categories,
      dishes: dishes,
      startY: 185,
      leftMargin: 55,
      contentWidth: kCanvasWidth - 110,
      titleColor: t.primaryColor,
      itemColor: t.secondaryColor,
      priceColor: t.accentColor,
      fontFamily: t.fontFamily,
      titleFontSize: 17,
      itemFontSize: 12,
      startZIndex: z,
    ),
  );

  return elements;
}

// ---- Noche -----------------------------------------------------------------

List<CanvasElement> _generateNoche(
  MenuTemplate t,
  List<CategoryEntity> categories,
  List<MenuItemEntity> dishes,
  String name,
) {
  final elements = <CanvasElement>[];
  int z = 0;

  // Dark bg
  elements.add(
    CanvasElement.shape(
      x: 0,
      y: 0,
      width: kCanvasWidth,
      height: kCanvasHeight,
      fillColor: t.backgroundColor,
      strokeColor: 'transparent',
      strokeWidth: 0,
      zIndex: z++,
    ),
  );

  // Accent side bar
  elements.add(
    CanvasElement.shape(
      x: 0,
      y: 0,
      width: 6,
      height: kCanvasHeight,
      fillColor: t.primaryColor,
      strokeColor: 'transparent',
      strokeWidth: 0,
      zIndex: z++,
    ),
  );
  elements.add(
    CanvasElement.shape(
      x: kCanvasWidth - 6,
      y: 0,
      width: 6,
      height: kCanvasHeight,
      fillColor: t.accentColor,
      strokeColor: 'transparent',
      strokeWidth: 0,
      zIndex: z++,
    ),
  );

  // Restaurant name with neon glow effect (bold + large)
  elements.add(
    CanvasElement.text(
      x: 30,
      y: 60,
      width: kCanvasWidth - 60,
      height: 55,
      text: name.toUpperCase(),
      fontFamily: t.headerFontFamily,
      fontSize: 34,
      color: t.primaryColor,
      fontWeight: 'bold',
      textAlign: 'center',
      zIndex: z++,
    ),
  );

  // Thin divider
  elements.add(
    CanvasElement.divider(
      x: 60,
      y: 125,
      width: kCanvasWidth - 120,
      color: t.accentColor,
      thickness: 1,
      zIndex: z++,
    ),
  );

  // Tagline
  elements.add(
    CanvasElement.text(
      x: 60,
      y: 135,
      width: kCanvasWidth - 120,
      height: 22,
      text: 'CARTA DE BEBIDAS & COCTELERÍA',
      fontFamily: t.fontFamily,
      fontSize: 10,
      color: t.accentColor,
      fontWeight: 'normal',
      textAlign: 'center',
      zIndex: z++,
    ),
  );

  // Category blocks
  elements.addAll(
    _layoutCategoryBlocks(
      categories: categories,
      dishes: dishes,
      startY: 175,
      leftMargin: 30,
      contentWidth: kCanvasWidth - 60,
      titleColor: t.primaryColor,
      itemColor: t.secondaryColor,
      priceColor: t.accentColor,
      fontFamily: t.fontFamily,
      titleFontSize: 16,
      itemFontSize: 12,
      startZIndex: z,
      spacing: 18,
    ),
  );

  return elements;
}

// ---- Mediterránea ----------------------------------------------------------

List<CanvasElement> _generateMediterranea(
  MenuTemplate t,
  List<CategoryEntity> categories,
  List<MenuItemEntity> dishes,
  String name,
) {
  final elements = <CanvasElement>[];
  int z = 0;

  // Blue header band
  elements.add(
    CanvasElement.shape(
      x: 0,
      y: 0,
      width: kCanvasWidth,
      height: 110,
      fillColor: t.primaryColor,
      strokeColor: 'transparent',
      strokeWidth: 0,
      zIndex: z++,
    ),
  );

  // Restaurant name (white on blue)
  elements.add(
    CanvasElement.text(
      x: 40,
      y: 28,
      width: kCanvasWidth - 80,
      height: 50,
      text: name,
      fontFamily: t.headerFontFamily,
      fontSize: 30,
      color: '#FFFFFF',
      fontWeight: 'bold',
      textAlign: 'center',
      zIndex: z++,
    ),
  );

  // Tagline (white/light)
  elements.add(
    CanvasElement.text(
      x: 80,
      y: 80,
      width: kCanvasWidth - 160,
      height: 20,
      text: 'Sabores del Mediterráneo',
      fontFamily: t.fontFamily,
      fontSize: 12,
      color: '#B3CFFF',
      fontWeight: 'normal',
      textAlign: 'center',
      zIndex: z++,
    ),
  );

  // White content area (implicit, just the bg)
  // Olive accent line
  elements.add(
    CanvasElement.divider(
      x: 100,
      y: 130,
      width: kCanvasWidth - 200,
      color: t.accentColor,
      thickness: 2,
      zIndex: z++,
    ),
  );

  // Category blocks
  elements.addAll(
    _layoutCategoryBlocks(
      categories: categories,
      dishes: dishes,
      startY: 152,
      leftMargin: 45,
      contentWidth: kCanvasWidth - 90,
      titleColor: t.primaryColor,
      itemColor: t.secondaryColor,
      priceColor: t.accentColor,
      fontFamily: t.fontFamily,
      titleFontSize: 17,
      itemFontSize: 12,
      startZIndex: z,
      spacing: 20,
    ),
  );

  // Footer wave (simplified as a colored bar)
  elements.add(
    CanvasElement.shape(
      x: 0,
      y: kCanvasHeight - 20,
      width: kCanvasWidth,
      height: 20,
      fillColor: t.primaryColor,
      strokeColor: 'transparent',
      strokeWidth: 0,
      zIndex: z,
    ),
  );

  return elements;
}

// ---- Café ------------------------------------------------------------------

List<CanvasElement> _generateCafe(
  MenuTemplate t,
  List<CategoryEntity> categories,
  List<MenuItemEntity> dishes,
  String name,
) {
  final elements = <CanvasElement>[];
  int z = 0;

  // Coffee stain circle decoration (top-right)
  elements.add(
    CanvasElement.shape(
      x: kCanvasWidth - 80,
      y: -30,
      width: 130,
      height: 130,
      shapeType: 'circle',
      fillColor: t.accentColor,
      strokeColor: 'transparent',
      strokeWidth: 0,
      opacity: 0.12,
      zIndex: z++,
    ),
  );

  // Another soft circle (bottom-left)
  elements.add(
    CanvasElement.shape(
      x: -40,
      y: kCanvasHeight - 80,
      width: 120,
      height: 120,
      shapeType: 'circle',
      fillColor: t.primaryColor,
      strokeColor: 'transparent',
      strokeWidth: 0,
      opacity: 0.1,
      zIndex: z++,
    ),
  );

  // Coffee cup icon text
  elements.add(
    CanvasElement.text(
      x: 0,
      y: 30,
      width: kCanvasWidth,
      height: 40,
      text: '☕',
      fontFamily: t.fontFamily,
      fontSize: 28,
      color: t.primaryColor,
      fontWeight: 'normal',
      textAlign: 'center',
      zIndex: z++,
    ),
  );

  // Restaurant name
  elements.add(
    CanvasElement.text(
      x: 50,
      y: 75,
      width: kCanvasWidth - 100,
      height: 45,
      text: name,
      fontFamily: t.headerFontFamily,
      fontSize: 28,
      color: t.primaryColor,
      fontWeight: 'bold',
      textAlign: 'center',
      zIndex: z++,
    ),
  );

  // Hand-drawn style divider (dotted)
  elements.add(
    CanvasElement.divider(
      x: 120,
      y: 128,
      width: kCanvasWidth - 240,
      color: t.accentColor,
      thickness: 2,
      style: 'dotted',
      zIndex: z++,
    ),
  );

  // Category blocks
  elements.addAll(
    _layoutCategoryBlocks(
      categories: categories,
      dishes: dishes,
      startY: 155,
      leftMargin: 50,
      contentWidth: kCanvasWidth - 100,
      titleColor: t.primaryColor,
      itemColor: t.secondaryColor,
      priceColor: t.accentColor,
      fontFamily: t.fontFamily,
      titleFontSize: 16,
      itemFontSize: 12,
      startZIndex: z,
      spacing: 22,
    ),
  );

  return elements;
}

// ---- Tropical --------------------------------------------------------------

List<CanvasElement> _generateTropical(
  MenuTemplate t,
  List<CategoryEntity> categories,
  List<MenuItemEntity> dishes,
  String name,
) {
  final elements = <CanvasElement>[];
  int z = 0;

  // Orange top band
  elements.add(
    CanvasElement.shape(
      x: 0,
      y: 0,
      width: kCanvasWidth,
      height: 6,
      fillColor: t.accentColor,
      strokeColor: 'transparent',
      strokeWidth: 0,
      zIndex: z++,
    ),
  );

  // Teal accent circle (decoration)
  elements.add(
    CanvasElement.shape(
      x: -20,
      y: 30,
      width: 100,
      height: 100,
      shapeType: 'circle',
      fillColor: t.primaryColor,
      strokeColor: 'transparent',
      strokeWidth: 0,
      opacity: 0.15,
      zIndex: z++,
    ),
  );
  elements.add(
    CanvasElement.shape(
      x: kCanvasWidth - 60,
      y: 55,
      width: 80,
      height: 80,
      shapeType: 'circle',
      fillColor: t.accentColor,
      strokeColor: 'transparent',
      strokeWidth: 0,
      opacity: 0.15,
      zIndex: z++,
    ),
  );

  // Emoji + restaurant name
  elements.add(
    CanvasElement.text(
      x: 40,
      y: 25,
      width: kCanvasWidth - 80,
      height: 40,
      text: '🌴 $name 🌴',
      fontFamily: t.headerFontFamily,
      fontSize: 26,
      color: t.primaryColor,
      fontWeight: 'bold',
      textAlign: 'center',
      zIndex: z++,
    ),
  );

  // Tagline
  elements.add(
    CanvasElement.text(
      x: 80,
      y: 72,
      width: kCanvasWidth - 160,
      height: 22,
      text: 'Sabores del paraíso',
      fontFamily: t.fontFamily,
      fontSize: 13,
      color: t.secondaryColor,
      fontWeight: 'normal',
      textAlign: 'center',
      zIndex: z++,
    ),
  );

  // Orange divider
  elements.add(
    CanvasElement.divider(
      x: 80,
      y: 102,
      width: kCanvasWidth - 160,
      color: t.accentColor,
      thickness: 2,
      zIndex: z++,
    ),
  );

  // Category blocks in two columns if ≥4
  if (categories.length >= 4) {
    final halfW = (kCanvasWidth - 90) / 2;
    final left = categories.sublist(0, (categories.length / 2).ceil());
    final right = categories.sublist(left.length);

    elements.addAll(
      _layoutCategoryBlocks(
        categories: left,
        dishes: dishes,
        startY: 130,
        leftMargin: 35,
        contentWidth: halfW,
        titleColor: t.primaryColor,
        itemColor: t.secondaryColor,
        priceColor: t.accentColor,
        fontFamily: t.fontFamily,
        titleFontSize: 15,
        itemFontSize: 11,
        startZIndex: z,
      ),
    );
    z += left.length;

    elements.addAll(
      _layoutCategoryBlocks(
        categories: right,
        dishes: dishes,
        startY: 130,
        leftMargin: 35 + halfW + 20,
        contentWidth: halfW,
        titleColor: t.primaryColor,
        itemColor: t.secondaryColor,
        priceColor: t.accentColor,
        fontFamily: t.fontFamily,
        titleFontSize: 15,
        itemFontSize: 11,
        startZIndex: z,
      ),
    );
  } else {
    elements.addAll(
      _layoutCategoryBlocks(
        categories: categories,
        dishes: dishes,
        startY: 130,
        leftMargin: 40,
        contentWidth: kCanvasWidth - 80,
        titleColor: t.primaryColor,
        itemColor: t.secondaryColor,
        priceColor: t.accentColor,
        fontFamily: t.fontFamily,
        titleFontSize: 16,
        itemFontSize: 12,
        startZIndex: z,
        spacing: 20,
      ),
    );
  }

  // Orange bottom band
  elements.add(
    CanvasElement.shape(
      x: 0,
      y: kCanvasHeight - 6,
      width: kCanvasWidth,
      height: 6,
      fillColor: t.accentColor,
      strokeColor: 'transparent',
      strokeWidth: 0,
      zIndex: z,
    ),
  );

  return elements;
}

// ---------------------------------------------------------------------------
// Shared layout helper
// ---------------------------------------------------------------------------

List<CanvasElement> _layoutCategoryBlocks({
  required List<CategoryEntity> categories,
  required List<MenuItemEntity> dishes,
  required double startY,
  required double leftMargin,
  required double contentWidth,
  required String titleColor,
  required String itemColor,
  required String priceColor,
  required String fontFamily,
  required double titleFontSize,
  required double itemFontSize,
  required int startZIndex,
  double spacing = 20,
}) {
  final blocks = <CanvasElement>[];
  double y = startY;

  for (final cat in categories) {
    if (!cat.isActive) continue;
    final catDishes = dishes
        .where((d) => d.categoryId == cat.id && d.isAvailable)
        .toList();
    if (catDishes.isEmpty) continue;

    // height = title (30) + items (22 each) + padding (15)
    final h = 30.0 + (catDishes.length * 22.0) + 15.0;

    blocks.add(
      CanvasElement.menuBlock(
        categoryId: cat.id,
        x: leftMargin,
        y: y,
        width: contentWidth,
        height: h.clamp(70, 500).toDouble(),
        titleColor: titleColor,
        itemColor: itemColor,
        priceColor: priceColor,
        fontFamily: fontFamily,
        titleFontSize: titleFontSize,
        itemFontSize: itemFontSize,
        zIndex: startZIndex + blocks.length,
      ),
    );

    y += h + spacing;
  }

  return blocks;
}
