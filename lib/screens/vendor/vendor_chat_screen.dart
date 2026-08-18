import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/app_icons.dart';
import '../../models/chat_message.dart';
import '../../state/vendor_chat_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/remote_image.dart';

/// Vendor-side mirror of screens/customer/chat/chat_screen.dart — same panel UI, but
/// opened from an in-progress order card and keyed by customer name instead
/// of shop name, with the vendor as the `isMe` side of the conversation.
void showVendorChatPanel(BuildContext context, String customer) {
  showModalBottomSheet(context: context, useSafeArea: true, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _VendorChatPanel(customer: customer));
}

class _VendorChatPanel extends ConsumerStatefulWidget {
  const _VendorChatPanel({required this.customer});
  final String customer;
  @override
  ConsumerState<_VendorChatPanel> createState() => _VendorChatPanelState();
}

class _VendorChatPanelState extends ConsumerState<_VendorChatPanel> {
  final _controller = TextEditingController();
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _send() {
    ref.read(vendorChatProvider.notifier).send(widget.customer);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(vendorChatProvider.select((state) => state.messagesFor(widget.customer)));
    final notifier = ref.read(vendorChatProvider.notifier);

    return FractionallySizedBox(
      heightFactor: 0.84,
      child: Container(
        decoration: const BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
              child: Column(children: [
                Container(width: 42, height: 4, decoration: BoxDecoration(color: AppColors.creamDark, borderRadius: BorderRadius.circular(99))),
                const SizedBox(height: 12),
                Row(children: [
                  SizedBox(width: 42, height: 42, child: RemoteImage(url: '', fallback: widget.customer, circle: true)),
                  const SizedBox(width: 11),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.customer, style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text('Customer conversation', style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.teal))])),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded, color: AppColors.slate)),
                ]),
              ]),
            ),
            const Divider(height: 1, color: AppColors.creamDark),
            Expanded(child: ListView.separated(padding: const EdgeInsets.all(18), itemCount: messages.length, separatorBuilder: (_, _) => const SizedBox(height: 12), itemBuilder: (_, i) => _Bubble(message: messages[i]))),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + MediaQuery.viewInsetsOf(context).bottom),
              child: Row(children: [
                Expanded(child: Container(height: 46, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.creamDark), borderRadius: BorderRadius.circular(999)), child: TextField(controller: _controller, onChanged: notifier.setDraft, onSubmitted: (_) => _send(), style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w600), decoration: InputDecoration.collapsed(hintText: 'Message the customer', hintStyle: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.muted))))),
                const SizedBox(width: 9),
                Material(color: AppColors.teal, shape: const CircleBorder(), clipBehavior: Clip.antiAlias, child: InkWell(onTap: _send, child: const SizedBox(width: 46, height: 46, child: Center(child: AppIcon(AppIcons.send, size: 19))))),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bg = message.isMe ? AppColors.teal : Colors.white;
    final fg = message.isMe ? AppColors.cream : AppColors.slate;
    final radius = message.isMe ? const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4)) : const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18));
    return Align(alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11), decoration: BoxDecoration(color: bg, borderRadius: radius), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(message.text, style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w600, color: fg)), const SizedBox(height: 5), Text(message.time, style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg.withValues(alpha: 0.55)))]))));
  }
}
