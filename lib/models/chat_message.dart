class ChatMessage {
  const ChatMessage({required this.isMe, required this.text, required this.time});

  final bool isMe;
  final String text;
  final String time;
}
