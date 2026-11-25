import 'package:griot/features/griot/domain/entities/conversation_message.dart';
import 'package:griot/features/griot/domain/entities/conversation_session.dart';
import 'package:griot/features/griot/domain/repositories/conversation_session_repository.dart';
import 'package:uuid/uuid.dart';

import '../entities/new_conversation_message.dart';

class ConversationSessionManager {
  ConversationSessionManager(this._repository);

  final ConversationSessionRepository _repository;

  Future<ConversationSession?> getSession(String id) =>
      _repository.getSession(id);

  Future<ConversationSession> createSession() async {
    final now = DateTime.now();

    final session = ConversationSession(
      id: Uuid().v4(),
      title: 'New Conversation',
      createdAt: now,
      updatedAt: now,
    );

    await _repository.createSession(session);

    return session;
  }

  Future<void> deleteSession(String id) => _repository.deleteSession(id);

  Future<ConversationMessage> addMessage(
    NewConversationMessage message,
    String sessionId,
  ) => _repository.appendMessage(sessionId, message);

  Future<List<ConversationMessage>> getMessages(
    String sessionId, {
    int limit = 20,
    int? beforeSequenceNumber,
  }) {
    return _repository.getMessages(
      sessionId,
      limit: limit,
      beforeSequenceNumber: beforeSequenceNumber,
    );
  }
}
