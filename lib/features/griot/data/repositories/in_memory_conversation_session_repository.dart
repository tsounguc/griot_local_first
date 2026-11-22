import 'package:griot/features/griot/domain/entities/conversation_message.dart';
import 'package:griot/features/griot/domain/entities/conversation_session.dart';
import 'package:griot/features/griot/domain/repositories/conversation_session_repository.dart';

class InMemoryConversationSessionRepository
    implements ConversationSessionRepository {
  final Map<String, ConversationSession> _sessions = {};

  @override
  Future<void> deleteSession(String id) async {
    _sessions.remove(id);
  }

  @override
  Future<ConversationSession?> getSession(String id) async {
    return _sessions[id];
  }

  @override
  Future<void> createSession(ConversationSession session) async {
    if (_sessions.containsKey(session.id)) {
      throw StateError('Session ${session.id} already exists');
    }
    _sessions[session.id] = session;
  }

  @override
  Future<void> appendMessage(
    String sessionId,
    ConversationMessage message,
  ) async {
    final session = _sessions[sessionId];

    if (session == null) {
      throw StateError('Session $sessionId does not exist');
    }

    _sessions[sessionId] = session.addMessage(message);
  }
}
