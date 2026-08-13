import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/order.dart';
import '../../state/orders_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/primary_cta_bar.dart';

/// Shown right after a successful payment — confirms the order with a
/// receipt-style summary (payment method, amount, pickup details) instead of
/// dropping straight into Track.
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
    order ??= orders.isNotEmpty ? orders.first : null;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const _SuccessBadge(),
              const SizedBox(height: 22),
              Text('Order confirmed!', style: AppText.serif(fontSize: 26), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                order == null
                    ? 'Your laundry is scheduled for pickup.'
                    : '${order.items} from ${order.shop} is scheduled for pickup.',
                style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.muted, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (order != null) _ReceiptCard(order: order),
              const SizedBox(height: 24),
              Text(
                'You can follow your laundry live on the Orders page.',
                style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: PrimaryCtaBar(
        label: 'View order status',
        onPressed: () => context.go('/orders'),
      ),
    );
  }
}

/// Expanding ripple rings around an elastic scale-in check — the "success"
/// moment.
class _SuccessBadge extends StatefulWidget {
  const _SuccessBadge();

  @override
  State<_SuccessBadge> createState() => _SuccessBadgeState();
}

class _SuccessBadgeState extends State<_SuccessBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _ripple = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ripple,
            builder: (context, _) {
              final t = _ripple.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  for (var i = 0; i < 2; i++)
                    _Ripple(progress: (t + i * 0.5) % 1.0),
                ],
              );
            },
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 550),
            curve: Curves.elasticOut,
            builder: (context, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(Icons.check_rounded, size: 48, color: AppColors.cream),
            ),
          ),
        ],
      ),
    );
  }
}

class _Ripple extends StatelessWidget {
  const _Ripple({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final size = 84 + progress * 44;
    return Opacity(
      opacity: (1 - progress) * 0.5,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.teal.withValues(alpha: 0.5), width: 2),
        ),
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(label: 'Order', value: order.id),
          _DetailRow(label: 'Shop', value: order.shop),
          _DetailRow(label: 'Items', value: order.items),
          if (order.pickup.isNotEmpty) _DetailRow(label: 'Pickup', value: order.pickup),
          if (order.address.isNotEmpty) _DetailRow(label: 'Address', value: order.address),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: AppColors.creamDark),
          ),
          Row(
            children: [
              _PaymentIcon(label: order.paymentMethod),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PAID WITH', style: AppText.eyebrow()),
                    const SizedBox(height: 3),
                    Text(
                      order.paymentMethod.isEmpty ? 'Payment method' : order.paymentMethod,
                      style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AMOUNT', style: AppText.eyebrow()),
              Text(order.total, style: AppText.sans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.teal)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: Text(
              label.toUpperCase(),
              style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentIcon extends StatelessWidget {
  const _PaymentIcon({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    if (label.startsWith('Mobile money')) {
      icon = Icons.phone_iphone;
    } else if (label.startsWith('Card')) {
      icon = Icons.credit_card;
    } else {
      icon = Icons.payments_outlined;
    }
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(color: AppColors.tealMuted, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, size: 21, color: AppColors.teal),
    );
  }
}
