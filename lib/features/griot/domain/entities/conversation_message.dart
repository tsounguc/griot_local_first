class ConversationMessage {
  const ConversationMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
    required this.sequenceNumber,
  });

  final String id;
  final String sessionId;
  final String role;
  final String content;
  final DateTime createdAt;
  final int sequenceNumber;
}
