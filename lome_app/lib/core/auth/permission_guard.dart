import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_permission.dart';
import 'permission_provider.dart';

/// Widget que muestra/oculta su [child] según los permisos del usuario.
///
/// Ejemplo:
/// ```dart
/// PermissionGuard(
///   permission: AppPermission.manageEmployees,
///   child: ElevatedButton(onPressed: _invite, child: Text('Invitar')),
/// )
/// ```
///
/// Se puede usar con un solo permiso, una lista (todos requeridos),
/// o una lista alternativa (al menos uno requerido).
class PermissionGuard extends ConsumerWidget {
  /// Permiso único requerido.
  final AppPermission? permission;

  /// Lista de permisos — se requieren TODOS.
  final List<AppPermission>? allOf;

  /// Lista de permisos — se requiere AL MENOS UNO.
  final List<AppPermission>? anyOf;

  /// Widget a mostrar cuando el usuario tiene permiso.
  final Widget child;

  /// Widget alternativo cuando NO tiene permiso. Por defecto: `SizedBox.shrink()`.
  final Widget? fallback;

  /// Si true, muestra [child] pero deshabilitado (opacidad reducida + sin eventos).
  final bool showDisabled;

  const PermissionGuard({
    super.key,
    this.permission,
    this.allOf,
    this.anyOf,
    required this.child,
    this.fallback,
    this.showDisabled = false,
  }) : assert(
          permission != null || allOf != null || anyOf != null,
          'Debes proporcionar permission, allOf o anyOf',
        );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool allowed;

    if (permission != null) {
      allowed = ref.watch(hasPermissionProvider(permission!));
    } else if (allOf != null) {
      allowed = ref.watch(hasAllPermissionsProvider(allOf!));
    } else {
      allowed = ref.watch(hasAnyPermissionProvider(anyOf!));
    }

    if (allowed) return child;

    if (showDisabled) {
      return IgnorePointer(
        child: Opacity(opacity: 0.4, child: child),
      );
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// Widget que muestra contenido solo si el usuario es owner o manager.
class ManagerGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const ManagerGuard({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isManager = ref.watch(isManagerOrAboveProvider);
    return isManager ? child : (fallback ?? const SizedBox.shrink());
  }
}

/// Widget que muestra contenido solo si el usuario es admin de plataforma.
class PlatformAdminGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const PlatformAdminGuard({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isPlatformAdminProvider);
    return isAdmin ? child : (fallback ?? const SizedBox.shrink());
  }
}
