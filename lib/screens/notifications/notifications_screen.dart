import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/notification_item.dart';
import '../../state/notifications_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/round_back_button.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notificationsProvider.notifier).loadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(notificationsProvider).items;
    final isLoading = ref.watch(notificationsProvider.select((s) => s.isLoading));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          children: [
            Row(
              children: [
                RoundBackButton(onPressed: () => context.pop()),
                const SizedBox(width: 12),
                Text('Notifications', style: AppText.serif(fontSize: 24)),
              ],
            ),
            const SizedBox(height: 20),
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
                    'No notifications yet',
                    style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted),
                  ),
                ),
              )
            else
              for (var i = 0; i < items.length; i++) ...[
                _NotificationCard(item: items[i]),
                if (i != items.length - 1) const SizedBox(height: 11),
              ],
          ],
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
        color: item.bg,
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
                Text(item.title, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(
                  item.body,
                  style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted, height: 1.45),
                ),
                const SizedBox(height: 6),
                Text(
                  item.time,
                  style: AppText.sans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
