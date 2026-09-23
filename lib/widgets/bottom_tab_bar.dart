import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/icons/app_icons.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../state/client_preferences_state.dart';

class TabBarItem {
  const TabBarItem({required this.icon, required this.label, this.gateReason});
  final String icon;
  final String label;

  /// Ports the source's `gated: 'reason'` — when set and the current user
  /// is still a guest, the shell should redirect to Login with this reason
  /// instead of switching to this tab. Only customer tabs use this.
  final String? gateReason;
}

/// Customer tabs: Packages, Explore, Home (raised center), Orders, Profile.
/// Branch order in the router must match these indices.
const kCustomerTabs = [
  TabBarItem(icon: AppIcons.tabCatalog, label: 'Packages'),
  TabBarItem(icon: AppIcons.tabSearch, label: 'Explore'),
  TabBarItem(icon: AppIcons.tabHome, label: 'Home'),
  TabBarItem(
    icon: AppIcons.tabOrders,
    label: 'Orders',
    gateReason: 'Log in to see your orders.',
  ),
  TabBarItem(
    icon: AppIcons.tabProfile,
    label: 'Profile',
    gateReason: 'Log in to see your profile, addresses and saved shops.',
  ),
];

const _kCustomerTabLabelsSw = [
  'Vifurushi',
  'Tafuta',
  'Nyumbani',
  'Oda',
  'Wasifu',
];

/// Customer navigation: floating rounded bar with a raised center Home
/// button. Light: white bar, black center. Dark: dark bar, teal center.
/// Sky: cloud-blue bar, white center.
class FloatingCustomerNavBar extends ConsumerWidget {
  const FloatingCustomerNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(clientPreferencesProvider).language;
    final prefs = ref.watch(clientPreferencesProvider);
    final dark = prefs.dark;
    final sky = prefs.sky;

    final barColor = sky
        ? AppColors.skyBlue.withValues(alpha: 0.85)
        : dark
        ? const Color(0xFF141E28)
        : Colors.white;
    final centerColor = sky
        ? Colors.white
        : dark
        ? AppColors.teal
        : const Color(0xFF101418);
    final centerIconColor = sky
        ? AppColors.skyBlue
        : dark
        ? AppColors.cream
        : Colors.white;
    final activeColor = sky || dark ? Colors.white : const Color(0xFF101418);
    final inactiveColor = sky
        ? Colors.white.withValues(alpha: 0.65)
        : dark
        ? AppColors.tabInactive
        : const Color(0xFF9AA3AD);

    Widget slot(int i) {
      // Center Home slot is a fixed narrow gap so the raised circle
      // overlaps the bar with no dead sideways space.
      if (i == 2) return const SizedBox(width: 64);
      final item = kCustomerTabs[i];
      final active = i == currentIndex;
      final color = active ? activeColor : inactiveColor;
      final pill = active
          ? sky
                ? Colors.white.withValues(alpha: 0.24)
                : dark
                ? const Color(0xFF6CC9BC).withValues(alpha: 0.2)
                : AppColors.teal.withValues(alpha: 0.12)
          : Colors.transparent;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: pill,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(item.icon, size: 21, color: color),
                const SizedBox(height: 4),
                Text(
                  clientLabel(item.label, _kCustomerTabLabelsSw[i], language),
                  style: AppText.sans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      // Always transparent — the bar floats over the page, which shows
      // behind and around it in every theme.
      color: Colors.transparent,
      child: SizedBox(
        height: 108,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 22,
              right: 22,
              bottom: 14,
              child: Material(
                color: barColor,
                borderRadius: BorderRadius.circular(28),
                elevation: 12,
                shadowColor: Colors.black.withValues(alpha: 0.22),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [slot(0), slot(1), slot(2), slot(3), slot(4)],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  color: centerColor,
                  shape: const CircleBorder(),
                  elevation: 10,
                  shadowColor: Colors.black.withValues(alpha: 0.3),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onTap(2),
                    child: SizedBox(
                      width: 58,
                      height: 58,
                      child: Center(
                        child: AppIcon(
                          AppIcons.tabHome,
                          size: 24,
                          color: centerIconColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const kVendorTabs = [
  TabBarItem(icon: AppIcons.tabDash, label: 'Dashboard'),
  TabBarItem(icon: AppIcons.tabOrders, label: 'Orders'),
  TabBarItem(icon: AppIcons.tabCatalog, label: 'Catalog'),
  TabBarItem(icon: AppIcons.tabReports, label: 'Promos'),
  TabBarItem(icon: AppIcons.tabReports, label: 'Earnings'),
];

/// Bottom tab bar ported from the source's `tabs` render block: active tab
/// gets a teal-muted pill behind its icon and teal text/icon; inactive tabs
/// are a flat neutral gray. Item set varies by role (see the 3 const lists
/// above) — the shell around this widget owns which list is passed in.
class AppBottomTabBar extends StatelessWidget {
  const AppBottomTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<TabBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      color: AppColors.cream,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 18),
      child: Material(
        color: AppColors.slate,
        borderRadius: BorderRadius.circular(28),
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _TabButton(
                  item: items[i],
                  active: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final TabBarItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: active ? 48 : 34,
            height: active ? 48 : 34,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: AppIcon(
              item.icon,
              size: 19,
              color: active ? AppColors.teal : AppColors.tabInactive,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: AppText.sans(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: active ? AppColors.cream : AppColors.tabInactive,
            ),
          ),
        ],
      ),
    );
  }
}
