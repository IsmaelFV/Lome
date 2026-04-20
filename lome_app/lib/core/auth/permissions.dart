/// Sistema de control de permisos del frontend.
///
/// Exporta las definiciones de permisos, los providers reactivos
/// y los widgets guard para usar en toda la aplicación.
///
/// Uso básico:
/// ```dart
/// import 'package:lome_app/core/auth/permissions.dart';
///
/// // En un widget con Riverpod:
/// final canManage = ref.watch(hasPermissionProvider(AppPermission.manageEmployees));
///
/// // Como widget wrapper:
/// PermissionGuard(
///   permission: AppPermission.manageMenu,
///   child: FloatingActionButton(...),
/// )
/// ```
library;

export 'app_permission.dart';
export 'permission_guard.dart';
export 'permission_provider.dart';
