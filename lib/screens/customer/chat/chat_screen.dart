import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/app_icons.dart';
import '../../../models/chat_message.dart';
import '../../../services/realtime_service.dart';
import '../../../state/catalog_state.dart';
import '../../../state/chat_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/remote_image.dart';

/// Opens the vendor/client conversation as a dismissible panel over the
/// current order. Chat is intentionally not a standalone navigation page.
/// [shopId] resolves (or creates) the real backend thread on open;
/// [shopName] is display-only.
void showChatPanel(BuildContext context, {required String shopId, required String shopName}) {
  showModalBottomSheet(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ChatPanel(shopId: shopId, shopName: shopName),
  );
}

class _ChatPanel extends ConsumerStatefulWidget {
  const _ChatPanel({required this.shopId, required this.shopName});
  final String shopId;
  final String shopName;
  @override
  ConsumerState<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<_ChatPanel> {
  final _controller = TextEditingController();
  String? _threadId;
  bool _resolving = true;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final notifier = ref.read(chatProvider.notifier);
    final threadId = await notifier.ensureThread(widget.shopId);
    if (!mounted) return;
    setState(() {
      _threadId = threadId;
      _resolving = false;
    });
    if (threadId == null) return;
    final id = int.tryParse(threadId);
    if (id != null) {
      RealtimeService.instance.joinChatThread(
        id,
        (message) => ref.read(chatProvider.notifier).handleRealtimeMessage(threadId, message),
      );
    }
    notifier.loadMessages(threadId);
  }

  @override
  void dispose() {
    final threadId = _threadId;
    if (threadId != null) {
      final id = int.tryParse(threadId);
      if (id != null) RealtimeService.instance.leaveChatThread(id);
    }
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final threadId = _threadId;
    if (threadId == null) return;
    ref.read(chatProvider.notifier).send(threadId);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final threadId = _threadId;
    final messages = threadId == null
        ? const <ChatMessage>[]
        : ref.watch(chatProvider.select((state) => state.messagesFor(threadId)));
    final notifier = ref.read(chatProvider.notifier);
    String image = '';
    for (final s in ref.watch(shopsProvider).items) {
      if (s.name == widget.shopName) {
        image = s.imageUrl;
        break;
      }
    }

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
                  SizedBox(width: 42, height: 42, child: RemoteImage(url: image, fallback: 'Shop', circle: true)),
                  const SizedBox(width: 11),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.shopName, style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text('Vendor conversation', style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.teal))])),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded, color: AppColors.slate)),
                ]),
              ]),
            ),
            const Divider(height: 1, color: AppColors.creamDark),
            Expanded(
              child: _resolving
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : threadId == null
                      ? Center(
                          child: Text(
                            "Couldn't open this conversation.",
                            style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
                          ),
                        )
                      : ListView.separated(padding: const EdgeInsets.all(18), itemCount: messages.length, separatorBuilder: (_, _) => const SizedBox(height: 12), itemBuilder: (_, i) => _Bubble(message: messages[i])),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + MediaQuery.viewInsetsOf(context).bottom),
              child: Row(children: [
                Expanded(child: Container(height: 46, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.creamDark), borderRadius: BorderRadius.circular(999)), child: TextField(controller: _controller, onChanged: notifier.setDraft, onSubmitted: (_) => _send(), style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w600), decoration: InputDecoration.collapsed(hintText: 'Message the vendor', hintStyle: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.muted))))),
                const SizedBox(width: 9),
                Material(color: AppColors.teal, shape: const CircleBorder(), clipBehavior: Clip.antiAlias, child: InkWell(onTap: threadId == null ? null : _send, child: const SizedBox(width: 46, height: 46, child: Center(child: AppIcon(AppIcons.send, size: 19))))),
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
