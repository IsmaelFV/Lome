/// Nombres de rutas de la aplicacion.
///
/// Centralizados para evitar strings magicos y facilitar la refactorizacion.
class RouteNames {
  RouteNames._();

  // ---------------------------------------------------------------------------
  // General
  // ---------------------------------------------------------------------------

  static const String splash = 'splash';
  static const String welcome = 'welcome';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgot-password';
  static const String emailVerification = 'email-verification';
  static const String resetPassword = 'reset-password';
  static const String editProfile = 'edit-profile';
  static const String selectTenant = 'select-tenant';

  // ---------------------------------------------------------------------------
  // Restaurant App
  // ---------------------------------------------------------------------------

  static const String restaurantShell = 'restaurant';
  static const String restaurantOnboarding = 'restaurant-onboarding';
  static const String restaurantDashboard = 'restaurant-dashboard';
  static const String tables = 'tables';
  static const String tableDetail = 'table-detail';
  static const String orders = 'orders';
  static const String orderDetail = 'order-detail';
  static const String newOrder = 'new-order';
  static const String kitchen = 'kitchen';
  static const String menu = 'menu';
  static const String menuItemDetail = 'menu-item-detail';
  static const String menuItemCreate = 'menu-item-create';
  static const String inventory = 'inventory';
  static const String inventoryItemDetail = 'inventory-item-detail';
  static const String employees = 'employees';
  static const String employeeDetail = 'employee-detail';
  static const String inviteEmployee = 'invite-employee';
  static const String invitationTemplate = 'invitation-template';
  static const String analytics = 'analytics';
  static const String settings = 'settings';
  static const String restaurantSettings = 'restaurant-settings';
  static const String customRoles = 'custom-roles';
  static const String activityLogs = 'activity-logs';
  static const String restaurantHours = 'restaurant-hours';
  static const String tableEditor = 'table-editor';
  static const String tableOrder = 'table-order';
  static const String tableHistory = 'table-history';
  static const String tableStats = 'table-stats';
  static const String reservations = 'reservations';
  static const String orderHistory = 'order-history';
  static const String menuDesignEditor = 'menu-design-editor';
  static const String menuQr = 'menu-qr';
  static const String digitalMenu = 'digital-menu';

  // ---------------------------------------------------------------------------
  // Marketplace
  // ---------------------------------------------------------------------------

  static const String marketplaceShell = 'marketplace';
  static const String marketplaceHome = 'marketplace-home';
  static const String marketplaceSearch = 'marketplace-search';
  static const String restaurantDetail = 'restaurant-detail';
  static const String cart = 'cart';
  static const String checkout = 'checkout';
  static const String orderTracking = 'order-tracking';
  static const String customerProfile = 'customer-profile';
  static const String customerOrders = 'customer-orders';
  static const String customerFavorites = 'customer-favorites';

  // ---------------------------------------------------------------------------
  // Admin Panel
  // ---------------------------------------------------------------------------

  static const String adminShell = 'admin';
  static const String adminDashboard = 'admin-dashboard';
  static const String adminRestaurants = 'admin-restaurants';
  static const String adminRestaurantDetail = 'admin-restaurant-detail';
  static const String adminAnalytics = 'admin-analytics';
  static const String adminIncidents = 'admin-incidents';
  static const String adminIncidentDetail = 'admin-incident-detail';
  static const String adminModeration = 'admin-moderation';
  static const String adminSubscriptions = 'admin-subscriptions';
  static const String adminAudit = 'admin-audit';
  static const String adminMonitoring = 'admin-monitoring';
}

/// Paths de las rutas.
class RoutePaths {
  RoutePaths._();

  // General
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';
  static const String resetPassword = '/reset-password';
  static const String editProfile = '/edit-profile';
  static const String selectTenant = '/select-tenant';

  // Restaurant
  static const String restaurant = '/restaurant';
  static const String restaurantOnboarding = '/restaurant/onboarding';
  static const String tables = '/restaurant/tables';
  static const String orders = '/restaurant/orders';
  static const String kitchen = '/restaurant/kitchen';
  static const String menu = '/restaurant/menu';
  static const String inventory = '/restaurant/inventory';
  static const String restaurantDashboard = '/restaurant/dashboard';
  static const String employees = '/restaurant/employees';
  static const String inviteEmployee = '/restaurant/employees/invite';
  static const String invitationTemplate = '/restaurant/employees/template';
  static const String analytics = '/restaurant/analytics';
  static const String settings = '/restaurant/settings';
  static const String restaurantSettings = '/restaurant/settings/restaurant';
  static const String customRoles = '/restaurant/settings/roles';
  static const String activityLogs = '/restaurant/activity-logs';
  static const String restaurantHours = '/restaurant/settings/hours';
  static const String tableEditor = '/restaurant/tables/editor';
  static const String tableOrder = '/restaurant/tables/order';
  static const String tableHistory = '/restaurant/tables/history';
  static const String tableStats = '/restaurant/tables/stats';
  static const String reservations = '/restaurant/reservations';
  static const String orderHistory = '/restaurant/orders/history';
  static const String menuDesignEditor = '/restaurant/menu/design';
  static const String menuQr = '/restaurant/menu/qr';
  static const String digitalMenu = '/menu/:id';

  // Marketplace
  static const String marketplace = '/marketplace';
  static const String marketplaceSearch = '/marketplace/search';
  static const String restaurantDetail = '/marketplace/restaurant/:id';
  static const String cart = '/marketplace/cart';
  static const String checkout = '/marketplace/checkout';
  static const String customerProfile = '/marketplace/profile';
  static const String customerOrders = '/marketplace/orders';
  static const String customerFavorites = '/marketplace/favorites';

  // Admin
  static const String admin = '/admin';
  static const String adminRestaurants = '/admin/restaurants';
  static const String adminRestaurantDetail = '/admin/restaurants/:id';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminIncidents = '/admin/incidents';
  static const String adminIncidentDetail = '/admin/incidents/:id';
  static const String adminModeration = '/admin/moderation';
  static const String adminSubscriptions = '/admin/subscriptions';
  static const String adminAudit = '/admin/audit';
  static const String adminMonitoring = '/admin/monitoring';
}
