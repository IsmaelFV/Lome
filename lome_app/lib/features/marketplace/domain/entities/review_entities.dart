import 'package:equatable/equatable.dart';

/// Valoración de un restaurante por un cliente.
class Review extends Equatable {
  final String id;
  final String tenantId;
  final String userId;
  final String orderId;
  final int rating;
  final String? comment;
  final String? reply;
  final DateTime? repliedAt;
  final bool isVisible;
  final DateTime createdAt;

  // Info desnormalizada para UI
  final String? userName;

  const Review({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.orderId,
    required this.rating,
    this.comment,
    this.reply,
    this.repliedAt,
    this.isVisible = true,
    required this.createdAt,
    this.userName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return Review(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      userId: json['user_id'] as String,
      orderId: json['order_id'] as String,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      reply: json['reply'] as String?,
      repliedAt: json['replied_at'] != null
          ? DateTime.parse(json['replied_at'] as String)
          : null,
      isVisible: json['is_visible'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: profile?['full_name'] as String?,
    );
  }

  @override
  List<Object?> get props => [id];
}

/// Entidad de promoción de un restaurante.
class Promotion extends Equatable {
  final String id;
  final String tenantId;
  final String title;
  final String? description;
  final PromotionType type;
  final double value;
  final double? minimumOrderAmount;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final int? maxUses;
  final int currentUses;
  final String? code;

  // Info desnormalizada
  final String? restaurantName;
  final String? restaurantLogo;

  const Promotion({
    required this.id,
    required this.tenantId,
    required this.title,
    this.description,
    required this.type,
    required this.value,
    this.minimumOrderAmount,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.maxUses,
    this.currentUses = 0,
    this.code,
    this.restaurantName,
    this.restaurantLogo,
  });

  bool get isExpired => endDate != null && endDate!.isBefore(DateTime.now());
  bool get hasUsesLeft => maxUses == null || currentUses < maxUses!;
  bool get isValid => isActive && !isExpired && hasUsesLeft;

  String get discountLabel {
    switch (type) {
      case PromotionType.percentage:
        return '-${value.toStringAsFixed(0)}%';
      case PromotionType.fixed:
        return '-€${value.toStringAsFixed(2)}';
      case PromotionType.timeLimited:
        return '-${value.toStringAsFixed(0)}%';
    }
  }

  factory Promotion.fromJson(Map<String, dynamic> json) {
    final tenant = json['tenants'] as Map<String, dynamic>?;
    return Promotion(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: PromotionType.fromString(json['type'] as String),
      value: (json['value'] as num).toDouble(),
      minimumOrderAmount:
          (json['minimum_order_amount'] as num?)?.toDouble(),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      maxUses: json['max_uses'] as int?,
      currentUses: (json['current_uses'] as num?)?.toInt() ?? 0,
      code: json['code'] as String?,
      restaurantName: tenant?['name'] as String?,
      restaurantLogo: tenant?['logo_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [id];
}

enum PromotionType {
  percentage,
  fixed,
  timeLimited;

  String get label {
    switch (this) {
      case percentage:
        return 'Porcentaje';
      case fixed:
        return 'Descuento fijo';
      case timeLimited:
        return 'Tiempo limitado';
    }
  }

  static PromotionType fromString(String value) {
    switch (value) {
      case 'percentage':
        return PromotionType.percentage;
      case 'fixed':
        return PromotionType.fixed;
      case 'time_limited':
        return PromotionType.timeLimited;
      default:
        return PromotionType.percentage;
    }
  }
}
