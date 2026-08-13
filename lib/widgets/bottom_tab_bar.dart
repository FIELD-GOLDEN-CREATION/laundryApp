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
  TabBarItem(icon: AppIcons.tabChat, label: 'Chat'),
  TabBarItem(
    icon: AppIcons.tabProfile,
    label: 'Profile',
    gateReason: 'Log in to see your profile, addresses and saved shops.',
  ),
];

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
