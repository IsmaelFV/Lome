/// Constantes globales de la aplicacion LOME.
class AppConstants {
  AppConstants._();

  // -------------------------------------------------------------------------
  // App
  // -------------------------------------------------------------------------

  static const String appName = 'LOME';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Tu restaurante, simplificado';

  // -------------------------------------------------------------------------
  // Pagination
  // -------------------------------------------------------------------------

  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // -------------------------------------------------------------------------
  // Timeouts
  // -------------------------------------------------------------------------

  static const Duration apiTimeout = Duration(seconds: 15);
  static const Duration realtimeReconnect = Duration(seconds: 5);

  // -------------------------------------------------------------------------
  // Validation
  // -------------------------------------------------------------------------

  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 500;
  static const int maxNotesLength = 1000;

  // -------------------------------------------------------------------------
  // Orders
  // -------------------------------------------------------------------------

  static const double defaultTaxRate = 0.10; // 10% IVA
  static const int orderNumberPadding = 4;

  // -------------------------------------------------------------------------
  // Storage Buckets
  // -------------------------------------------------------------------------

  static const String avatarsBucket = 'avatars';
  static const String menuImagesBucket = 'menu-images';
  static const String restaurantImagesBucket = 'restaurant-images';

  // -------------------------------------------------------------------------
  // Realtime Channels
  // -------------------------------------------------------------------------

  static const String ordersChannel = 'orders';
  static const String tablesChannel = 'tables';
  static const String kitchenChannel = 'kitchen';

  // -------------------------------------------------------------------------
  // Roles
  // -------------------------------------------------------------------------

  static const String roleOwner = 'owner';
  static const String roleManager = 'manager';
  static const String roleWaiter = 'waiter';
  static const String roleChef = 'chef';
  static const String roleCashier = 'cashier';

  static const List<String> allRoles = [
    roleOwner,
    roleManager,
    roleWaiter,
    roleChef,
    roleCashier,
  ];

  static const List<String> managementRoles = [roleOwner, roleManager];
}
