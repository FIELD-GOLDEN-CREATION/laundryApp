import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/app_icons.dart';
import '../../data/mock_data.dart';
import '../../models/order.dart';
import '../../state/chat_state.dart';
import '../../state/orders_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/remote_image.dart';

/// Chat tab: lists the vendors the customer has an *active* (incomplete)
/// order with. Conversations are only available while an order is in
/// progress, so completed orders' vendors drop off this list.
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrders = ref.watch(ordersProvider);
    final threads = ref.watch(chatProvider.select((s) => s.threads));
    final vendors = _activeVendors(activeOrders);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chats', style: AppText.serif(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text(
                    'Talk to the shops handling your orders',
                    style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (vendors.isEmpty)
              const Expanded(child: _EmptyState())
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                  itemCount: vendors.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final name = vendors[i];
                    final shop = shopByName(name);
                    final messages = threads[name];
                    final last = (messages != null && messages.isNotEmpty) ? messages.last : null;
                    return _ChatRow(
                      name: name,
                      imageUrl: shop?.imageUrl ?? '',
                      preview: last?.text ?? 'Start the conversation',
                      time: last?.time ?? '',
                      onTap: () => context.push('/chat-thread', extra: name),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Distinct vendor names from the active order list, in order of appearance.
List<String> _activeVendors(List<Order> orders) {
  final seen = <String>{};
  final result = <String>[];
  for (final o in orders) {
    if (seen.add(o.shop)) result.add(o.shop);
  }
  return result;
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.name, required this.imageUrl, required this.preview, required this.time, required this.onTap});

  final String name;
  final String imageUrl;
  final String preview;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.creamDark),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              SizedBox(width: 52, height: 52, child: RemoteImage(url: imageUrl, fallback: 'Shop', circle: true)),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (time.isNotEmpty)
                    Text(
                      time,
                      style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted.withValues(alpha: 0.8)),
                    ),
                  const SizedBox(height: 8),
                  const AppIcon(AppIcons.chevronRightSmall, size: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: AppColors.tealMuted, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const AppIcon(AppIcons.chatBubble, size: 26, color: AppColors.teal),
            ),
            const SizedBox(height: 16),
            Text('No active chats', style: AppText.serif(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              'Chat with a shop opens once you have an order in progress with them.',
              textAlign: TextAlign.center,
              style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
