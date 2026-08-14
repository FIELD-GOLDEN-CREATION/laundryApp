import 'package:flutter/material.dart';

import '../core/icons/app_icons.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class TabBarItem {
  const TabBarItem({required this.icon, required this.label, this.gateReason});
  final String icon;
  final String label;

  /// Ports the source's `gated: 'reason'` — when set and the current user
  /// is still a guest, the shell should redirect to Login with this reason
  /// instead of switching to this tab. Only customer tabs use this.
  final String? gateReason;
}

const kCustomerTabs = [
  TabBarItem(icon: AppIcons.tabHome, label: 'Home'),
  TabBarItem(icon: AppIcons.tabSearch, label: 'Explore'),
  TabBarItem(icon: AppIcons.tabOrders, label: 'Orders', gateReason: 'Log in to see your orders.'),
  TabBarItem(
    icon: AppIcons.tabProfile,
    label: 'Profile',
    gateReason: 'Log in to see your profile, addresses and saved shops.',
  ),
];

/// Customer navigation styled as a floating dark capsule with rounded ends.
/// Chat intentionally is not a tab; customers enter it from an active order.
class FloatingCustomerNavBar extends StatelessWidget {
  const FloatingCustomerNavBar({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
      color: AppColors.cream,
      child: Material(
        color: AppColors.slate,
        borderRadius: BorderRadius.circular(28),
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: 0.22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            children: [
              for (var i = 0; i < kCustomerTabs.length; i++)
                Expanded(
                  child: _FloatingTabButton(
                    item: kCustomerTabs[i],
                    active: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingTabButton extends StatelessWidget {
  const _FloatingTabButton({required this.item, required this.active, required this.onTap});

  final TabBarItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(color: active ? Colors.white.withValues(alpha: 0.16) : Colors.transparent, borderRadius: BorderRadius.circular(22)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(item.icon, size: 19, color: active ? AppColors.cream : AppColors.tabInactive),
            const SizedBox(height: 4),
            Text(item.label, style: AppText.sans(fontSize: 9.5, fontWeight: FontWeight.w800, color: active ? AppColors.cream : AppColors.tabInactive)),
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
  TabBarItem(icon: AppIcons.tabLogistics, label: 'Handoff'),
  TabBarItem(icon: AppIcons.tabReports, label: 'Earnings'),
];

const kAdminTabs = [
  TabBarItem(icon: AppIcons.tabDash, label: 'Dashboard'),
  TabBarItem(icon: AppIcons.tabOrders, label: 'Orders'),
  TabBarItem(icon: AppIcons.tabProfile, label: 'Members'),
  TabBarItem(icon: AppIcons.tabReports, label: 'Reports'),
  TabBarItem(icon: AppIcons.tabSettings, label: 'Settings'),
];

const kDriverTabs = [
  TabBarItem(icon: AppIcons.tabDash, label: 'Shift'),
  TabBarItem(icon: AppIcons.tabOrders, label: 'Queue'),
  TabBarItem(icon: AppIcons.tabReports, label: 'Wallet'),
  TabBarItem(icon: AppIcons.tabProfile, label: 'Profile'),
];

/// Bottom tab bar ported from the source's `tabs` render block: active tab
/// gets a teal-muted pill behind its icon and teal text/icon; inactive tabs
/// are a flat neutral gray. Item set varies by role (see the 3 const lists
/// above) — the shell around this widget owns which list is passed in.
class AppBottomTabBar extends StatelessWidget {
  const AppBottomTabBar({super.key, required this.items, required this.currentIndex, required this.onTap});

  final List<TabBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.creamDark)),
      ),
      padding: const EdgeInsets.only(top: 12),
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
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.item, required this.active, required this.onTap});

  final TabBarItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.teal : AppColors.tabInactive;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 30,
            decoration: BoxDecoration(
              color: active ? AppColors.tealMuted : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: AppIcon(item.icon, size: 19, color: color),
          ),
          const SizedBox(height: 5),
          Text(
            item.label,
            style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
