import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/app_icons.dart';
import '../../data/vendor_mock_data.dart';
import '../../models/vendor_order.dart';
import '../../models/vendor_order_decision.dart';
import '../../models/vendor_payment_method.dart';
import '../../state/vendor_orders_state.dart';
import '../../state/vendor_payment_methods_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/currency.dart';
import '../../widgets/vendor_accept_order_sheet.dart';
import '../../widgets/vendor_reject_order_sheet.dart';
import 'vendor_chat_screen.dart';

const _kTabLabels = ['Incoming', 'In progress', 'Ready'];

class VendorOrdersScreen extends ConsumerWidget {
  const VendorOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorOrdersProvider);
    final notifier = ref.read(vendorOrdersProvider.notifier);
    final paymentMethods = ref.watch(vendorPaymentMethodsProvider);
    final orders = switch (state.tab) {
      0 => kVendorOrdersNew,
      1 => kVendorOrdersWip,
      _ => kVendorOrdersReady,
    };

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          children: [
            Text('Orders', style: AppText.serif(fontSize: 28)),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.creamDark, borderRadius: BorderRadius.circular(999)),
              child: Row(
                children: [
                  for (var i = 0; i < _kTabLabels.length; i++)
                    Expanded(
                      child: _SegmentTab(label: _kTabLabels[i], active: state.tab == i, onTap: () => notifier.pickTab(i)),
                    ),
                ],
              ),
            ),
            if (state.tab == 0) ...[
              const SizedBox(height: 16),
              const _IncomingBanner(),
            ],
            const SizedBox(height: 16),
            for (var i = 0; i < orders.length; i++) ...[
              _OrderCard(
                order: orders[i],
                acceptance: state.acceptances[orders[i].id],
                rejectReason: state.rejections[orders[i].id],
                offeredMethods: [
                  for (final id in state.acceptances[orders[i].id]?.paymentMethodIds ?? const <String>[])
                    for (final method in paymentMethods)
                      if (method.id == id) method,
                ],
                onOpen: () => context.push('/vendor/order-detail'),
                onAccept: () => showVendorAcceptFlow(context, ref, orders[i]),
                onReject: () => showVendorRejectSheet(context, ref, orders[i]),
                onChat: orders[i].stage == 'wip' ? () => showVendorChatPanel(context, orders[i].customer) : null,
              ),
              if (i != orders.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({required this.label, required this.active, required this.onTap});

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
              style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: active ? AppColors.teal : AppColors.muted),
            ),
          ),
        ),
      ),
    );
  }
}

class _IncomingBanner extends StatefulWidget {
  const _IncomingBanner();

  @override
  State<_IncomingBanner> createState() => _IncomingBannerState();
}

class _IncomingBannerState extends State<_IncomingBanner> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final t = _controller.value;
                    return Opacity(
                      opacity: 1 - t,
                      child: Transform.scale(
                        scale: 1 + t * 1.6,
                        child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle)),
                      ),
                    );
                  },
                ),
                Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle)),
              ],
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              '3 new requests in the last 10 minutes',
              style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.cream),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.acceptance,
    required this.rejectReason,
    required this.offeredMethods,
    required this.onAccept,
    required this.onReject,
    required this.onOpen,
    this.onChat,
  });

  final VendorOrder order;

  /// Non-null once the vendor has accepted this order — carries the fee and
  /// which saved payment methods were offered. Only meaningful for stage
  /// 'new' orders.
  final VendorOrderAcceptance? acceptance;

  /// Non-null once the vendor has rejected this order — the reason entered.
  final String? rejectReason;

  /// [acceptance]'s payment method ids resolved against the vendor's current
  /// saved methods, so their name/subtitle can be shown even if the id list
  /// itself only has ids.
  final List<VendorPaymentMethod> offeredMethods;

  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onOpen;

  /// Chat entry point — only set for in-progress orders (a vendor can only
  /// message a customer while their order is being worked on).
  final VoidCallback? onChat;

  @override
  Widget build(BuildContext context) {
    final isNew = order.stage == 'new';
    final isAccepted = acceptance != null;
    final isRejected = rejectReason != null;
    final tagFg = order.priority == 'Express' ? AppColors.amber : AppColors.muted;
    final tagBg = order.priority == 'Express' ? AppColors.amberLight : AppColors.creamDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  onTap: onOpen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.customer, style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(
                        '${order.id} · ${order.items} · ${order.dist}',
                        style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(999)),
                child: Text(order.priority, style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, color: tagFg)),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final chip in order.chips)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(7)),
                  child: Text(chip, style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.teal)),
                ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 13), child: Divider(height: 1, color: AppColors.cream)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                    children: [
                      TextSpan(text: '${order.when} · '),
                      TextSpan(text: order.total, style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
              if (onChat != null || !isNew)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onChat != null) ...[
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
                      const SizedBox(width: 10),
                    ],
                    if (!isNew) _SolidButton(label: 'Update status', onTap: onOpen, dense: true),
                  ],
                ),
            ],
          ),
          if (isNew && !isAccepted && !isRejected) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _OutlineButton(label: 'Reject', color: AppColors.danger, onTap: onReject)),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: _SolidButton(label: 'Accept order', onTap: onAccept)),
              ],
            ),
          ],
          if (isAccepted) ...[
            const SizedBox(height: 14),
            _AcceptedSummary(acceptance: acceptance!, offeredMethods: offeredMethods),
          ],
          if (isRejected) ...[
            const SizedBox(height: 14),
            _RejectedSummary(reason: rejectReason!),
          ],
        ],
      ),
    );
  }
}

/// The card's primary action button — solid teal fill, rounded rect (never a
/// full pill, so it reads as a button rather than a status tag). [dense]
/// shrinks it to sit inline next to the chat icon ("Update status"); the
/// default size is for the full-width "Accept order" footer button.
class _SolidButton extends StatelessWidget {
  const _SolidButton({required this.label, required this.onTap, this.dense = false});

  final String label;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.teal,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: dense ? 36 : 46,
          padding: dense ? const EdgeInsets.symmetric(horizontal: 16) : null,
          alignment: Alignment.center,
          child: Text(label, style: AppText.sans(fontSize: dense ? 12.5 : 13.5, fontWeight: FontWeight.w800, color: AppColors.cream)),
        ),
      ),
    );
  }
}

/// The card's secondary action button — bordered, no fill — same "outline"
/// recipe as the Cancel buttons in the accept/reject sheets, just tinted
/// with [color] so "Reject" reads distinctly from a plain Cancel.
class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onTap, required this.color});

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.creamDark, width: 1.5)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          child: Text(label, style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: color)),
        ),
      ),
    );
  }
}

/// The fee + offered-payment-methods readout shown on an accepted order's
/// card — surfaces what the vendor promised the client without needing to
/// reopen the accept sheet.
class _AcceptedSummary extends StatelessWidget {
  const _AcceptedSummary({required this.acceptance, required this.offeredMethods});

  final VendorOrderAcceptance acceptance;
  final List<VendorPaymentMethod> offeredMethods;

  @override
  Widget build(BuildContext context) {
    final fee = double.tryParse(acceptance.fee) ?? 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.teal),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Accepted · fee ${formatTzs(fee)}',
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.teal),
                ),
              ),
            ],
          ),
          if (offeredMethods.isNotEmpty) ...[
            const SizedBox(height: 10),
            Column(
              children: [
                for (var i = 0; i < offeredMethods.length; i++) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offeredMethods[i].title,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          offeredMethods[i].subtitle,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  if (i != offeredMethods.length - 1) const SizedBox(height: 6),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The reason readout shown on a rejected order's card.
class _RejectedSummary extends StatelessWidget {
  const _RejectedSummary({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cancel_rounded, size: 16, color: AppColors.danger),
              const SizedBox(width: 7),
              Text('Rejected', style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.danger)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            reason,
            style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.danger, height: 1.4),
          ),
        ],
      ),
    );
  }
}
