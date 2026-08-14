import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock_data.dart';
import '../../models/order.dart';
import '../../state/client_preferences_state.dart';
import '../../state/orders_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/curved_clipper.dart';
import '../../widgets/remote_image.dart';
import '../../widgets/round_back_button.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, this.orderId});
  final String? orderId;

  Order _findOrder(WidgetRef ref) {
    final active = ref.read(ordersProvider);
    for (final order in [...active, ...kCompletedOrders]) {
      if (order.id == orderId) return order;
    }
    return active.isNotEmpty ? active.first : kCompletedOrders.first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = _findOrder(ref);
    final language = ref.watch(clientPreferencesProvider).language;
    final dark = AppColors.isClientDark(context);
    final surface = AppColors.clientSurface(context);
    final status = order.fulfillment == 'self' ? selfOrderStatusForStep(order.trackStep) : orderStatusForStep(order.trackStep);

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF080D12) : AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(children: [
            Container(
              color: AppColors.slate,
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              child: Row(children: [
                RoundBackButton(onPressed: () => context.pop()),
                const SizedBox(width: 12),
                Expanded(child: Text(clientLabel('Order details', 'Maelezo ya oda', language), style: AppText.serif(fontSize: 23, color: AppColors.cream))),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: status.bg, borderRadius: BorderRadius.circular(99)), child: Text(status.label, style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: status.fg))),
              ]),
            ),
            Transform.translate(
              offset: const Offset(0, -1),
              child: ClipPath(
                clipper: const CurvedTopClipper(depth: 28, lift: -18),
                child: Container(
                  color: surface,
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 28),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${clientLabel('Order', 'Oda', language)} ${order.id}', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.clientSecondaryText(context))),
                    const SizedBox(height: 4),
                    Text(order.shop, style: AppText.serif(fontSize: 24, color: AppColors.clientText(context))),
                    const SizedBox(height: 4),
                    Text('${order.date} · ${order.items}', style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context))),
                    const SizedBox(height: 18),
                    _InfoRow(icon: Icons.location_on_outlined, label: order.fulfillment == 'self' ? clientLabel('Drop-off', 'Anwani ya kupeleka', language) : clientLabel('Pickup address', 'Anwani ya kuchukua', language), value: order.address.isEmpty ? clientLabel('Address from your schedule', 'Anwani kutoka kwenye ratiba yako', language) : order.address),
                    const SizedBox(height: 10),
                    _InfoRow(icon: Icons.schedule_rounded, label: order.fulfillment == 'self' ? clientLabel('Drop-off window', 'Muda wa kupeleka', language) : clientLabel('Pickup window', 'Muda wa kuchukua', language), value: order.pickup.isEmpty ? clientLabel('Scheduled pickup', 'Kuchukua kulikopangwa', language) : order.pickup),
                    if (order.fulfillment == 'delivery' && order.driver.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _InfoRow(icon: Icons.person_pin_circle_outlined, label: clientLabel('Your driver', 'Dereva wako', language), value: order.driver),
                    ],
                    const SizedBox(height: 22),
                    Text(clientLabel('Order summary', 'Muhtasari wa oda', language), style: AppText.eyebrow(color: AppColors.clientSecondaryText(context))),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: AppColors.isClientDark(context) ? const Color(0xFF182631) : AppColors.cream, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.clientBorder(context))),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          SizedBox(width: 58, height: 58, child: RemoteImage(url: shopByName(order.shop)?.imageUrl ?? '', fallback: 'Laundry', borderRadius: 14)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(order.shop, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.clientText(context))), const SizedBox(height: 3), Text(order.items, style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)))])),
                          Text(order.total, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.teal)),
                        ]),
                        if (order.lines.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Divider(height: 1, color: AppColors.clientBorder(context)),
                          const SizedBox(height: 12),
                          for (final line in order.lines) ...[
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Expanded(child: Text('${line.qty}× ${line.name}', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.clientText(context)))),
                              Text(formatMoney(line.total), style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.clientSecondaryText(context))),
                            ]),
                            if (line != order.lines.last) const SizedBox(height: 8),
                          ],
                        ],
                      ]),
                    ),
                    if (order.fulfillment == 'delivery' && order.deliveryFeeTzs > 0) ...[
                      const SizedBox(height: 14),
                      _TotalRow(label: clientLabel('Delivery fee', 'Nauli ya usafirishaji', language), value: formatMoney(order.deliveryFeeTzs.toDouble()), strong: false, context: context),
                    ],
                    const SizedBox(height: 10),
                    _TotalRow(label: clientLabel('Total', 'Jumla', language), value: order.total, strong: true, context: context),
                    const SizedBox(height: 18),
                    SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => context.push('/track', extra: order.id), icon: const Icon(Icons.location_on_outlined, size: 17), label: Text(clientLabel('Track order', 'Fuatilia oda', language), style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800)), style: FilledButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: AppColors.cream, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon; final String label; final String value;
  @override
  Widget build(BuildContext context) => Row(children: [Icon(icon, color: AppColors.teal, size: 19), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: AppText.eyebrow(color: AppColors.clientSecondaryText(context))), const SizedBox(height: 2), Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.clientText(context)))]))]);
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value, required this.strong, required this.context});
  final String label; final String value; final bool strong; final BuildContext context;
  @override
  Widget build(BuildContext _) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: AppText.sans(fontSize: strong ? 15 : 13, fontWeight: strong ? FontWeight.w800 : FontWeight.w600, color: AppColors.clientText(context))), Text(value, style: AppText.sans(fontSize: strong ? 16 : 13, fontWeight: FontWeight.w800, color: strong ? AppColors.teal : AppColors.clientSecondaryText(context)))]);
}
