import 'package:equatable/equatable.dart';

/// Configuración visual de la carta digital de un restaurante.
class MenuDesign extends Equatable {
  final String id;
  final String tenantId;

  // Colores
  final String primaryColor;
  final String secondaryColor;
  final String backgroundColor;
  final String accentColor;
  final String cardColor;
  final String textColor;

  // Tipografía
  final String fontFamily;
  final String headerFontFamily;
  final int fontSizeBase;

  // Layout
  final String layoutStyle;
  final String itemsLayout;

  // Opciones de visualización
  final bool showImages;
  final bool showPrices;
  final bool showDescriptions;
  final bool showAllergens;
  final bool showCalories;
  final bool showPrepTime;
  final bool showTags;

  // Cabecera
  final String? headerImageUrl;
  final String logoPosition;
  final bool showRestaurantInfo;
  final String headerStyle;

  // Animaciones
  final String animationStyle;
  final String animationIntensity;

  // Bloques personalizables
  final List<MenuSection> sections;

  // Extensiones / canvas
  final Map<String, dynamic>? customStyles;

  // Estado
  final bool isPublished;
  final DateTime? publishedAt;

  const MenuDesign({
    required this.id,
    required this.tenantId,
    this.primaryColor = '#FF6B35',
    this.secondaryColor = '#2D3436',
    this.backgroundColor = '#FAFAFA',
    this.accentColor = '#FDCB6E',
    this.cardColor = '#FFFFFF',
    this.textColor = '#2D3436',
    this.fontFamily = 'Poppins',
    this.headerFontFamily = 'Playfair Display',
    this.fontSizeBase = 14,
    this.layoutStyle = 'classic',
    this.itemsLayout = 'list',
    this.showImages = true,
    this.showPrices = true,
    this.showDescriptions = true,
    this.showAllergens = true,
    this.showCalories = false,
    this.showPrepTime = false,
    this.showTags = true,
    this.headerImageUrl,
    this.logoPosition = 'center',
    this.showRestaurantInfo = true,
    this.headerStyle = 'full',
    this.animationStyle = 'fade',
    this.animationIntensity = 'medium',
    this.sections = const [],
    this.customStyles,
    this.isPublished = false,
    this.publishedAt,
  });

  factory MenuDesign.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'] as List<dynamic>? ?? [];
    return MenuDesign(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      primaryColor: json['primary_color'] as String? ?? '#FF6B35',
      secondaryColor: json['secondary_color'] as String? ?? '#2D3436',
      backgroundColor: json['background_color'] as String? ?? '#FAFAFA',
      accentColor: json['accent_color'] as String? ?? '#FDCB6E',
      cardColor: json['card_color'] as String? ?? '#FFFFFF',
      textColor: json['text_color'] as String? ?? '#2D3436',
      fontFamily: json['font_family'] as String? ?? 'Poppins',
      headerFontFamily:
          json['header_font_family'] as String? ?? 'Playfair Display',
      fontSizeBase: json['font_size_base'] as int? ?? 14,
      layoutStyle: json['layout_style'] as String? ?? 'classic',
      itemsLayout: json['items_layout'] as String? ?? 'list',
      showImages: json['show_images'] as bool? ?? true,
      showPrices: json['show_prices'] as bool? ?? true,
      showDescriptions: json['show_descriptions'] as bool? ?? true,
      showAllergens: json['show_allergens'] as bool? ?? true,
      showCalories: json['show_calories'] as bool? ?? false,
      showPrepTime: json['show_prep_time'] as bool? ?? false,
      showTags: json['show_tags'] as bool? ?? true,
      headerImageUrl: json['header_image_url'] as String?,
      logoPosition: json['logo_position'] as String? ?? 'center',
      showRestaurantInfo: json['show_restaurant_info'] as bool? ?? true,
      headerStyle: json['header_style'] as String? ?? 'full',
      animationStyle: json['animation_style'] as String? ?? 'fade',
      animationIntensity: json['animation_intensity'] as String? ?? 'medium',
      sections: rawSections
          .map((s) => MenuSection.fromJson(s as Map<String, dynamic>))
          .toList(),
      customStyles: json['custom_styles'] as Map<String, dynamic>?,
      isPublished: json['is_published'] as bool? ?? false,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'tenant_id': tenantId,
    'primary_color': primaryColor,
    'secondary_color': secondaryColor,
    'background_color': backgroundColor,
    'accent_color': accentColor,
    'card_color': cardColor,
    'text_color': textColor,
    'font_family': fontFamily,
    'header_font_family': headerFontFamily,
    'font_size_base': fontSizeBase,
    'layout_style': layoutStyle,
    'items_layout': itemsLayout,
    'show_images': showImages,
    'show_prices': showPrices,
    'show_descriptions': showDescriptions,
    'show_allergens': showAllergens,
    'show_calories': showCalories,
    'show_prep_time': showPrepTime,
    'show_tags': showTags,
    'header_image_url': headerImageUrl,
    'logo_position': logoPosition,
    'show_restaurant_info': showRestaurantInfo,
    'header_style': headerStyle,
    'animation_style': animationStyle,
    'animation_intensity': animationIntensity,
    'sections': sections.map((s) => s.toJson()).toList(),
    if (customStyles != null) 'custom_styles': customStyles,
    'is_published': isPublished,
  };

  MenuDesign copyWith({
    String? primaryColor,
    String? secondaryColor,
    String? backgroundColor,
    String? accentColor,
    String? cardColor,
    String? textColor,
    String? fontFamily,
    String? headerFontFamily,
    int? fontSizeBase,
    String? layoutStyle,
    String? itemsLayout,
    bool? showImages,
    bool? showPrices,
    bool? showDescriptions,
    bool? showAllergens,
    bool? showCalories,
    bool? showPrepTime,
    bool? showTags,
    String? headerImageUrl,
    String? logoPosition,
    bool? showRestaurantInfo,
    String? headerStyle,
    String? animationStyle,
    String? animationIntensity,
    List<MenuSection>? sections,
    Map<String, dynamic>? customStyles,
    bool? isPublished,
    DateTime? publishedAt,
  }) {
    return MenuDesign(
      id: id,
      tenantId: tenantId,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      accentColor: accentColor ?? this.accentColor,
      cardColor: cardColor ?? this.cardColor,
      textColor: textColor ?? this.textColor,
      fontFamily: fontFamily ?? this.fontFamily,
      headerFontFamily: headerFontFamily ?? this.headerFontFamily,
      fontSizeBase: fontSizeBase ?? this.fontSizeBase,
      layoutStyle: layoutStyle ?? this.layoutStyle,
      itemsLayout: itemsLayout ?? this.itemsLayout,
      showImages: showImages ?? this.showImages,
      showPrices: showPrices ?? this.showPrices,
      showDescriptions: showDescriptions ?? this.showDescriptions,
      showAllergens: showAllergens ?? this.showAllergens,
      showCalories: showCalories ?? this.showCalories,
      showPrepTime: showPrepTime ?? this.showPrepTime,
      showTags: showTags ?? this.showTags,
      headerImageUrl: headerImageUrl ?? this.headerImageUrl,
      logoPosition: logoPosition ?? this.logoPosition,
      showRestaurantInfo: showRestaurantInfo ?? this.showRestaurantInfo,
      headerStyle: headerStyle ?? this.headerStyle,
      animationStyle: animationStyle ?? this.animationStyle,
      animationIntensity: animationIntensity ?? this.animationIntensity,
      sections: sections ?? this.sections,
      customStyles: customStyles ?? this.customStyles,
      isPublished: isPublished ?? this.isPublished,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  @override
  List<Object?> get props => [id, tenantId, isPublished];
}

/// Bloque/sección personalizable de la carta digital.
class MenuSection extends Equatable {
  final String id;
  final String
  type; // 'header', 'featured', 'categories', 'category', 'divider', 'text', 'banner'
  final bool visible;
  final String
  animation; // 'none', 'fade', 'slide', 'scale', 'stagger', 'elegant', 'playful'
  final Map<String, dynamic> config;

  const MenuSection({
    required this.id,
    required this.type,
    this.visible = true,
    this.animation = 'fade',
    this.config = const {},
  });

  factory MenuSection.fromJson(Map<String, dynamic> json) {
    return MenuSection(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      visible: json['visible'] as bool? ?? true,
      animation: json['animation'] as String? ?? 'fade',
      config: (json['config'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'visible': visible,
    'animation': animation,
    'config': config,
  };

  MenuSection copyWith({
    bool? visible,
    String? animation,
    Map<String, dynamic>? config,
  }) {
    return MenuSection(
      id: id,
      type: type,
      visible: visible ?? this.visible,
      animation: animation ?? this.animation,
      config: config ?? this.config,
    );
  }

  @override
  List<Object?> get props => [id, type, visible];
}
