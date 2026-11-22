import 'package:griot/features/griot/domain/entities/conversation_message.dart';

class ConversationSession {
  ConversationSession({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required List<ConversationMessage> messages,
  }) : messages = List.unmodifiable(messages);

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ConversationMessage> messages;

  ConversationSession addMessage(ConversationMessage message) {
    return ConversationSession(
      id: id,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      messages: [...messages, message],
    );
  }
}
