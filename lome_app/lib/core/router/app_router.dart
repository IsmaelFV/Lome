import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'route_names.dart';

// -- Auth pages --
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/email_verification_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';

// -- Profile pages --
import '../../features/profile/presentation/pages/edit_profile_page.dart';

// -- Restaurant pages --
import '../../features/restaurant/presentation/pages/restaurant_shell.dart';
import '../../features/restaurant/tables/presentation/pages/tables_page.dart';
import '../../features/restaurant/orders/presentation/pages/orders_page.dart';
import '../../features/restaurant/kitchen/presentation/pages/kitchen_display_page.dart';
import '../../features/restaurant/menu/presentation/pages/menu_management_page.dart';
import '../../features/restaurant/menu/presentation/pages/menu_design_editor_page.dart';
import '../../features/restaurant/menu/presentation/pages/menu_qr_page.dart';
import '../../features/restaurant/menu/presentation/pages/digital_menu_page.dart';
import '../../features/restaurant/inventory/presentation/pages/inventory_page.dart';
import '../../features/restaurant/employees/presentation/pages/employees_page.dart';
import '../../features/restaurant/employees/presentation/pages/invite_employee_page.dart';
import '../../features/restaurant/employees/presentation/pages/invitation_template_page.dart';
import '../../features/restaurant/analytics/presentation/pages/analytics_page.dart';
import '../../features/restaurant/settings/presentation/pages/settings_page.dart';
import '../../features/restaurant/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/restaurant/settings/presentation/pages/restaurant_settings_page.dart';
import '../../features/restaurant/roles/presentation/pages/custom_roles_page.dart';
import '../../features/restaurant/activity_logs/presentation/pages/activity_logs_page.dart';
import '../../features/restaurant/hours/presentation/pages/restaurant_hours_page.dart';
import '../../features/restaurant/tables/presentation/pages/table_editor_page.dart';
import '../../features/restaurant/tables/presentation/pages/table_history_page.dart';
import '../../features/restaurant/tables/presentation/pages/table_stats_page.dart';
import '../../features/restaurant/orders/presentation/pages/table_order_page.dart';
import '../../features/restaurant/orders/presentation/pages/order_history_page.dart';
import '../../features/restaurant/onboarding/presentation/pages/restaurant_onboarding_page.dart';
import '../../features/restaurant/onboarding/presentation/providers/restaurant_onboarding_provider.dart';

// -- Marketplace pages --
import '../../features/marketplace/presentation/pages/marketplace_shell.dart';
import '../../features/marketplace/home/presentation/pages/marketplace_home_page.dart';
import '../../features/marketplace/search/presentation/pages/search_page.dart';
import '../../features/marketplace/cart/presentation/pages/cart_page.dart';
import '../../features/marketplace/checkout/presentation/pages/checkout_page.dart';
import '../../features/marketplace/order_tracking/presentation/pages/order_tracking_page.dart';
import '../../features/marketplace/profile/presentation/pages/profile_page.dart';
import '../../features/marketplace/menu/presentation/pages/restaurant_menu_page.dart';
import '../../features/marketplace/favorites/presentation/pages/favorites_page.dart';
import '../../features/marketplace/orders/presentation/pages/customer_orders_page.dart';

// -- Admin pages --
import '../../features/admin/presentation/pages/admin_shell.dart';
import '../../features/admin/dashboard/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/restaurants/presentation/pages/admin_restaurants_page.dart';
import '../../features/admin/analytics/presentation/pages/admin_analytics_page.dart';
import '../../features/admin/incidents/presentation/pages/admin_incidents_page.dart';
import '../../features/admin/moderation/presentation/pages/admin_moderation_page.dart';
import '../../features/admin/restaurants/presentation/pages/admin_restaurant_detail_page.dart';
import '../../features/admin/incidents/presentation/pages/admin_incident_detail_page.dart';
import '../../features/admin/subscriptions/presentation/pages/admin_subscriptions_page.dart';
import '../../features/admin/audit/presentation/pages/admin_audit_page.dart';
import '../../features/admin/monitoring/presentation/pages/admin_monitoring_page.dart';

// -- Providers --
import '../../features/auth/presentation/providers/auth_provider.dart';

/// GlobalKey para acceso al navigator desde cualquier parte.
final rootNavigatorKey = GlobalKey<NavigatorState>();
final _restaurantNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'restaurant-tables',
);
final _ordersNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'restaurant-orders',
);
final _kitchenNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'restaurant-kitchen',
);
final _menuNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'restaurant-menu',
);
final _inventoryNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'restaurant-inventory',
);
final _marketplaceNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'marketplace-home',
);
final _marketplaceSearchNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'marketplace-search',
);
final _marketplaceCartNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'marketplace-cart',
);
final _marketplaceProfileNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'marketplace-profile',
);
final _adminNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'admin-dashboard');
final _adminRestaurantsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'admin-restaurants');
final _adminAnalyticsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'admin-analytics');
final _adminIncidentsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'admin-incidents');
final _adminModerationNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'admin-moderation');
final _adminSubscriptionsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'admin-subscriptions');
final _adminAuditNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'admin-audit');
final _adminMonitoringNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'admin-monitoring');

/// Provider del rootNavigatorKey para que otros servicios accedan al contexto.
final rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return rootNavigatorKey;
});

/// Notifier que convierte el stream de auth en un [ChangeNotifier]
/// para que GoRouter reevalúe sus redirects sin recrear el router completo.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

/// Transición suave compartida para todas las rutas.
CustomTransitionPage<T> _buildPageTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeIn = CurveTween(curve: Curves.easeOutCubic).animate(animation);
      final slideIn = Tween<Offset>(
        begin: const Offset(0.04, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);

      // Secondary (when another page pushes on top)
      final fadeOut = Tween<double>(begin: 1.0, end: 0.94)
          .chain(CurveTween(curve: Curves.easeInCubic))
          .animate(secondaryAnimation);

      return FadeTransition(
        opacity: fadeIn,
        child: SlideTransition(
          position: slideIn,
          child: ScaleTransition(
            scale: fadeOut,
            child: child,
          ),
        ),
      );
    },
  );
}

/// Provider del router principal.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    observers: [SentryNavigatorObserver()],
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isAuthenticated = authState.valueOrNull != null;
      final publicRoutes = {
        RoutePaths.login,
        RoutePaths.register,
        RoutePaths.splash,
        RoutePaths.welcome,
        RoutePaths.forgotPassword,
        RoutePaths.emailVerification,
        RoutePaths.resetPassword,
      };
      // Las rutas de carta digital tambien son publicas
      final isDigitalMenu = state.matchedLocation.startsWith('/menu/');
      final isPublicRoute =
          publicRoutes.contains(state.matchedLocation) || isDigitalMenu;

      // Si no esta autenticado y no esta en una ruta publica, redirigir al welcome
      if (!isAuthenticated && !isPublicRoute) {
        return RoutePaths.welcome;
      }

      // Si esta autenticado y esta en login/welcome/splash, redirigir según tipo.
      // NOTA: /register NO se incluye aquí porque el signUp dispara un auth
      // state change ANTES de que el tenant sea creado, causando un redirect
      // prematuro. La register_page maneja su propia navegación post-signup.
      if (isAuthenticated &&
          (state.matchedLocation == RoutePaths.login ||
              state.matchedLocation == RoutePaths.welcome ||
              state.matchedLocation == RoutePaths.splash)) {
        final user = authState.valueOrNull;
        if (user != null && user.isPlatformAdmin) {
          return RoutePaths.admin;
        }
        if (user != null && user.hasTenants) {
          // Comprobar si el onboarding está completo
          final onboardingDone = ref.read(onboardingCompleteProvider);
          if (!onboardingDone) {
            return RoutePaths.restaurantOnboarding;
          }
          return RoutePaths.tables;
        }
        return RoutePaths.marketplace;
      }

      return null;
    },
    routes: [
      // -----------------------------------------------------------------------
      // Auth Routes
      // -----------------------------------------------------------------------
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const SplashPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.welcome,
        name: RouteNames.welcome,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const WelcomePage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const RegisterPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const ForgotPasswordPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.emailVerification,
        name: RouteNames.emailVerification,
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return _buildPageTransition(
            context: context,
            state: state,
            child: EmailVerificationPage(email: email),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.resetPassword,
        name: RouteNames.resetPassword,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const ResetPasswordPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.editProfile,
        name: RouteNames.editProfile,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const EditProfilePage(),
        ),
      ),

      // -----------------------------------------------------------------------
      // Restaurant Onboarding
      // -----------------------------------------------------------------------
      GoRoute(
        path: RoutePaths.restaurantOnboarding,
        name: RouteNames.restaurantOnboarding,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const RestaurantOnboardingPage(),
        ),
      ),

      // -----------------------------------------------------------------------
      // Restaurant Shell (StatefulShellRoute for nested navigation)
      // -----------------------------------------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            RestaurantShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _restaurantNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.tables,
                name: RouteNames.tables,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const TablesPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _ordersNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.orders,
                name: RouteNames.orders,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const OrdersPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _kitchenNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.kitchen,
                name: RouteNames.kitchen,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const KitchenDisplayPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _menuNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.menu,
                name: RouteNames.menu,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const MenuManagementPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _inventoryNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.inventory,
                name: RouteNames.inventory,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const InventoryPage(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Restaurant secondary routes (full screen, not in shell)
      GoRoute(
        path: RoutePaths.restaurantDashboard,
        name: RouteNames.restaurantDashboard,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const DashboardPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.employees,
        name: RouteNames.employees,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const EmployeesPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.inviteEmployee,
        name: RouteNames.inviteEmployee,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const InviteEmployeePage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.invitationTemplate,
        name: RouteNames.invitationTemplate,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const InvitationTemplatePage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.analytics,
        name: RouteNames.analytics,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const AnalyticsPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const SettingsPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.restaurantSettings,
        name: RouteNames.restaurantSettings,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const RestaurantSettingsPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.customRoles,
        name: RouteNames.customRoles,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const CustomRolesPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.activityLogs,
        name: RouteNames.activityLogs,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const ActivityLogsPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.restaurantHours,
        name: RouteNames.restaurantHours,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const RestaurantHoursPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.tableEditor,
        name: RouteNames.tableEditor,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const TableEditorPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.tableOrder,
        name: RouteNames.tableOrder,
        pageBuilder: (context, state) {
          final tableId = state.uri.queryParameters['tableId'] ?? '';
          return _buildPageTransition(
            context: context,
            state: state,
            child: TableOrderPage(tableId: tableId),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.tableHistory,
        name: RouteNames.tableHistory,
        pageBuilder: (context, state) {
          final tableId = state.uri.queryParameters['tableId'] ?? '';
          return _buildPageTransition(
            context: context,
            state: state,
            child: TableHistoryPage(tableId: tableId),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.tableStats,
        name: RouteNames.tableStats,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const TableStatsPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.orderHistory,
        name: RouteNames.orderHistory,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const OrderHistoryPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.menuDesignEditor,
        name: RouteNames.menuDesignEditor,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const MenuDesignEditorPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.menuQr,
        name: RouteNames.menuQr,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const MenuQrPage(),
        ),
      ),

      // -----------------------------------------------------------------------
      // Marketplace Shell
      // -----------------------------------------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MarketplaceShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _marketplaceNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.marketplace,
                name: RouteNames.marketplaceHome,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const MarketplaceHomePage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _marketplaceSearchNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.marketplaceSearch,
                name: RouteNames.marketplaceSearch,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const SearchPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _marketplaceCartNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.cart,
                name: RouteNames.cart,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const CartPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _marketplaceProfileNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.customerProfile,
                name: RouteNames.customerProfile,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const ProfilePage(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Marketplace full-screen routes
      GoRoute(
        path: RoutePaths.restaurantDetail,
        name: RouteNames.restaurantDetail,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: RestaurantMenuPage(restaurantId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: RoutePaths.checkout,
        name: RouteNames.checkout,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const CheckoutPage(),
        ),
      ),
      GoRoute(
        path: '${RoutePaths.marketplace}/order/:orderId',
        name: RouteNames.orderTracking,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: OrderTrackingPage(orderId: state.pathParameters['orderId']!),
        ),
      ),
      GoRoute(
        path: RoutePaths.customerOrders,
        name: RouteNames.customerOrders,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const CustomerOrdersPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.customerFavorites,
        name: RouteNames.customerFavorites,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: const FavoritesPage(),
        ),
      ),

      // -----------------------------------------------------------------------
      // Digital Menu (public, no auth required)
      // -----------------------------------------------------------------------
      GoRoute(
        path: RoutePaths.digitalMenu,
        name: RouteNames.digitalMenu,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: DigitalMenuPage(restaurantId: state.pathParameters['id']!),
        ),
      ),

      // -----------------------------------------------------------------------
      // Admin Shell
      // -----------------------------------------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdminShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _adminNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.admin,
                name: RouteNames.adminDashboard,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const AdminDashboardPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _adminRestaurantsNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.adminRestaurants,
                name: RouteNames.adminRestaurants,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const AdminRestaurantsPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _adminAnalyticsNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.adminAnalytics,
                name: RouteNames.adminAnalytics,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const AdminAnalyticsPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _adminIncidentsNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.adminIncidents,
                name: RouteNames.adminIncidents,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const AdminIncidentsPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _adminModerationNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.adminModeration,
                name: RouteNames.adminModeration,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const AdminModerationPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _adminSubscriptionsNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.adminSubscriptions,
                name: RouteNames.adminSubscriptions,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const AdminSubscriptionsPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _adminAuditNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.adminAudit,
                name: RouteNames.adminAudit,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const AdminAuditPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _adminMonitoringNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.adminMonitoring,
                name: RouteNames.adminMonitoring,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const AdminMonitoringPage(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Admin full-screen detail routes
      GoRoute(
        path: RoutePaths.adminRestaurantDetail,
        name: RouteNames.adminRestaurantDetail,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: AdminRestaurantDetailPage(
            restaurantId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.adminIncidentDetail,
        name: RouteNames.adminIncidentDetail,
        pageBuilder: (context, state) => _buildPageTransition(
          context: context,
          state: state,
          child: AdminIncidentDetailPage(incidentId: state.pathParameters['id']!),
        ),
      ),
    ],
    errorBuilder: (context, state) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIcons.compassTool(),
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.pageNotFound(state.matchedLocation),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () => context.go(RoutePaths.splash),
                    icon: Icon(PhosphorIcons.house(), size: 20),
                    label: Text(l10n.errorBackHome),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
});
