import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/notification_item.dart';
import '../../state/notifications_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/round_back_button.dart';

const _kTypes = ['all', 'order', 'vendor', 'payment', 'system'];

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key, this.vendor = false});

  final bool vendor;

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notificationsProvider.notifier).loadNotifications(vendor: widget.vendor));
  }

  Future<void> _openDetail(NotificationItem item) async {
    final notifier = ref.read(notificationsProvider.notifier);
    await notifier.markRead(item.id, vendor: widget.vendor);
    if (!mounted) return;
    final data = item.data;
    final orderId = data['order_id']?.toString();
    if (orderId != null && orderId.isNotEmpty) {
      if (widget.vendor) {
        context.push('/vendor/order-detail', extra: orderId);
      } else {
        context.push('/track', extra: orderId);
      }
      return;
    }
    final shopId = data['shop_id']?.toString();
    if (shopId != null && shopId.isNotEmpty) {
      context.push('/search');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final items = state.filtered;
    final isLoading = state.isLoading;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(notificationsProvider.notifier).loadNotifications(vendor: widget.vendor),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
            children: [
              Row(
                children: [
                  RoundBackButton(onPressed: () => context.pop()),
                  const SizedBox(width: 12),
                  Text('Notifications', style: AppText.serif(fontSize: 24)),
                  const Spacer(),
                  if (state.unreadCount > 0)
                    TextButton(
                      onPressed: () => ref
                          .read(notificationsProvider.notifier)
                          .markAllRead(vendor: widget.vendor),
                      child: Text('Mark all read (${state.unreadCount})',
                          style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _kTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final t = _kTypes[i];
                    final selected = state.activeType == t;
                    return ChoiceChip(
                      label: Text(t[0].toUpperCase() + t.substring(1)),
                      selected: selected,
                      onSelected: (_) {
                        ref.read(notificationsProvider.notifier).setFilter(t);
                        ref.read(notificationsProvider.notifier).loadNotifications(vendor: widget.vendor, type: t == 'all' ? null : t);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (isLoading && items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No notifications yet — they stay here for 30 days',
                      style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted),
                    ),
                  ),
                )
              else
                for (var i = 0; i < items.length; i++) ...[
                  Dismissible(
                    key: ValueKey(items[i].id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                    onDismissed: (_) => ref
                        .read(notificationsProvider.notifier)
                        .deleteNotification(items[i].id, vendor: widget.vendor),
                    child: GestureDetector(
                      onTap: () => _openDetail(items[i]),
                      child: _NotificationCard(item: items[i]),
                    ),
                  ),
                  if (i != items.length - 1) const SizedBox(height: 11),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.isRead ? item.bg : const Color(0xFFF6FBFA),
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: item.iconBg, borderRadius: BorderRadius.circular(13)),
            alignment: Alignment.center,
            child: Text(item.initial, style: AppText.serif(fontSize: 16, color: item.iconFg)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.title,
                          style: AppText.sans(
                              fontSize: 14,
                              fontWeight: item.isRead ? FontWeight.w700 : FontWeight.w800)),
                    ),
                    if (!item.isRead)
                      Container(
                          width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF00897B), shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.body,
                  style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted, height: 1.45),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.time,
                        style: AppText.sans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    if (item.event != null && item.event!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: AppColors.creamDark.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(item.event!,
                            style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
