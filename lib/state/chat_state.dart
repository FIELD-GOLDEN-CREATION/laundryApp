import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';
import '../services/api_service.dart';

/// Chat threads from the API, keyed by thread ID.
class ChatState {
  const ChatState({required this.threads, this.draft = '', this.isLoading = false});

  final Map<String, List<ChatMessage>> threads;
  final String draft;
  final bool isLoading;

  ChatState copyWith({Map<String, List<ChatMessage>>? threads, String? draft, bool? isLoading}) =>
      ChatState(
        threads: threads ?? this.threads,
        draft: draft ?? this.draft,
        isLoading: isLoading ?? this.isLoading,
      );

  List<ChatMessage> messagesFor(String threadId) => threads[threadId] ?? const <ChatMessage>[];
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState(threads: {});

  Future<void> loadThreads() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await api.getChatThreads();
      final threads = <String, List<ChatMessage>>{};
      for (final t in data) {
        final threadId = t['id'] as String? ?? '';
        if (threadId.isNotEmpty) {
          threads[threadId] = const <ChatMessage>[];
        }
      }
      state = state.copyWith(threads: threads, isLoading: false);
    } on ApiException {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMessages(String threadId) async {
    try {
      final data = await api.getChatMessages(threadId);
      final messages = data.map((j) => ChatMessage(
        isMe: j['is_mine'] as bool? ?? j['sender_type'] == 'customer',
        text: j['text'] as String? ?? j['message'] as String? ?? '',
        time: j['created_at'] as String? ?? '',
      )).toList();
      state = state.copyWith(
        threads: {...state.threads, threadId: messages},
      );
    } on ApiException {
      // Keep existing state
    }
  }

  void setDraft(String draft) => state = state.copyWith(draft: draft);

  Future<void> send(String threadId) async {
    final text = state.draft.trim();
    if (text.isEmpty) return;

    // Optimistic add
    final current = List<ChatMessage>.from(state.messagesFor(threadId));
    final optimistic = ChatMessage(isMe: true, text: text, time: 'now');
    state = state.copyWith(
      draft: '',
      threads: {...state.threads, threadId: [...current, optimistic]},
    );

    try {
      final data = await api.sendChatMessage(threadId, text);
      final saved = data['data'] as Map<String, dynamic>? ?? data;
      final savedMessage = ChatMessage(
        isMe: true,
        text: saved['text'] as String? ?? text,
        time: saved['created_at'] as String? ?? 'now',
      );
      state = state.copyWith(
        threads: {...state.threads, threadId: [...current, savedMessage]},
      );
    } catch (_) {
      // Keep optimistic message on failure
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
