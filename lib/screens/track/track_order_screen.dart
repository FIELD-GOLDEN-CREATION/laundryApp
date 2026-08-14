import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/app_icons.dart';
import '../../data/mock_data.dart';
import '../chat/chat_screen.dart';
import '../../models/order.dart';
import '../../models/track_step_def.dart';
import '../../state/orders_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/placeholder_image.dart';
import '../../widgets/round_back_button.dart';

/// The order shown when Track is opened with no specific order in mind
/// (e.g. Home's "being washed" banner) — the long-running demo order.
const _kDefaultOrderId = '#LD-2481';

class TrackOrderScreen extends ConsumerWidget {
  const TrackOrderScreen({super.key, this.orderId});

  /// Which order to show. Null falls back to the default demo order.
  final String? orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrders = ref.watch(ordersProvider);
    final targetId = orderId ?? _kDefaultOrderId;

    Order? order;
    var isActive = false;
    for (final o in activeOrders) {
      if (o.id == targetId) {
        order = o;
        isActive = true;
        break;
      }
    }
    if (order == null) {
      for (final o in kCompletedOrders) {
        if (o.id == targetId) {
          order = o;
          break;
        }
      }
    }
    order ??= activeOrders.isNotEmpty ? activeOrders.first : kCompletedOrders.first;
    final step = order.trackStep;
    final awaitingPickup = step == kOrderPlacedStep;

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
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                        Text('Order ${order.id}', style: AppText.serif(fontSize: 23)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                          decoration: BoxDecoration(
                            color: awaitingPickup ? AppColors.amberLight : AppColors.tealMuted,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            orderStatusForStep(step).label,
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
                        for (var i = 0; i < kTrackSteps.length; i++)
                          _StepTile(
                            step: kTrackSteps[i],
                            done: i <= step,
                            isLast: i == kTrackSteps.length - 1,
                            lineActive: i < step,
                          ),
                      ],
                    ),
                    if (awaitingPickup)
                      const _AwaitingPickupCard()
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.creamDark),
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
                                  Text('Daniel O.', style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Your pickup driver · 4.9 ★',
                                    style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
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
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => ref.read(ordersProvider.notifier).advanceStep(order!.id),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.creamDark, width: 1.5),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Text(
                                'Demo: advance status',
                                style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.muted),
                              ),
                            ),
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

/// Shown instead of the driver card while an order hasn't been picked up
/// yet — there's no driver assigned to chat with or call.
class _AwaitingPickupCard extends StatelessWidget {
  const _AwaitingPickupCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
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
                Text('Waiting for pickup', style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  "A driver will be assigned once your order is picked up.",
                  style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
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
                  color: done ? AppColors.teal : Colors.white,
                  border: Border.all(color: done ? AppColors.teal : const Color(0xFFD7D2C6), width: 2),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? AppColors.cream : const Color(0xFFD7D2C6),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: lineActive ? AppColors.teal : AppColors.creamDark,
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
                      color: done ? AppColors.slate : AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    step.time,
                    style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
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
