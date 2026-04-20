import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import 'app_permission.dart';

// ---------------------------------------------------------------------------
// Providers de permisos — conectan el sistema de roles con Riverpod
// ---------------------------------------------------------------------------

/// Rol actual del usuario en el tenant activo.
/// Devuelve null si no hay tenant activo o no hay membresía.
final currentRoleProvider = Provider<String?>((ref) {
  final membership = ref.watch(activeMembershipProvider);
  return membership?.role;
});

/// Set de permisos del usuario en el tenant activo.
/// Se recalcula automáticamente cuando cambia el tenant o la membresía.
final userPermissionsProvider = Provider<Set<AppPermission>>((ref) {
  final role = ref.watch(currentRoleProvider);
  if (role == null) return {};
  return rolePermissions[role] ?? {};
});

/// Comprueba si el usuario tiene un permiso específico.
/// Uso: `ref.watch(hasPermissionProvider(AppPermission.manageEmployees))`
final hasPermissionProvider = Provider.family<bool, AppPermission>((ref, permission) {
  final permissions = ref.watch(userPermissionsProvider);
  return permissions.contains(permission);
});

/// Comprueba si el usuario tiene TODOS los permisos indicados.
/// Uso: `ref.watch(hasAllPermissionsProvider([AppPermission.manageMenu, AppPermission.viewInventory]))`
final hasAllPermissionsProvider = Provider.family<bool, List<AppPermission>>((ref, required) {
  final permissions = ref.watch(userPermissionsProvider);
  return required.every(permissions.contains);
});

/// Comprueba si el usuario tiene AL MENOS UNO de los permisos indicados.
final hasAnyPermissionProvider = Provider.family<bool, List<AppPermission>>((ref, anyOf) {
  final permissions = ref.watch(userPermissionsProvider);
  return anyOf.any(permissions.contains);
});

/// true si el usuario es owner del tenant activo.
final isOwnerProvider = Provider<bool>((ref) {
  return ref.watch(currentRoleProvider) == 'owner';
});

/// true si el usuario es owner o manager del tenant activo.
final isManagerOrAboveProvider = Provider<bool>((ref) {
  final role = ref.watch(currentRoleProvider);
  return role == 'owner' || role == 'manager';
});

/// true si el usuario es admin de plataforma (superadmin).
final isPlatformAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.isPlatformAdmin ?? false;
});
