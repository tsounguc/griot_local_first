import 'package:griot/features/griot/domain/entities/conversation_message.dart';
import 'package:griot/features/griot/domain/entities/conversation_session.dart';
import 'package:griot/features/griot/domain/entities/new_conversation_message.dart';
import 'package:griot/features/griot/domain/repositories/conversation_session_repository.dart';
import 'package:uuid/uuid.dart';

class InMemoryConversationSessionRepository
    implements ConversationSessionRepository {
  final Map<String, ConversationSession> _sessions = {};
  final Map<String, List<ConversationMessage>> _messages = {};

  final Uuid _uuid = const Uuid();

  @override
  Future<void> createSession(ConversationSession session) async {
    if (_sessions.containsKey(session.id)) {
      throw StateError('Session ${session.id} already exists');
    }
    _sessions[session.id] = session;
    _messages[session.id] = [];
  }

  @override
  Future<ConversationSession?> getSession(String id) async {
    return _sessions[id];
  }

  @override
  Future<void> deleteSession(String id) async {
    _sessions.remove(id);
    _messages.remove(id);
  }

  @override
  Future<ConversationMessage> appendMessage(
    String sessionId,
    NewConversationMessage message,
  ) async {
    final session = _sessions[sessionId];
    final messages = _messages[sessionId];

    // 1. Validate the session
    // Ensure the parent conversation exists.
    if (session == null || messages == null) {
      throw StateError('Session $sessionId does not exist');
    }

    // 2. Allocate a sequence number
    // Read the last recorded sequence number and increment it.
    final nextSequenceNumber = messages.isEmpty
        ? 1
        : messages.last.sequenceNumber + 1;

    final now = DateTime.now();

    // 3. Construct the recorded message
    // Generate a UUID, associate the session ID, and record the timestamp.
    final recordedMessage = ConversationMessage(
      id: _uuid.v4(),
      sessionId: sessionId,
      role: message.role,
      content: message.content,
      createdAt: now,
      sequenceNumber: nextSequenceNumber,
    );

    messages.add(recordedMessage);

    // 4. Update storage
    // Append the recorded message and return it to the caller.
    _sessions[sessionId] = session.copyWith(updatedAt: now);

    return recordedMessage;
  }

  @override
  Future<List<ConversationMessage>> getMessages(
    String sessionId, {
    int limit = 20,
    int? beforeSequenceNumber,
  }) async {
    if (limit <= 0) {
      throw ArgumentError.value(
        limit,
        'limit',
        'Limit must be greater than zero',
      );
    }

    final messages = _messages[sessionId];

    if (messages == null) {
      throw StateError('Session $sessionId does not exist');
    }
    final end = beforeSequenceNumber == null
        ? messages.length
        : (beforeSequenceNumber - 1).clamp(0, messages.length).toInt();

    final start = (end - limit).clamp(0, end).toInt();

    return List<ConversationMessage>.unmodifiable(
      messages.getRange(start, end),
    );
  }
}
