import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../models/chat_message.dart';

/// Chat threads keyed by shop name, so the customer can hold a separate
/// conversation with each vendor they have an active order with.
class ChatState {
  const ChatState({required this.threads, this.draft = ''});

  final Map<String, List<ChatMessage>> threads;
  final String draft;

  ChatState copyWith({Map<String, List<ChatMessage>>? threads, String? draft}) =>
      ChatState(threads: threads ?? this.threads, draft: draft ?? this.draft);

  List<ChatMessage> messagesFor(String shop) => threads[shop] ?? const <ChatMessage>[];
}

/// Ports the source's `messages`/`draft` state + `send()`, extended to one
/// thread per shop. Seeded with a conversation under "Marina Fresh Laundry"
/// (the default demo order's vendor); other vendors start with no messages.
class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() => ChatState(threads: {'Marina Fresh Laundry': List.of(kInitialChatMessages)});

  void setDraft(String draft) => state = state.copyWith(draft: draft);

  void send(String shop) {
    final text = state.draft.trim();
    if (text.isEmpty) return;
    state = state.copyWith(
      draft: '',
      threads: {
        ...state.threads,
        shop: [...state.messagesFor(shop), ChatMessage(isMe: true, text: text, time: 'now')],
      },
    );
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
