import 'package:equatable/equatable.dart';

/// Entidad de usuario del dominio.
///
/// Representa un usuario autenticado con su informacion basica
/// y su relacion con tenants (restaurantes).
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String? phone;
  final bool isPlatformAdmin;
  final List<TenantMembership> memberships;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.phone,
    this.isPlatformAdmin = false,
    this.memberships = const [],
    required this.createdAt,
  });

  /// Devuelve true si el usuario pertenece a al menos un restaurante.
  bool get hasTenants => memberships.isNotEmpty;

  /// Devuelve el primer tenant (restaurante activo por defecto).
  TenantMembership? get defaultMembership =>
      memberships.isNotEmpty ? memberships.first : null;

  /// Comprueba si el usuario tiene un rol especifico en un tenant.
  bool hasRoleInTenant(String tenantId, String role) {
    return memberships.any(
      (m) => m.tenantId == tenantId && m.role == role && m.isActive,
    );
  }

  /// Comprueba si el usuario es owner o manager en un tenant.
  bool isManagerInTenant(String tenantId) {
    return memberships.any(
      (m) =>
          m.tenantId == tenantId &&
          (m.role == 'owner' || m.role == 'manager') &&
          m.isActive,
    );
  }

  @override
  List<Object?> get props => [id, email, fullName, isPlatformAdmin];
}

/// Relacion usuario-tenant con su rol.
class TenantMembership extends Equatable {
  final String id;
  final String tenantId;
  final String tenantName;
  final String? tenantLogoUrl;
  final String role;
  final bool isActive;

  const TenantMembership({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    this.tenantLogoUrl,
    required this.role,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, tenantId, role, isActive];
}
