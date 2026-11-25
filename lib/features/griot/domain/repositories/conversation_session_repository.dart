import 'package:griot/features/griot/domain/entities/conversation_message.dart';
import 'package:griot/features/griot/domain/entities/conversation_session.dart';
import 'package:griot/features/griot/domain/entities/new_conversation_message.dart';

abstract class ConversationSessionRepository {
  Future<ConversationSession?> getSession(String id);

  Future<void> createSession(ConversationSession session);

  Future<void> deleteSession(String id);

  Future<ConversationMessage> appendMessage(
    String sessionId,
    NewConversationMessage message,
  );

  Future<List<ConversationMessage>> getMessages(
    String sessionId, {
    int limit = 20,
    int? beforeSequenceNumber,
  });
}
