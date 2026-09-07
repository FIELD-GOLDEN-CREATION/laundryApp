import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../screens/customer/cart/cart_screen.dart';
import '../../models/shop.dart';
import '../../models/laundry_category.dart';
import '../../state/catalog_state.dart';
import '../../screens/customer/checkout/order_confirmation_screen.dart';
import '../../screens/customer/home/home_screen.dart';
import '../../screens/login/login_screen.dart';
import '../../screens/login/register_screen.dart';
import '../../screens/customer/onboarding/onboarding_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/customer/orders/orders_screen.dart';
import '../../screens/customer/orders/order_detail_screen.dart';
import '../../screens/customer/profile/profile_screen.dart';
import '../../screens/customer/profile/profile_settings_screen.dart';
import '../../screens/customer/profile/edit_profile_screen.dart';
import '../../screens/customer/profile/vendor_apply_screen.dart';
import '../../screens/customer/schedule/schedule_screen.dart';
import '../../screens/customer/search/search_screen.dart';
import '../../screens/customer/service/service_vendors_screen.dart';
import '../../screens/customer/category_detail/category_detail_screen.dart';
import '../../screens/customer/direction/direction_screen.dart';
import '../../screens/customer/shop_detail/shop_detail_screen.dart';
import '../../screens/customer/track/track_order_screen.dart';
import '../../screens/vendor/vendor_catalog_screen.dart';
import '../../screens/vendor/vendor_dashboard_screen.dart';
import '../../screens/vendor/vendor_earnings_screen.dart';
import '../../screens/vendor/vendor_promos_screen.dart';
import '../../screens/vendor/vendor_order_detail_screen.dart';
import '../../screens/vendor/vendor_orders_screen.dart';
import '../../screens/vendor/vendor_settings_screen.dart';
import '../../models/user_role.dart';
import '../../services/realtime_service.dart';
import '../../state/auth_state.dart';
import '../../state/browse_location_state.dart';
import '../../state/notifications_state.dart';
import '../../state/orders_state.dart';
import '../../state/profile_state.dart';
import '../../state/vendor_dashboard_state.dart';
import '../../state/vendor_earnings_state.dart';
import '../../state/vendor_order_detail_state.dart';
import '../../state/vendor_orders_state.dart';
import '../../state/vendor_promos_state.dart';
import '../../widgets/bottom_tab_bar.dart';

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
        StatefulShellBranch(routes: [GoRoute(path: '/vendor/promos', builder: (_, _) => const VendorPromosScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/vendor/earnings', builder: (_, _) => const VendorEarningsScreen())]),
      ],
    ),
    GoRoute(
      path: '/detail',
      builder: (_, state) => Consumer(builder: (_, ref, _) {
        final initialTab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
        final extra = state.extra as Shop?;
        if (extra != null) return ShopDetailScreen(shop: extra, initialTab: initialTab);
        // No explicit shop (e.g. an offer claim) — open the top-ranked one.
        final shops = ref.watch(shopsWithDistanceProvider);
        return shops.isNotEmpty
            ? ShopDetailScreen(shop: shops.first, initialTab: initialTab)
            : const Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 2)));
      }),
    ),
    GoRoute(
      path: '/category-detail',
      builder: (_, state) => CategoryDetailScreen(category: state.extra as LaundryCategory),
    ),
    GoRoute(
      path: '/direction',
      builder: (_, state) => DirectionScreen(shop: state.extra as Shop),
    ),
    GoRoute(
      path: '/service-vendors',
      builder: (_, state) {
        final category = state.extra as LaundryCategory?;
        return ServiceVendorsScreen(categoryId: category?.id ?? '', categoryName: category?.name ?? '');
      },
    ),
    GoRoute(path: '/cart', builder: (_, state) => CartScreen(shopId: state.extra as String? ?? '')),
    GoRoute(path: '/schedule', builder: (_, state) => ScheduleScreen(shopId: state.extra as String? ?? '')),
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
    GoRoute(path: '/profile/apply-vendor', builder: (_, _) => const VendorApplyScreen()),
    GoRoute(path: '/profile/settings', builder: (_, _) => const ProfileSettingsScreen()),
    GoRoute(path: '/profile/edit', builder: (_, _) => const EditProfileScreen()),
    GoRoute(path: '/vendor/order-detail', builder: (_, _) => const VendorOrderDetailScreen()),
    GoRoute(path: '/vendor/settings', builder: (_, _) => const VendorSettingsScreen()),
  ],
);

/// Also owns the realtime (WebSocket) connection lifecycle for the customer
/// role — same pattern as `_RoleTabShell` below, but scoped to just this
/// user's private channel (no shop channel to join). The backend already
/// pushes a `notification.created` event here on every order status change
/// (accept/reject/in_wash/ready/out_for_delivery/delivered — see
/// `VendorOrderController::notifyCustomerStatus`); it just wasn't being
/// listened for anywhere before this.
class _CustomerTabShell extends ConsumerStatefulWidget {
  const _CustomerTabShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<_CustomerTabShell> createState() => _CustomerTabShellState();
}

class _CustomerTabShellState extends ConsumerState<_CustomerTabShell> {
  int? _connectedUserId;
  bool _addressesPrefetched = false;

  @override
  void initState() {
    super.initState();
    _syncRealtime();
    // Deferred via `Future.microtask` — `prefetch()`/`loadAddresses()` both
    // write provider state as their first synchronous statement, which
    // Riverpod disallows from `initState` directly (same reason
    // `shopsProvider.notifier.load()` is deferred like this on Home/Search).
    Future.microtask(() {
      // Warms up GPS the moment the customer's app session starts — well
      // ahead of Search ever opening its location picker — so "Use my
      // current location" there usually resolves instantly off this cache
      // instead of waiting on a live GPS+geocode round trip. Works for
      // guests too, no auth needed.
      ref.read(browseLocationProvider.notifier).prefetch();
      // Covers the case where the session was already restored (customer
      // re-opening the app while still logged in) by the time this shell
      // mounts — the `ref.listen` below only fires on later role changes.
      _prefetchAddressesOnce(ref.read(authProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) {
      _syncRealtime();
      _prefetchAddressesOnce(next);
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: widget.shell,
      ),
      bottomNavigationBar: FloatingCustomerNavBar(
        currentIndex: widget.shell.currentIndex,
        onTap: (i) {
          final reason = kCustomerTabs[i].gateReason;
          if (reason != null && gateGuest(ref, context, reason)) return;
          widget.shell.goBranch(i, initialLocation: i == widget.shell.currentIndex);
        },
      ),
    );
  }

  void _syncRealtime() {
    final auth = ref.read(authProvider);
    if (auth.role != UserRole.customer || auth.userId == 0) {
      if (_connectedUserId != null) _disconnectRealtime();
      return;
    }
    if (_connectedUserId == auth.userId) return;
    _connectedUserId = auth.userId;

    final realtime = RealtimeService.instance;
    realtime.onNotificationEvent = (n) {
      ref.read(notificationsProvider.notifier).handleRealtimeNotification(n);
      final data = n['data'];
      if (data is Map && data['order_id'] != null) {
        ref.read(ordersProvider.notifier).handleRealtimeOrderNotification(n);
        ref.read(completedOrdersProvider.notifier).handleRealtimeOrderNotification(n);
      }
    };
    realtime.connect(userId: auth.userId);
  }

  /// Fires the customer's saved-address fetch once per login session, ahead
  /// of Search opening its location picker, so the "use a saved address"
  /// option there is populated with no loading spinner. Listener-driven
  /// (not a one-shot `initState` check) because session restore is async —
  /// `auth.role` may still read `guest` at the moment this shell first
  /// mounts.
  void _prefetchAddressesOnce(AuthState auth) {
    if (auth.role != UserRole.customer || auth.userId == 0) return;
    if (_addressesPrefetched) return;
    _addressesPrefetched = true;
    ref.read(profileProvider.notifier).loadAddresses();
  }

  void _disconnectRealtime() {
    RealtimeService.instance.disconnect();
    _connectedUserId = null;
  }

  @override
  void dispose() {
    _disconnectRealtime();
    super.dispose();
  }
}

/// Shared by the Vendor and Admin shells — neither has any gated tabs (you
/// only ever land in one by having already logged in), so unlike the
/// customer shell this is a plain role-agnostic tab switcher.
///
/// Also owns the realtime (WebSocket) connection lifecycle for the vendor
/// role: connects once the signed-in user is known (and again, without a
/// full reconnect, once the vendor dashboard's shop id resolves), and
/// disconnects on dispose — i.e. when this whole shell is left, such as on
/// logout. A no-op for any other role.
///
/// One socket, fanned out to every vendor screen's state — dashboard,
/// orders list, order detail, and earnings all react to the same
/// `order.updated`/`new_order` events (each ignoring or debouncing them as
/// appropriate; see each notifier's `handleRealtimeOrderEvent`), since all
/// four branches stay mounted (`IndexedStack`) and can go stale together
/// from one backend action, e.g. accepting an order. Promos additionally
/// react to `promo.updated`, fired when a customer's order redeems one of
/// this shop's codes.
class _RoleTabShell extends ConsumerStatefulWidget {
  const _RoleTabShell({required this.shell, required this.items});

  final StatefulNavigationShell shell;
  final List<TabBarItem> items;

  @override
  ConsumerState<_RoleTabShell> createState() => _RoleTabShellState();
}

class _RoleTabShellState extends ConsumerState<_RoleTabShell> {
  int? _connectedUserId;
  int? _connectedShopId;

  @override
  void initState() {
    super.initState();
    _syncRealtime();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, _) => _syncRealtime());
    ref.listen<int>(vendorDashboardProvider.select((s) => s.shopId), (_, _) => _syncRealtime());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: widget.shell,
      ),
      bottomNavigationBar: AppBottomTabBar(
        items: widget.items,
        currentIndex: widget.shell.currentIndex,
        onTap: (i) => widget.shell.goBranch(i, initialLocation: i == widget.shell.currentIndex),
      ),
    );
  }

  void _syncRealtime() {
    final auth = ref.read(authProvider);
    if (auth.role != UserRole.vendor || auth.userId == 0) {
      if (_connectedUserId != null) _disconnectRealtime();
      return;
    }

    final rawShopId = ref.read(vendorDashboardProvider).shopId;
    final shopId = rawShopId == 0 ? null : rawShopId;
    if (_connectedUserId == auth.userId && _connectedShopId == shopId) return;
    _connectedUserId = auth.userId;
    _connectedShopId = shopId;

    final realtime = RealtimeService.instance;
    realtime.onOrderEvent = (action, order) {
      ref.read(vendorDashboardProvider.notifier).handleRealtimeOrderEvent(action, order);
      ref.read(vendorOrdersProvider.notifier).handleRealtimeOrderEvent(action, order);
      ref.read(vendorOrderDetailProvider.notifier).handleRealtimeOrderEvent(action, order);
      ref.read(vendorEarningsProvider.notifier).handleRealtimeOrderEvent(action, order);
    };
    realtime.onNotificationEvent = (n) =>
        ref.read(vendorDashboardProvider.notifier).handleRealtimeNotification(n);
    realtime.onPromoEvent = (action, promo) =>
        ref.read(vendorPromosProvider.notifier).handleRealtimePromoEvent(action, promo);
    realtime.connect(userId: auth.userId, shopId: shopId);
  }

  void _disconnectRealtime() {
    RealtimeService.instance.disconnect();
    _connectedUserId = null;
    _connectedShopId = null;
  }

  @override
  void dispose() {
    _disconnectRealtime();
    super.dispose();
  }
}
