import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/app_icons.dart';
import '../../../data/mock_data.dart';
import '../../../models/order.dart';
import '../../../state/orders_state.dart';
import '../../../state/orders_tab_state.dart';
import '../../../state/client_preferences_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/contact_launcher.dart';
import '../../../widgets/remote_image.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(ordersTabProvider);
    final notifier = ref.read(ordersTabProvider.notifier);
    final activeOrders = ref.watch(ordersProvider);
    final orders = tab == 0 ? activeOrders : kCompletedOrders;
    final language = ref.watch(clientPreferencesProvider).language;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          children: [
             Text(clientLabel('Your orders', 'Oda zako', language), style: AppText.serif(fontSize: 28, color: AppColors.clientText(context))),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(4),
               decoration: BoxDecoration(color: AppColors.isClientDark(context) ? const Color(0xFF182631) : AppColors.creamDark, borderRadius: BorderRadius.circular(999)),
              child: Row(
                children: [
                   Expanded(child: _TabButton(label: clientLabel('Active', 'Inayoendelea', language), active: tab == 0, onTap: () => notifier.pick(0))),
                   Expanded(child: _TabButton(label: clientLabel('Completed', 'Imekamilika', language), active: tab == 1, onTap: () => notifier.pick(1))),
                ],
              ),
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < orders.length; i++) ...[
              _OrderCard(
                order: orders[i],
                showContact: tab == 0,
                language: language,
                         onTap: () => context.push('/order-detail', extra: orders[i].id),
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
      color: active ? AppColors.clientSurfaceRaised(context) : Colors.transparent,
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
  const _OrderCard({required this.order, required this.onTap, required this.language, this.showContact = false});

  final Order order;
  final VoidCallback onTap;
  final String language;

  /// Whether to show the WhatsApp/call buttons — only for active orders (a
  /// customer only needs to reach the vendor while an order is in progress).
  final bool showContact;

  @override
  Widget build(BuildContext context) {
    final shop = shopByName(order.shop);
    return Material(
       color: AppColors.clientSurface(context),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
             border: Border.all(color: AppColors.clientBorder(context)),
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
                        Text(order.shop, style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.clientText(context))),
                        const SizedBox(height: 3),
                        Text(
                          '${order.id} · ${order.items}',
                           style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
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
                     style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.clientSecondaryText(context)),
                  ),
                  Row(
                    children: [
                      Text(
                        order.total,
                        style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.teal),
                      ),
                      if (showContact && shop != null) ...[
                        const SizedBox(width: 10),
                        _ContactIconButton(
                          icon: AppIcons.whatsapp,
                          bg: AppColors.tealMuted,
                          iconColor: AppColors.teal,
                          onTap: () async {
                            final ok = await launchWhatsAppChat(shop.phone);
                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(clientLabel("Couldn't open WhatsApp.", 'Imeshindwa kufungua WhatsApp.', language))),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        _ContactIconButton(
                          icon: AppIcons.phone,
                          bg: AppColors.teal,
                          iconColor: AppColors.cream,
                          onTap: () async {
                            final ok = await launchPhoneCall(shop.phone);
                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(clientLabel("Couldn't start the call.", 'Imeshindwa kupiga simu.', language))),
                              );
                            }
                          },
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

class _ContactIconButton extends StatelessWidget {
  const _ContactIconButton({required this.icon, required this.bg, required this.iconColor, required this.onTap});

  final String icon;
  final Color bg;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(width: 36, height: 36, child: Center(child: AppIcon(icon, size: 17, color: iconColor))),
      ),
    );
  }
}
