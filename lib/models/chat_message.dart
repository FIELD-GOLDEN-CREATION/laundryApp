class ChatMessage {
  const ChatMessage({this.id = '', required this.isMe, required this.text, required this.time});

  /// Backend `chat_messages.id` — empty for an optimistic, not-yet-sent
  /// message. Used to de-dupe a message that arrives back over the socket
  /// after already being added locally.
  final String id;
  final bool isMe;
  final String text;
  final String time;
}
