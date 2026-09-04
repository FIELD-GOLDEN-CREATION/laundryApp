import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/app_icons.dart';
import '../chat/chat_screen.dart';
import '../../../models/order.dart';
import '../../../models/track_step_def.dart';
import '../../../services/api_service.dart';
import '../../../state/orders_state.dart';
import '../../../state/client_preferences_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/time_format.dart';
import '../../../widgets/placeholder_image.dart';
import '../../../widgets/round_back_button.dart';

/// Timeline step titles, index-aligned with `kOrderStatusSteps` — the actual
/// timestamp for each step comes from the order's `tracking` rows (see
/// [_stepTime]).
const _kTrackTitles = [
  'Accepted',
  'Washing in progress',
  'Ready for delivery',
  'Out for delivery',
  'Delivered',
];

const _kSelfTrackTitles = [
  'Dropped at shop',
  'Washing in progress',
  'Ready for collection',
  'Ready for collection',
  'Collected',
];

/// Whether the order has an `order_tracking` row for `kOrderStatusSteps[i]`
/// — the vendor toggles these independently now (see
/// `vendor_order_detail_screen.dart`), so this can't be derived from a
/// single `trackStep` index any more: a later step can be done while an
/// earlier one isn't.
bool _stepDone(Order order, int i) {
  if (i < 0 || i >= kOrderStatusSteps.length) return false;
  final status = kOrderStatusSteps[i];
  return order.tracking.any((t) => t.status == status && t.completedAt != null);
}

/// The real timestamp the order reached `kOrderStatusSteps[i]`, formatted
/// for display — "Pending" for a step not yet reached.
String _stepTime(Order order, int i, {required bool done}) {
  if (i < 0 || i >= kOrderStatusSteps.length) return '';
  final status = kOrderStatusSteps[i];
  for (final t in order.tracking) {
    if (t.status == status && t.completedAt != null) {
      return formatClockTime(t.completedAt!);
    }
  }
  return done ? '' : 'Pending';
}

class TrackOrderScreen extends ConsumerStatefulWidget {
  const TrackOrderScreen({super.key, this.orderId});

  /// Which order to show. Null falls back to the first active order.
  final String? orderId;

  @override
  ConsumerState<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends ConsumerState<TrackOrderScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ordersProvider.notifier).loadOrders();
      ref.read(completedOrdersProvider.notifier).loadOrders();
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      ref.read(ordersProvider.notifier).loadOrders();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders = ref.watch(ordersProvider);
    final completed = ref.watch(completedOrdersProvider);
    final targetId = widget.orderId;

    Order? order;
    var isActive = false;
    if (targetId != null) {
      for (final o in [...activeOrders, ...completed]) {
        if (o.id == targetId) {
          order = o;
          isActive = activeOrders.contains(o);
          break;
        }
      }
    }
    order ??= activeOrders.isNotEmpty ? activeOrders.first : (completed.isNotEmpty ? completed.first : null);

    if (order == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }

    final language = ref.watch(clientPreferencesProvider).language;
    final step = order.trackStep;
    final awaitingPickup = step == kOrderPlacedStep;
    final isSelf = order.fulfillment == 'self';
    final titles = isSelf ? _kSelfTrackTitles : _kTrackTitles;
    final driverName = order.driver.isNotEmpty ? order.driver : '';

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 300,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: AppColors.tealMuted),
                  const PlaceholderImage(label: 'Map view of the route'),
                  SafeArea(
                    bottom: false,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        // The source wires this button to goHome (a tab
                        // reset), not the generic back() — always lands on
                        // Home regardless of how Track was reached.
                        child: RoundBackButton(onPressed: () => context.go('/home')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.clientSurfaceRaised(context),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${clientLabel('Order', 'Oda', language)} ${order.id}', style: AppText.serif(fontSize: 23, color: AppColors.clientText(context))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                          decoration: BoxDecoration(
                            color: awaitingPickup ? AppColors.amberLight : AppColors.tealMuted,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isSelf ? selfOrderStatusForStep(step).label : orderStatusForStep(step).label,
                            style: AppText.sans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: awaitingPickup ? AppColors.amber : AppColors.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        for (var i = 0; i < titles.length; i++)
                          _StepTile(
                            step: TrackStepDef(title: titles[i], time: _stepTime(order, i, done: _stepDone(order, i))),
                            done: _stepDone(order, i),
                            isLast: i == titles.length - 1,
                            lineActive: _stepDone(order, i),
                          ),
                      ],
                    ),
                    if (awaitingPickup)
                      isSelf ? _SelfDropOffCard(shop: order.shop, language: language) : const _AwaitingPickupCard()
                    else if (isSelf)
                      _SelfDropOffCard(shop: order.shop, language: language)
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: AppColors.clientSurface(context),
                          border: Border.all(color: AppColors.clientBorder(context)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 48,
                              height: 48,
                              child: PlaceholderImage(label: 'Driver', circle: true),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(driverName, style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.clientText(context))),
                                  const SizedBox(height: 2),
                                  Text(
                                    clientLabel('Your pickup driver · 4.9 ★', 'Dereva wako wa kuchukua · 4.9 ★', language),
                                    style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
                                  ),
                                ],
                              ),
                            ),
                            _RoundIconButton(
                              icon: AppIcons.chatBubble,
                              bg: AppColors.tealMuted,
                              iconColor: AppColors.teal,
                              // The source wires this to goChat, which is
                              // also a tab-switch (this.tab('chat')), not a
                              // push.
                               onTap: () => showChatPanel(context, order!.shop),
                            ),
                            const SizedBox(width: 8),
                            _RoundIconButton(icon: AppIcons.phone, bg: AppColors.teal, iconColor: AppColors.cream, onTap: () {}),
                          ],
                        ),
                      ),
                    if (isActive) ...[
                      const SizedBox(height: 14),
                      // Show "Mark as Delivered" button when order is out for delivery (step 3)
                      if (step == 3)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _showDeliveredDialog(context, ref, order!, language),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                            label: Text(
                              clientLabel('Mark as Delivered', 'Weka kama Imefikishwa', language),
                              style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              foregroundColor: AppColors.cream,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showDeliveredDialog(BuildContext context, WidgetRef ref, Order order, String language) {
  int rating = 0;
  final commentController = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(color: AppColors.tealMuted, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.check_circle_rounded, size: 30, color: AppColors.teal),
              ),
              const SizedBox(height: 16),
              Text(
                clientLabel('Order Delivered!', 'Oda Imefikishwa!', language),
                style: AppText.serif(fontSize: 22),
              ),
              const SizedBox(height: 6),
              Text(
                clientLabel(
                  'How was your experience with ${order.shop}?',
                  'Uzoefu wako na ${order.shop} ulikuwaje?',
                  language,
                ),
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
                            clientLabel('Skip', 'Ruka', language),
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
                                try {
                                  await api.createReview(
                                    order.id,
                                    rating: rating,
                                    comment: commentController.text.trim(),
                                  );
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
                            clientLabel('Submit Review', 'Wasilisha Maoni', language),
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

/// Shown instead of the driver card while an order hasn't been picked up
/// yet — there's no driver assigned to chat with or call.
class _AwaitingPickupCard extends StatelessWidget {
  const _AwaitingPickupCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.clientSurface(context),
        border: Border.all(color: AppColors.clientBorder(context)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: AppColors.amberLight, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const AppIcon(AppIcons.clock, size: 20, color: AppColors.amber),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Waiting for pickup', style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.clientText(context))),
                const SizedBox(height: 2),
                Text(
                  "A driver will be assigned once your order is picked up.",
                  style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelfDropOffCard extends StatelessWidget {
  const _SelfDropOffCard({required this.shop, required this.language});

  final String shop;
  final String language;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.clientSurface(context),
        border: Border.all(color: AppColors.clientBorder(context)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: AppColors.tealMuted, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.storefront_outlined, size: 20, color: AppColors.teal),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(clientLabel('Drop off at shop', 'Peleka kwenye duka', language), style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.clientText(context))),
                const SizedBox(height: 2),
                Text(
                  shop,
                  style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.step, required this.done, required this.isLast, required this.lineActive});

  final TrackStepDef step;
  final bool done;
  final bool isLast;
  final bool lineActive;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.teal : AppColors.clientSurface(context),
                  border: Border.all(color: done ? AppColors.teal : AppColors.clientBorder(context), width: 2),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? AppColors.cream : AppColors.clientBorder(context),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: lineActive ? AppColors.teal : AppColors.clientBorder(context),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: AppText.sans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: done ? AppColors.clientText(context) : AppColors.clientSecondaryText(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    step.time,
                    style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.bg, required this.iconColor, required this.onTap});

  final String icon;
  final Color bg;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(width: 40, height: 40, child: Center(child: AppIcon(icon, size: 18, color: iconColor))),
      ),
    );
  }
}
