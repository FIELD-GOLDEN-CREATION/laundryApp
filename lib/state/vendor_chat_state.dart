import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';
import '../services/api_service.dart';

class VendorChatState {
  const VendorChatState({required this.threads, this.draft = '', this.isLoading = false});

  final Map<String, List<ChatMessage>> threads;
  final String draft;
  final bool isLoading;

  VendorChatState copyWith({Map<String, List<ChatMessage>>? threads, String? draft, bool? isLoading}) =>
      VendorChatState(
        threads: threads ?? this.threads,
        draft: draft ?? this.draft,
        isLoading: isLoading ?? this.isLoading,
      );

  List<ChatMessage> messagesFor(String threadId) => threads[threadId] ?? const <ChatMessage>[];
}

class VendorChatNotifier extends Notifier<VendorChatState> {
  @override
  VendorChatState build() => const VendorChatState(threads: {});

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
        isMe: j['is_mine'] as bool? ?? j['sender_type'] == 'vendor',
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
    } on ApiException {
      // Keep optimistic message on failure
    }
  }
}

final vendorChatProvider = NotifierProvider<VendorChatNotifier, VendorChatState>(VendorChatNotifier.new);
