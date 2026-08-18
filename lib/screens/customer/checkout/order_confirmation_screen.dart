import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/order.dart';
import '../../../state/client_preferences_state.dart';
import '../../../state/orders_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/primary_cta_bar.dart';

/// Shown right after the client finishes scheduling — the client pays later
/// (at pickup/drop-off), so this just confirms the order was placed with a
/// receipt-style summary of the order details, instead of dropping straight
/// into Track.
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
    final language = ref.watch(clientPreferencesProvider).language;
    final isSelf = order?.fulfillment == 'self';

    return Scaffold(
      backgroundColor: AppColors.isClientDark(context) ? const Color(0xFF0A1117) : AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const _SuccessBadge(),
              const SizedBox(height: 22),
              Text(clientLabel('Order placed!', 'Oda imewekwa!', language), style: AppText.serif(fontSize: 26, color: AppColors.clientText(context)), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                order == null
                    ? clientLabel('Your laundry is scheduled.', 'Nguo zako zimepangwa.', language)
                    : isSelf
                        ? clientLabel(
                            'Promise order: bring ${order.items} to ${order.shop} on ${order.pickup.isEmpty ? 'your chosen day' : order.pickup} and pay at the counter.',
                            'Oda ya ahadi: peleka ${order.items} kwenye ${order.shop} siku ya ${order.pickup.isEmpty ? 'uliyochagua' : order.pickup} na ulipe kauntani.',
                            language,
                          )
                        : clientLabel(
                            'Our driver will pick up ${order.items} from ${order.shop} on ${order.pickup.isEmpty ? 'your chosen day' : order.pickup}.',
                            'Dereva wetu atachukua ${order.items} kutoka ${order.shop} siku ya ${order.pickup.isEmpty ? 'uliyochagua' : order.pickup}.',
                            language,
                          ),
                style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context), height: 1.45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (order != null) _ReceiptCard(order: order, isSelf: isSelf, language: language),
              const SizedBox(height: 24),
              Text(
                isSelf
                    ? clientLabel('You can follow your promise order on the Orders page.', 'Unaweza kuifuatilia oda yako kwenye ukurasa wa Oda.', language)
                    : clientLabel('You can follow your laundry live on the Orders page.', 'Unaweza kuifuatilia nguo zako moja kwa moja kwenye ukurasa wa Oda.', language),
                style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: PrimaryCtaBar(
        label: clientLabel('View order status', 'Angalia hali ya oda', language),
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
  const _ReceiptCard({required this.order, required this.isSelf, required this.language});

  final Order order;
  final bool isSelf;
  final String language;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.clientSurface(context),
        border: Border.all(color: AppColors.clientBorder(context)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(label: clientLabel('Order', 'Oda', language), value: order.id, context: context),
          _DetailRow(label: clientLabel('Shop', 'Duka', language), value: order.shop, context: context),
          _DetailRow(label: clientLabel('Items', 'Vitu', language), value: order.items, context: context),
          if (order.pickup.isNotEmpty) _DetailRow(label: isSelf ? clientLabel('Arrive at shop', 'Fika dukani', language) : clientLabel('Pickup', 'Kuchukua', language), value: order.pickup, context: context),
          if (order.address.isNotEmpty) _DetailRow(label: isSelf ? clientLabel('Drop-off address', 'Anwani ya duka', language) : clientLabel('Address', 'Anwani', language), value: order.address, context: context),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: AppColors.clientBorder(context)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(clientLabel('AMOUNT', 'KIASI', language), style: AppText.eyebrow(color: AppColors.clientSecondaryText(context))),
              Text(order.total, style: AppText.sans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.teal)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, required this.context});

  final String label;
  final String value;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label.toUpperCase(),
              style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.clientSecondaryText(context)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.clientText(context)),
            ),
          ),
        ],
      ),
    );
  }
}
