import 'package:griot/features/griot/domain/entities/conversation_message.dart';
import 'package:griot/features/griot/domain/entities/conversation_session.dart';
import 'package:griot/features/griot/domain/repositories/conversation_session_repository.dart';
import 'package:uuid/uuid.dart';

class ConversationSessionManager {
  ConversationSessionManager(this._repository);

  final ConversationSessionRepository _repository;

  Future<ConversationSession?> getSession(String id) =>
      _repository.getSession(id);

  Future<ConversationSession> createSession() async {
    final id = Uuid().v4();
    final now = DateTime.now();

    final session = ConversationSession(
      id: id,
      createdAt: now,
      updatedAt: now,
      messages: [],
    );

    await _repository.createSession(session);

    return session;
  }

  Future<void> deleteSession(String id) => _repository.deleteSession(id);

  Future<void> addMessage(ConversationMessage message, String sessionId) =>
      _repository.appendMessage(sessionId, message);
}
