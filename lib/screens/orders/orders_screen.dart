import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/app_icons.dart';
import '../../data/mock_data.dart';
import '../../models/order.dart';
import '../../state/orders_state.dart';
import '../../state/orders_tab_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/remote_image.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(ordersTabProvider);
    final notifier = ref.read(ordersTabProvider.notifier);
    final activeOrders = ref.watch(ordersProvider);
    final orders = tab == 0 ? activeOrders : kCompletedOrders;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          children: [
            Text('Your orders', style: AppText.serif(fontSize: 28)),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.creamDark, borderRadius: BorderRadius.circular(999)),
              child: Row(
                children: [
                  Expanded(child: _TabButton(label: 'Active', active: tab == 0, onTap: () => notifier.pick(0))),
                  Expanded(child: _TabButton(label: 'Completed', active: tab == 1, onTap: () => notifier.pick(1))),
                ],
              ),
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < orders.length; i++) ...[
              _OrderCard(
                order: orders[i],
                onChat: tab == 0 ? () => context.push('/chat-thread', extra: orders[i].shop) : null,
                onTap: () => context.push('/track', extra: orders[i].id),
              ),
              if (i != orders.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: AppText.sans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: active ? AppColors.teal : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap, this.onChat});

  final Order order;
  final VoidCallback onTap;

  /// Chat entry point — only set for active orders (a customer can only chat
  /// a vendor while an order with them is in progress).
  final VoidCallback? onChat;

  @override
  Widget build(BuildContext context) {
    final shop = shopByName(order.shop);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.creamDark),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 44, height: 44, child: RemoteImage(url: shop?.imageUrl ?? '', fallback: 'Shop', circle: true)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.shop, style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text(
                          '${order.id} · ${order.items}',
                          style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: order.statusBg, borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      order.status,
                      style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, color: order.statusFg),
                    ),
                  ),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 13), child: Divider(height: 1, color: AppColors.cream)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.date,
                    style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                  ),
                  Row(
                    children: [
                      Text(
                        order.total,
                        style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.teal),
                      ),
                      if (onChat != null) ...[
                        const SizedBox(width: 10),
                        Material(
                          color: AppColors.tealMuted,
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: onChat,
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: Center(child: AppIcon(AppIcons.chatBubble, size: 17, color: AppColors.teal)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
