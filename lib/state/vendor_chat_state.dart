import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/vendor_mock_data.dart';
import '../models/chat_message.dart';

/// Vendor-side mirror of state/chat_state.dart — chat threads keyed by
/// customer name instead of shop name, with the vendor as the `isMe` side.
class VendorChatState {
  const VendorChatState({required this.threads, this.draft = ''});

  final Map<String, List<ChatMessage>> threads;
  final String draft;

  VendorChatState copyWith({Map<String, List<ChatMessage>>? threads, String? draft}) =>
      VendorChatState(threads: threads ?? this.threads, draft: draft ?? this.draft);

  List<ChatMessage> messagesFor(String customer) => threads[customer] ?? const <ChatMessage>[];
}

/// Ports state/chat_state.dart's `messages`/`draft`/`send()` pattern, keyed
/// by customer instead of shop. Seeded with a conversation under
/// "Amara Reed" (the in-progress #LD-2481 order); other customers start
/// with no messages.
class VendorChatNotifier extends Notifier<VendorChatState> {
  @override
  VendorChatState build() => VendorChatState(threads: {'Amara Reed': List.of(kInitialVendorChatMessages)});

  void setDraft(String draft) => state = state.copyWith(draft: draft);

  void send(String customer) {
    final text = state.draft.trim();
    if (text.isEmpty) return;
    state = state.copyWith(
      draft: '',
      threads: {
        ...state.threads,
        customer: [...state.messagesFor(customer), ChatMessage(isMe: true, text: text, time: 'now')],
      },
    );
  }
}

final vendorChatProvider = NotifierProvider<VendorChatNotifier, VendorChatState>(VendorChatNotifier.new);
