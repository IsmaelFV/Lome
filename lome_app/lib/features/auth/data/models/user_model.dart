import '../../../auth/domain/entities/user_entity.dart';

/// Modelo de datos del usuario para serializacion con Supabase.
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String? phone;
  final bool isPlatformAdmin;
  final List<TenantMembershipModel> memberships;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.phone,
    this.isPlatformAdmin = false,
    this.memberships = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      isPlatformAdmin: json['is_super_admin'] as bool? ?? false,
      memberships:
          (json['tenant_memberships'] as List<dynamic>?)
              ?.map(
                (e) =>
                    TenantMembershipModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'phone': phone,
      'is_platform_admin': isPlatformAdmin,
    };
  }

  /// Convierte a entidad de dominio.
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      fullName: fullName,
      avatarUrl: avatarUrl,
      phone: phone,
      isPlatformAdmin: isPlatformAdmin,
      memberships: memberships.map((m) => m.toEntity()).toList(),
      createdAt: createdAt,
    );
  }
}

/// Modelo de membresía de tenant.
class TenantMembershipModel {
  final String id;
  final String tenantId;
  final String tenantName;
  final String? tenantLogoUrl;
  final String role;
  final bool isActive;

  const TenantMembershipModel({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    this.tenantLogoUrl,
    required this.role,
    this.isActive = true,
  });

  factory TenantMembershipModel.fromJson(Map<String, dynamic> json) {
    final tenant = json['tenants'] as Map<String, dynamic>?;
    return TenantMembershipModel(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      tenantName: tenant?['name'] as String? ?? '',
      tenantLogoUrl: tenant?['logo_url'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  TenantMembership toEntity() {
    return TenantMembership(
      id: id,
      tenantId: tenantId,
      tenantName: tenantName,
      tenantLogoUrl: tenantLogoUrl,
      role: role,
      isActive: isActive,
    );
  }
}
