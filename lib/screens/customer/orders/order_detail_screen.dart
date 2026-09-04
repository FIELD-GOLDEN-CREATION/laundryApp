import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/order.dart';
import '../../../models/review.dart';
import '../../../services/api_service.dart';
import '../../../state/catalog_state.dart';
import '../../../state/client_preferences_state.dart';
import '../../../state/orders_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/cart_math.dart';
import '../../../widgets/curved_clipper.dart';
import '../../../widgets/remote_image.dart';
import '../../../widgets/round_back_button.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, this.orderId});
  final String? orderId;

  Order? _findOrder(WidgetRef ref) {
    final active = ref.watch(ordersProvider);
    final completed = ref.watch(completedOrdersProvider);
    for (final order in [...active, ...completed]) {
      if (order.id == orderId) return order;
    }
    return active.isNotEmpty ? active.first : (completed.isNotEmpty ? completed.first : null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure both lists are loaded so the requested order can resolve.
    ref.listen(ordersProvider, (_, _) {});
    Future.microtask(() {
      ref.read(ordersProvider.notifier).loadOrders();
      ref.read(completedOrdersProvider.notifier).loadOrders();
      ref.read(shopsProvider.notifier).load();
    });
    final order = _findOrder(ref);
    final language = ref.watch(clientPreferencesProvider).language;

    if (order == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }

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
                          SizedBox(width: 58, height: 58, child: RemoteImage(url: ref.watch(shopsProvider).items.where((s) => s.name == order.shop).map((s) => s.imageUrl).firstOrNull ?? '', fallback: 'Laundry', borderRadius: 14)),
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

                    // Payment method section
                    if (order.paymentMethod.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Text(clientLabel('Payment method', 'Njia ya malipo', language), style: AppText.eyebrow(color: AppColors.clientSecondaryText(context))),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.isClientDark(context) ? const Color(0xFF182631) : AppColors.cream,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.clientBorder(context)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(12)),
                              alignment: Alignment.center,
                              child: Icon(
                                order.paymentMethod.contains('Mobile') ? Icons.phone_android_rounded : Icons.credit_card_rounded,
                                size: 18,
                                color: AppColors.teal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(order.paymentMethod, style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.clientText(context))),
                                  const SizedBox(height: 2),
                                  Text(
                                    clientLabel('Saved to your profile', 'Imehifadhiwaswa kwenye wasifu wako', language),
                                    style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.check_circle_rounded, size: 20, color: AppColors.teal),
                          ],
                        ),
                      ),
                    ],

                    // Customer info (name + phone)
                    if (order.customerName.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Text(clientLabel('Your details', 'Maelezo yako', language), style: AppText.eyebrow(color: AppColors.clientSecondaryText(context))),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.isClientDark(context) ? const Color(0xFF182631) : AppColors.cream,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.clientBorder(context)),
                        ),
                        child: Column(
                          children: [
                            _ProfileInfoRow(
                              icon: Icons.person_outline_rounded,
                              label: clientLabel('Name', 'Jina', language),
                              value: order.customerName,
                            ),
                            if (order.customerPhone.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _ProfileInfoRow(
                                icon: Icons.call_outlined,
                                label: clientLabel('Phone', 'Simu', language),
                                value: order.customerPhone,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    // Review section — only once the order has actually
                    // arrived (delivered) / been collected (self pickup),
                    // matching the backend's `status === 'delivered'` gate.
                    if (order.trackStep == 4) ...[
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(clientLabel('Your review', 'Maoni yako', language), style: AppText.eyebrow(color: AppColors.clientSecondaryText(context))),
                          if (order.review != null)
                            Row(
                              children: [
                                _ReviewActionButton(
                                  icon: Icons.edit_outlined,
                                  onTap: () => _showReviewDialog(context, ref, order, language, existing: order.review),
                                ),
                                const SizedBox(width: 6),
                                _ReviewActionButton(
                                  icon: Icons.delete_outline_rounded,
                                  onTap: () => _confirmDeleteReview(context, ref, order, language),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (order.review != null)
                        _ReviewCard(review: order.review!)
                      else
                        _LeaveReviewCard(
                          language: language,
                          onTap: () => _showReviewDialog(context, ref, order, language),
                        ),
                    ],

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

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.teal),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted)),
            const SizedBox(height: 1),
            Text(value, style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.clientText(context))),
          ],
        ),
      ],
    );
  }
}

class _ReviewActionButton extends StatelessWidget {
  const _ReviewActionButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.isClientDark(context) ? const Color(0xFF182631) : AppColors.cream,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(width: 30, height: 30, child: Icon(icon, size: 15, color: AppColors.clientSecondaryText(context))),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.isClientDark(context) ? const Color(0xFF182631) : AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.clientBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (i) => Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(
                i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 18,
                color: i < review.rating ? AppColors.amber : AppColors.creamDark,
              ),
            )),
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.clientText(context))),
          ],
        ],
      ),
    );
  }
}

class _LeaveReviewCard extends StatelessWidget {
  const _LeaveReviewCard({required this.language, required this.onTap});
  final String language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.isClientDark(context) ? const Color(0xFF182631) : AppColors.cream,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.clientBorder(context))),
          child: Row(
            children: [
              const Icon(Icons.star_outline_rounded, size: 20, color: AppColors.teal),
              const SizedBox(width: 10),
              Expanded(child: Text(clientLabel('Leave a review', 'Acha maoni', language), style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.clientText(context)))),
              Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.clientSecondaryText(context)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared create/edit dialog — `existing` prefills the star rating and
/// comment and switches the call from `createReview` to `updateReview`.
void _showReviewDialog(BuildContext context, WidgetRef ref, Order order, String language, {Review? existing}) {
  int rating = existing?.rating ?? 0;
  final commentController = TextEditingController(text: existing?.comment ?? '');
  final isEdit = existing != null;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEdit ? clientLabel('Edit your review', 'Hariri maoni yako', language) : clientLabel('Rate your order', 'Kadiria oda yako', language),
                style: AppText.serif(fontSize: 20),
              ),
              const SizedBox(height: 6),
              Text(
                clientLabel('How was your experience with ${order.shop}?', 'Uzoefu wako na ${order.shop} ulikuwaje?', language),
                textAlign: TextAlign.center,
                style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setDialogState(() => rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 36,
                      color: i < rating ? AppColors.amber : AppColors.creamDark,
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  border: Border.all(color: AppColors.creamDark),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: commentController,
                  maxLines: 3,
                  style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: clientLabel('Leave a comment (optional)', 'Wacha maoni (si lazima)', language),
                    hintStyle: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.creamDark, width: 1.5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          child: Text(
                            clientLabel('Cancel', 'Ghairi', language),
                            style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Material(
                      color: rating > 0 ? AppColors.teal : AppColors.creamDark,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: rating > 0
                            ? () async {
                                final comment = commentController.text.trim();
                                Map<String, dynamic> response;
                                try {
                                  response = isEdit
                                      ? await api.updateReview(order.id, rating: rating, comment: comment)
                                      : await api.createReview(order.id, rating: rating, comment: comment);
                                } on ApiException {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(clientLabel(
                                          'Could not submit your review. Try again.',
                                          'Imeshindikana kuwasilisha maoni. Jaribu tena.',
                                          language,
                                        )),
                                      ),
                                    );
                                  }
                                  return;
                                }
                                final saved = orderReviewFromJson(response['data'] as Map<String, dynamic>?) ??
                                    Review(id: existing?.id ?? 0, rating: rating, comment: comment);
                                ref.read(ordersProvider.notifier).setReview(order.id, saved);
                                ref.read(completedOrdersProvider.notifier).setReview(order.id, saved);
                                if (!ctx.mounted) return;
                                Navigator.of(ctx).pop();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(clientLabel('Thanks for your feedback!', 'Asante kwa maoni yako!', language)),
                                      backgroundColor: AppColors.teal,
                                    ),
                                  );
                                }
                              }
                            : null,
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          child: Text(
                            isEdit ? clientLabel('Save', 'Hifadhi', language) : clientLabel('Submit Review', 'Wasilisha Maoni', language),
                            style: AppText.sans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: rating > 0 ? AppColors.cream : AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ).then((_) => commentController.dispose());
}

void _confirmDeleteReview(BuildContext context, WidgetRef ref, Order order, String language) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(clientLabel('Delete review?', 'Futa maoni?', language), style: AppText.serif(fontSize: 18)),
      content: Text(
        clientLabel("This can't be undone.", 'Hili haliwezi kutenduliwa.', language),
        style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(clientLabel('Cancel', 'Ghairi', language), style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted)),
        ),
        TextButton(
          onPressed: () async {
            try {
              await api.deleteReview(order.id);
            } on ApiException {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(clientLabel('Could not delete your review. Try again.', 'Imeshindikana kufuta maoni. Jaribu tena.', language))),
                );
              }
              return;
            }
            ref.read(ordersProvider.notifier).setReview(order.id, null);
            ref.read(completedOrdersProvider.notifier).setReview(order.id, null);
            if (!ctx.mounted) return;
            Navigator.of(ctx).pop();
          },
          child: Text(clientLabel('Delete', 'Futa', language), style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.red)),
        ),
      ],
    ),
  );
}
