import 'package:griot/features/griot/domain/entities/conversation_message.dart';
import 'package:griot/features/griot/domain/entities/conversation_session.dart';

abstract class ConversationSessionRepository {
  Future<ConversationSession?> getSession(String id);

  Future<void> createSession(ConversationSession session);

  Future<void> deleteSession(String id);

  Future<void> appendMessage(String sessionId, ConversationMessage message);
}
