/// Define los permisos de la aplicación agrupados por módulo.
///
/// Cada permiso se asocia a uno o más roles del sistema.
/// El [PermissionGuard] y los providers de permisos usan estos valores
/// para mostrar/ocultar elementos de la UI según el rol del usuario.
enum AppPermission {
  // ── Empleados / Equipo ──
  manageEmployees,      // Invitar, editar roles, desactivar
  viewEmployees,        // Ver listado de empleados

  // ── Menú ──
  manageMenu,           // Crear, editar, eliminar platos
  viewMenu,             // Ver el menú

  // ── Pedidos ──
  createOrder,          // Crear nuevos pedidos
  viewOrders,           // Ver listado de pedidos
  manageOrders,         // Cambiar estado, cancelar pedidos

  // ── Cocina ──
  viewKitchen,          // Ver pantalla de cocina

  // ── Mesas ──
  manageTables,         // Crear, editar, eliminar mesas
  viewTables,           // Ver listado de mesas

  // ── Inventario ──
  manageInventory,      // Crear, editar stock
  viewInventory,        // Ver inventario

  // ── Analíticas ──
  viewAnalytics,        // Ver panel de analíticas

  // ── Configuración ──
  manageSettings,       // Editar configuración del restaurante

  // ── Facturación ──
  viewBilling,          // Ver información de facturación
  manageBilling,        // Gestionar pagos y suscripción
}

/// Mapa de roles → permisos.
///
/// Define qué puede hacer cada rol dentro de un tenant (restaurante).
/// Los roles siguen una jerarquía implícita:
///   owner > manager > waiter > kitchen > viewer
const Map<String, Set<AppPermission>> rolePermissions = {
  'owner': {
    // El owner tiene TODOS los permisos
    AppPermission.manageEmployees,
    AppPermission.viewEmployees,
    AppPermission.manageMenu,
    AppPermission.viewMenu,
    AppPermission.createOrder,
    AppPermission.viewOrders,
    AppPermission.manageOrders,
    AppPermission.viewKitchen,
    AppPermission.manageTables,
    AppPermission.viewTables,
    AppPermission.manageInventory,
    AppPermission.viewInventory,
    AppPermission.viewAnalytics,
    AppPermission.manageSettings,
    AppPermission.viewBilling,
    AppPermission.manageBilling,
  },
  'manager': {
    AppPermission.manageEmployees,
    AppPermission.viewEmployees,
    AppPermission.manageMenu,
    AppPermission.viewMenu,
    AppPermission.createOrder,
    AppPermission.viewOrders,
    AppPermission.manageOrders,
    AppPermission.viewKitchen,
    AppPermission.manageTables,
    AppPermission.viewTables,
    AppPermission.manageInventory,
    AppPermission.viewInventory,
    AppPermission.viewAnalytics,
    AppPermission.manageSettings,
    // Sin acceso a facturación
  },
  'waiter': {
    AppPermission.viewEmployees,
    AppPermission.viewMenu,
    AppPermission.createOrder,
    AppPermission.viewOrders,
    AppPermission.manageOrders,
    AppPermission.viewTables,
    AppPermission.viewKitchen,
  },
  'kitchen': {
    AppPermission.viewMenu,
    AppPermission.viewOrders,
    AppPermission.viewKitchen,
    AppPermission.viewInventory,
  },
  'viewer': {
    AppPermission.viewMenu,
    AppPermission.viewOrders,
    AppPermission.viewTables,
  },
};

/// Extensión utilitaria para verificar si un rol tiene un permiso.
extension RolePermissionCheck on String {
  bool hasPermission(AppPermission permission) {
    return rolePermissions[this]?.contains(permission) ?? false;
  }

  Set<AppPermission> get permissions {
    return rolePermissions[this] ?? {};
  }
}
