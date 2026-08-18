import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_item.dart';
import '../models/vendor_order.dart';
import '../state/notifications_state.dart';
import '../state/vendor_orders_state.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// The "Reject order" sheet — prompts the vendor for a reason before an
/// incoming order is rejected, so the client can see why.
void showVendorRejectSheet(BuildContext context, WidgetRef ref, VendorOrder order) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _RejectOrderSheet(order: order),
  );
}

class _RejectOrderSheet extends ConsumerStatefulWidget {
  const _RejectOrderSheet({required this.order});
  final VendorOrder order;

  @override
  ConsumerState<_RejectOrderSheet> createState() => _RejectOrderSheetState();
}

class _RejectOrderSheetState extends ConsumerState<_RejectOrderSheet> {
  final _reasonController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'Enter a reason for rejecting this order.');
      return;
    }
    ref.read(vendorOrdersProvider.notifier).rejectOrder(widget.order.id, reason);
    ref.read(notificationsProvider.notifier).addNotification(
      NotificationItem(
        initial: '✕',
        title: 'Order rejected',
        body: 'Marina Fresh Laundry couldn\'t take your order ${widget.order.id}: "$reason"',
        time: 'Just now',
        bg: AppColors.white,
        iconBg: AppColors.dangerLight,
        iconFg: AppColors.danger,
      ),
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.order.id} rejected')));
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
            decoration: const BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: AppColors.creamDark, borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                Text('Reject order?', style: AppText.serif(fontSize: 22)),
                const SizedBox(height: 3),
                Text(
                  "Let ${order.customer} know why you can't take ${order.id}.",
                  style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                Text('REASON', style: AppText.eyebrow()),
                const SizedBox(height: 7),
                Container(
                  constraints: const BoxConstraints(minHeight: 96),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.creamDark), borderRadius: BorderRadius.circular(14)),
                  child: TextField(
                    controller: _reasonController,
                    maxLines: 4,
                    autofocus: true,
                    style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
                    decoration: InputDecoration.collapsed(
                      hintText: "e.g. Fully booked until tomorrow, can't take express orders right now",
                      hintStyle: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.danger)),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(color: AppColors.creamDark, width: 1.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            height: 52,
                            alignment: Alignment.center,
                            child: Text('Cancel', style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.muted)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 7,
                      child: Material(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: _submit,
                          child: Container(
                            height: 52,
                            alignment: Alignment.center,
                            child: Text('Reject order', style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
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
    );
  }
}
