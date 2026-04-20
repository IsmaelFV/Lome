import 'package:equatable/equatable.dart';

/// Entidad de restaurante visible en el marketplace.
class MarketplaceRestaurant extends Equatable {
  final String id;
  final String name;
  final String? slug;
  final String? description;
  final String? logoUrl;
  final String? coverImageUrl;
  final List<String> cuisineType;
  final double rating;
  final int totalReviews;
  final bool deliveryEnabled;
  final bool takeawayEnabled;
  final double? deliveryRadiusKm;
  final double? minimumOrderAmount;
  final double? deliveryFee;
  final int? estimatedDeliveryTimeMin;
  final String? averagePriceRange;
  final String? city;
  final double? latitude;
  final double? longitude;
  final bool isFeatured;
  final String status;

  const MarketplaceRestaurant({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.logoUrl,
    this.coverImageUrl,
    this.cuisineType = const [],
    this.rating = 0,
    this.totalReviews = 0,
    this.deliveryEnabled = false,
    this.takeawayEnabled = false,
    this.deliveryRadiusKm,
    this.minimumOrderAmount,
    this.deliveryFee,
    this.estimatedDeliveryTimeMin,
    this.averagePriceRange,
    this.city,
    this.latitude,
    this.longitude,
    this.isFeatured = false,
    this.status = 'active',
  });

  bool get isOpen => status == 'active';

  String get cuisineLabel =>
      cuisineType.isNotEmpty ? cuisineType.join(', ') : 'Variada';

  String get deliveryTimeLabel => estimatedDeliveryTimeMin != null
      ? '$estimatedDeliveryTimeMin min'
      : '20-30 min';

  factory MarketplaceRestaurant.fromJson(Map<String, dynamic> json) {
    return MarketplaceRestaurant(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      cuisineType:
          (json['cuisine_type'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      deliveryEnabled: json['delivery_enabled'] as bool? ?? false,
      takeawayEnabled: json['takeaway_enabled'] as bool? ?? false,
      deliveryRadiusKm: (json['delivery_radius_km'] as num?)?.toDouble(),
      minimumOrderAmount: (json['minimum_order_amount'] as num?)?.toDouble(),
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble(),
      estimatedDeliveryTimeMin: (json['estimated_delivery_time_min'] as num?)
          ?.toInt(),
      averagePriceRange: json['average_price_range'] as String?,
      city: json['city'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isFeatured: json['is_featured'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
    );
  }

  @override
  List<Object?> get props => [id];
}

/// Categoría de menú.
class MenuCategory extends Equatable {
  final String id;
  final String tenantId;
  final String name;
  final String? description;
  final String? imageUrl;
  final int sortOrder;

  const MenuCategory({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    this.imageUrl,
    this.sortOrder = 0,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id];
}

/// Plato del menú.
class Dish extends Equatable {
  final String id;
  final String tenantId;
  final String? categoryId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final List<String> allergens;
  final List<String> tags;
  final int? preparationTimeMin;
  final int? calories;
  final bool isAvailable;
  final bool isFeatured;

  const Dish({
    required this.id,
    required this.tenantId,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.allergens = const [],
    this.tags = const [],
    this.preparationTimeMin,
    this.calories,
    this.isAvailable = true,
    this.isFeatured = false,
  });

  bool get isVegetarian => tags.contains('vegetarian');
  bool get isVegan => tags.contains('vegan');
  bool get isGlutenFree => tags.contains('gluten_free');
  bool get isSpicy => tags.contains('spicy');

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      categoryId: json['category_id'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      imageUrl: json['image_url'] as String?,
      allergens:
          (json['allergens'] as List?)?.map((e) => e.toString()).toList() ?? [],
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      preparationTimeMin: (json['preparation_time_min'] as num?)?.toInt(),
      calories: (json['calories'] as num?)?.toInt(),
      isAvailable: json['is_available'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id];
}
