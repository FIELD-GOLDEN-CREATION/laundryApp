import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/app_icons.dart';
import '../../models/order.dart';
import '../../state/orders_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/primary_cta_bar.dart';

/// Shown right after Checkout's "Place order" instead of dropping straight
/// into Track — confirms the order was submitted and points the customer
/// at Orders for live status, since Track used to imply (falsely) that the
/// order had already been picked up.
class OrderConfirmationScreen extends ConsumerWidget {
  const OrderConfirmationScreen({super.key, this.orderId});

  final String? orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    Order? order;
    for (final o in orders) {
      if (o.id == orderId) {
        order = o;
        break;
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(color: AppColors.tealMuted, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const AppIcon(AppIcons.checkCircle, size: 38),
              ),
              const SizedBox(height: 22),
              Text('Order submitted!', style: AppText.serif(fontSize: 25), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                order == null
                    ? "Your order has been submitted and is waiting to be picked up."
                    : 'Order ${order.id} has been submitted to ${order.shop} and is waiting to be picked up.',
                style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.muted, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'You can visit the Orders page anytime to see its real-time status.',
                style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.muted, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context.go('/orders'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      'View order status →',
                      style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.teal),
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: PrimaryCtaBar(label: 'Back to home', onPressed: () => context.go('/home')),
    );
  }
}
