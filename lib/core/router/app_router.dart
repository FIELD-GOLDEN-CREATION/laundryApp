import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../screens/admin/admin_client_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/admin_driver_screen.dart';
import '../../screens/admin/admin_members_screen.dart';
import '../../screens/admin/admin_orders_screen.dart';
import '../../screens/admin/admin_reports_screen.dart';
import '../../screens/admin/admin_settings_screen.dart';
import '../../screens/admin/admin_vendor_screen.dart';
import '../../screens/cart/cart_screen.dart';
import '../../data/mock_data.dart';
import '../../models/shop.dart';
import '../../screens/checkout/checkout_screen.dart';
import '../../screens/checkout/order_confirmation_screen.dart';
import '../../screens/driver/driver_dash_screen.dart';
import '../../screens/driver/driver_profile_screen.dart';
import '../../screens/driver/driver_queue_screen.dart';
import '../../screens/driver/driver_wallet_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/login/login_screen.dart';
import '../../screens/login/register_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/orders/orders_screen.dart';
import '../../screens/orders/order_detail_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/profile_settings_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/schedule/schedule_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/service/service_vendors_screen.dart';
import '../../screens/shop_detail/shop_detail_screen.dart';
import '../../screens/track/track_order_screen.dart';
import '../../screens/vendor/vendor_catalog_screen.dart';
import '../../screens/vendor/vendor_dashboard_screen.dart';
import '../../screens/vendor/vendor_earnings_screen.dart';
import '../../screens/vendor/vendor_logistics_screen.dart';
import '../../screens/vendor/vendor_order_detail_screen.dart';
import '../../screens/vendor/vendor_orders_screen.dart';
import '../../screens/vendor/vendor_settings_screen.dart';
import '../../state/auth_state.dart';
import '../../widgets/bottom_tab_bar.dart';
import '../../widgets/announcement_banner.dart';

/// Root navigation graph.
///
/// Three disjoint `StatefulShellRoute`s, one per role (customer/vendor/
/// admin) — not one shell with 15 branches — because the source itself has
/// 3 disjoint `tabScreens` arrays with zero screen overlap between roles.
/// Switching role is an explicit `context.go(roleHomePath)` from the Login
/// screen (and from logout), the same imperative style Checkout's "Place
/// order" already uses for `context.go('/track')` — no `redirect:` guard,
/// since the source itself is imperative (`doLogin`/`doLogout`), not
/// guard-based.
///
/// Detail/Cart/Schedule/Checkout/Track/Notifications/Login and the Vendor
/// order-detail + Admin client/vendor/driver detail screens are top-level
/// routes (siblings of the shells, not nested in a branch) so pushing them
/// covers the bottom tab bar entirely — matching the source's
/// `showTabs:false` for those screens.
/// Exposed so code outside the widget tree built by the router (e.g. the
/// startup update checker) can still find a valid BuildContext to show
/// dialogs against.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => _CustomerTabShell(shell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/search', builder: (_, _) => const SearchScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())]),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => _RoleTabShell(shell: navigationShell, items: kVendorTabs),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/vendor/dashboard', builder: (_, _) => const VendorDashboardScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/vendor/orders', builder: (_, _) => const VendorOrdersScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/vendor/catalog', builder: (_, _) => const VendorCatalogScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/vendor/logistics', builder: (_, _) => const VendorLogisticsScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/vendor/earnings', builder: (_, _) => const VendorEarningsScreen())]),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => _RoleTabShell(shell: navigationShell, items: kAdminTabs),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/admin/dashboard', builder: (_, _) => const AdminDashboardScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/admin/orders', builder: (_, _) => const AdminOrdersScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/admin/members', builder: (_, _) => const AdminMembersScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/admin/reports', builder: (_, _) => const AdminReportsScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/admin/settings', builder: (_, _) => const AdminSettingsScreen())]),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => _RoleTabShell(shell: navigationShell, items: kDriverTabs),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/driver/dash', builder: (_, _) => const DriverDashScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/driver/queue', builder: (_, _) => const DriverQueueScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/driver/wallet', builder: (_, _) => const DriverWalletScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/driver/alerts', builder: (_, _) => const NotificationsScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/driver/profile', builder: (_, _) => const DriverProfileScreen())]),
      ],
    ),
    GoRoute(
      path: '/detail',
      builder: (_, state) => ShopDetailScreen(shop: (state.extra as Shop?) ?? kShops.first),
    ),
    GoRoute(path: '/service-vendors', builder: (_, state) => ServiceVendorsScreen(service: (state.extra as String?) ?? 'Ironing')),
    GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
    GoRoute(path: '/schedule', builder: (_, _) => const ScheduleScreen()),
    GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
    GoRoute(
      path: '/order-confirmation',
      builder: (_, state) => OrderConfirmationScreen(orderId: state.extra as String?),
    ),
    GoRoute(path: '/track', builder: (_, state) => TrackOrderScreen(orderId: state.extra as String?)),
    GoRoute(path: '/order-detail', builder: (_, state) => OrderDetailScreen(orderId: state.extra as String?)),
    GoRoute(path: '/notifs', builder: (_, _) => const NotificationsScreen()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
    GoRoute(path: '/profile/settings', builder: (_, _) => const ProfileSettingsScreen()),
    GoRoute(path: '/profile/edit', builder: (_, _) => const EditProfileScreen()),
    GoRoute(path: '/profile/settings', builder: (_, _) => const ProfileSettingsScreen()),
    GoRoute(path: '/profile/edit', builder: (_, _) => const EditProfileScreen()),
    GoRoute(path: '/vendor/order-detail', builder: (_, _) => const VendorOrderDetailScreen()),
    GoRoute(path: '/vendor/settings', builder: (_, _) => const VendorSettingsScreen()),
    GoRoute(path: '/admin/client', builder: (_, _) => const AdminClientScreen()),
    GoRoute(path: '/admin/vendor', builder: (_, _) => const AdminVendorScreen()),
    GoRoute(path: '/admin/driver', builder: (_, _) => const AdminDriverScreen()),
  ],
);

class _CustomerTabShell extends ConsumerWidget {
  const _CustomerTabShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          const AnnouncementBanner(),
          Expanded(child: shell),
        ],
      ),
      bottomNavigationBar: FloatingCustomerNavBar(
        currentIndex: shell.currentIndex,
        onTap: (i) {
          final reason = kCustomerTabs[i].gateReason;
          if (reason != null && gateGuest(ref, context, reason)) return;
          shell.goBranch(i, initialLocation: i == shell.currentIndex);
        },
      ),
    );
  }
}

/// Shared by the Vendor and Admin shells — neither has any gated tabs (you
/// only ever land in one by having already logged in), so unlike the
/// customer shell this is a plain role-agnostic tab switcher.
class _RoleTabShell extends StatelessWidget {
  const _RoleTabShell({required this.shell, required this.items});

  final StatefulNavigationShell shell;
  final List<TabBarItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AnnouncementBanner(),
          Expanded(child: shell),
        ],
      ),
      bottomNavigationBar: AppBottomTabBar(
        items: items,
        currentIndex: shell.currentIndex,
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}
