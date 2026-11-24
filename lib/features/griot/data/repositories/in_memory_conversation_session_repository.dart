import 'package:griot/features/griot/domain/entities/conversation_message.dart';
import 'package:griot/features/griot/domain/entities/conversation_session.dart';
import 'package:griot/features/griot/domain/entities/new_conversation_message.dart';
import 'package:griot/features/griot/domain/repositories/conversation_session_repository.dart';
import 'package:uuid/uuid.dart';

class InMemoryConversationSessionRepository
    implements ConversationSessionRepository {
  final Map<String, ConversationSession> _sessions = {};
  final Uuid _uuid = const Uuid();

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
  Future<ConversationMessage> appendMessage(
    String sessionId,
    NewConversationMessage message,
  ) async {
    final session = _sessions[sessionId];

    // 1. Validate the session
    // Ensure the parent conversation exists.
    if (session == null) {
      throw StateError('Session $sessionId does not exist');
    }

    // 2. Allocate a sequence number
    // Read the last recorded sequence number and increment it.
    final nextSequenceNumber = session.messages.isEmpty
        ? 1
        : session.messages.last.sequenceNumber + 1;

    // 3. Construct the recorded message
    // Generate a UUID, associate the session ID, and record the timestamp.
    final recordedMessage = ConversationMessage(
      id: _uuid.v4(),
      sessionId: sessionId,
      role: message.role,
      content: message.content,
      createdAt: DateTime.now(),
      sequenceNumber: nextSequenceNumber,
    );

    // 4. Update storage
    // Append the recorded message and return it to the caller.
    _sessions[sessionId] = session.addMessage(recordedMessage);
    return recordedMessage;
  }
}
