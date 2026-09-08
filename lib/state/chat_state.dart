import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../utils/num_helper.dart';
import 'auth_state.dart';

/// Chat threads from the API, keyed by the backend's real numeric thread id
/// (as a string) — never the shop's display name, which was never a valid
/// id the backend could look anything up by.
class ChatState {
  const ChatState({this.threads = const {}, this.draft = '', this.isLoading = false});

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
  ChatState build() => const ChatState();

  /// Resolves the real thread id for this customer's conversation with
  /// [shopId], creating it on the backend the first time they message that
  /// shop. Null on failure (network error, shop not found).
  Future<String?> ensureThread(String shopId) async {
    try {
      final data = await api.openChatThread(shopId: shopId);
      final thread = data['data'] as Map<String, dynamic>? ?? data;
      return thread['id'] != null ? '${thread['id']}' : null;
    } on ApiException {
      return null;
    }
  }

  Future<void> loadMessages(String threadId) async {
    try {
      final data = await api.getChatMessages(threadId);
      final myId = ref.read(authProvider).userId;
      state = state.copyWith(
        threads: {...state.threads, threadId: data.map((j) => _fromJson(j, myId)).toList()},
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
        id: saved['id'] != null ? '${saved['id']}' : '',
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

  /// Called by [RealtimeService] for a `message.created` event on this
  /// thread's channel — the vendor just replied. De-dupes on id so an echo
  /// of a message this side already added (e.g. sent from another signed-in
  /// device) doesn't show up twice.
  void handleRealtimeMessage(String threadId, Map<String, dynamic> json) {
    final id = json['id'] != null ? '${json['id']}' : '';
    final current = state.messagesFor(threadId);
    if (id.isNotEmpty && current.any((m) => m.id == id)) return;

    final myId = ref.read(authProvider).userId;
    final senderId = parseInt(json['sender_id']);
    state = state.copyWith(
      threads: {
        ...state.threads,
        threadId: [
          ...current,
          ChatMessage(
            id: id,
            isMe: senderId != null && senderId == myId,
            text: json['text'] as String? ?? '',
            time: json['created_at'] as String? ?? 'now',
          ),
        ],
      },
    );
  }

  ChatMessage _fromJson(Map<String, dynamic> j, int myId) {
    final sender = j['sender'] as Map<String, dynamic>?;
    final senderId = parseInt(j['sender_id'] ?? sender?['id']);
    return ChatMessage(
      id: j['id'] != null ? '${j['id']}' : '',
      isMe: senderId != null && senderId == myId,
      text: j['text'] as String? ?? '',
      time: j['created_at'] as String? ?? '',
    );
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
