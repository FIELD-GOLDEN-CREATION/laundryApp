import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/app_icons.dart';
import '../../models/vendor_order.dart';
import '../../state/vendor_order_detail_state.dart' show normalizeVendorOrderId;
import '../../state/vendor_orders_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import 'vendor_chat_screen.dart';

const _kTabLabels = ['Incoming', 'In progress', 'Ready'];

class VendorOrdersScreen extends ConsumerStatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  ConsumerState<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends ConsumerState<VendorOrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(vendorOrdersProvider.notifier).loadOrders());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorOrdersProvider);
    final notifier = ref.read(vendorOrdersProvider.notifier);
    final orders = switch (state.tab) {
      0 => state.newOrders,
      1 => state.wipOrders,
      _ => state.readyOrders,
    };
    final loading = state.isLoading && state.orders.isEmpty;

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
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (orders.isEmpty) ...[
              Text(
                'No orders here right now.',
                style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
              ),
            ] else ...[
              for (var i = 0; i < orders.length; i++) ...[
                _OrderCard(
                  order: orders[i],
                  onToggle: () {
                    if (orders[i].stage != 'new') {
                      openDetail(orders[i]);
                    } else {
                      _showAcceptDialog(context, ref, orders[i]);
                    }
                  },
                  onReject: orders[i].stage == 'new' ? () => _showRejectDialog(context, ref, orders[i]) : null,
                  onOpen: () => openDetail(orders[i]),
                  onChat: orders[i].stage == 'wip' ? () => showVendorChatPanel(context, orders[i].customer) : null,
                ),
                if (i != orders.length - 1) const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void openDetail(VendorOrder order) {
    ref.read(vendorOrdersProvider.notifier).openOrder(order);
    context.push('/vendor/order-detail');
  }

  void _showAcceptDialog(BuildContext context, WidgetRef ref, VendorOrder order) {
    final isDelivery = order.fulfillment == 'delivery';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AcceptOrderSheet(order: order, isDelivery: isDelivery),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref, VendorOrder order) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Reject order?', style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Text(
          'This will decline ${order.id} from ${order.customer}. This cannot be undone.',
          style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final ok = await ref.read(vendorOrdersProvider.notifier).rejectOrder(normalizeVendorOrderId(order.id));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? '${order.id} declined' : 'Could not reject ${order.id}'),
                  backgroundColor: ok ? AppColors.danger : AppColors.muted,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: Text('Reject', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.danger)),
          ),
        ],
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

class _IncomingBanner extends ConsumerStatefulWidget {
  const _IncomingBanner();

  @override
  ConsumerState<_IncomingBanner> createState() => _IncomingBannerState();
}

class _IncomingBannerState extends ConsumerState<_IncomingBanner> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newCount = ref.watch(vendorOrdersProvider.select((s) => s.newOrders.length));
    if (newCount == 0) return const SizedBox.shrink();

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
              '$newCount new request${newCount == 1 ? '' : 's'} waiting for your response',
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
    required this.onToggle,
    required this.onOpen,
    this.onReject,
    this.onChat,
  });

  final VendorOrder order;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final VoidCallback? onReject;
  final VoidCallback? onChat;

  @override
  Widget build(BuildContext context) {
    final isNew = order.stage == 'new';
    final active = !isNew;
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
              if (order.fulfillment == 'delivery')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(7)),
                  child: Text('Delivery · ${order.dist}', style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.amber)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.creamDark, borderRadius: BorderRadius.circular(7)),
                  child: Text('Self drop-off', style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.muted)),
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
                  if (isNew && onReject != null) ...[
                    Material(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(999),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: onReject,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Text(
                            'Reject',
                            style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.danger),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Material(
                    color: active ? AppColors.tealMuted : AppColors.teal,
                    borderRadius: BorderRadius.circular(999),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onToggle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Text(
                          isNew ? 'Accept' : 'Update status',
                          style: AppText.sans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: active ? AppColors.teal : AppColors.cream,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AcceptOrderSheet extends ConsumerStatefulWidget {
  const _AcceptOrderSheet({required this.order, required this.isDelivery});

  final VendorOrder order;
  final bool isDelivery;

  @override
  ConsumerState<_AcceptOrderSheet> createState() => _AcceptOrderSheetState();
}

class _AcceptOrderSheetState extends ConsumerState<_AcceptOrderSheet> {
  bool _freeDelivery = true;
  final _feeController = TextEditingController(text: '3500');

  @override
  void dispose() {
    _feeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.creamDark, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 18),
            Text('Accept order', style: AppText.serif(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              '${order.id} · ${order.customer}',
              style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _InfoLine(icon: Icons.person_outline_rounded, label: 'Customer', value: order.customer),
                  const SizedBox(height: 10),
                  _InfoLine(icon: Icons.call_outlined, label: 'Phone', value: order.customerPhone),
                  if (order.customerAddress.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InfoLine(icon: Icons.location_on_outlined, label: 'Address', value: order.customerAddress),
                  ],
                  const SizedBox(height: 10),
                  _InfoLine(icon: Icons.straighten_rounded, label: 'Distance', value: order.dist),
                ],
              ),
            ),
            if (widget.isDelivery) ...[
              const SizedBox(height: 20),
              Text('Delivery fee', style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setState(() => _freeDelivery = true),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _freeDelivery ? AppColors.tealMuted : Colors.white,
                    border: Border.all(color: _freeDelivery ? AppColors.teal : AppColors.creamDark),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _freeDelivery ? AppColors.teal : Colors.white,
                          border: Border.all(color: _freeDelivery ? AppColors.teal : AppColors.creamDark),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: _freeDelivery
                            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Free delivery', style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800)),
                            Text(
                              'Customer pays no delivery fee',
                              style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setState(() => _freeDelivery = false),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: !_freeDelivery ? AppColors.tealMuted : Colors.white,
                    border: Border.all(color: !_freeDelivery ? AppColors.teal : AppColors.creamDark),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: !_freeDelivery ? AppColors.teal : Colors.white,
                              border: Border.all(color: !_freeDelivery ? AppColors.teal : AppColors.creamDark),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: !_freeDelivery
                                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text('Charge delivery fee', style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      if (!_freeDelivery) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.creamDark),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text('TZS', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _feeController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(border: InputBorder.none, hintText: '0'),
                                  style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final fee = widget.isDelivery && !_freeDelivery
                      ? (int.tryParse(_feeController.text) ?? 0)
                      : 0;
                  ref.read(vendorOrdersProvider.notifier).acceptOrder(normalizeVendorOrderId(order.id), deliveryFeeTzs: fee);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${order.id} accepted · ${order.customer} notified'),
                      backgroundColor: AppColors.teal,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: AppColors.cream,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Accept order', style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  ref.read(vendorOrdersProvider.notifier).rejectOrder(normalizeVendorOrderId(order.id));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${order.id} declined'),
                      backgroundColor: AppColors.danger,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Decline order', style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.muted)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.label, required this.value});
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
            Text(value, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800)),
          ],
        ),
      ],
    );
  }
}
