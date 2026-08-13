import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../models/chat_message.dart';

class ChatState {
  const ChatState({required this.messages, this.draft = ''});

  final List<ChatMessage> messages;
  final String draft;

  ChatState copyWith({List<ChatMessage>? messages, String? draft}) =>
      ChatState(messages: messages ?? this.messages, draft: draft ?? this.draft);
}

/// Ports the source's `messages`/`draft` state + `send()`.
class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() => ChatState(messages: List.of(kInitialChatMessages));

  void setDraft(String draft) => state = state.copyWith(draft: draft);

  void send() {
    final text = state.draft.trim();
    if (text.isEmpty) return;
    state = state.copyWith(
      draft: '',
      messages: [...state.messages, ChatMessage(isMe: true, text: text, time: 'now')],
    );
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
