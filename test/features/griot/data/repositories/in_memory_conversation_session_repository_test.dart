import 'package:flutter_test/flutter_test.dart';
import 'package:griot/features/griot/data/repositories/in_memory_conversation_session_repository.dart';
import 'package:griot/features/griot/domain/entities/conversation_message.dart';
import 'package:griot/features/griot/domain/entities/conversation_session.dart';

void main() {
  test(
    'creating a session with a duplicate ID does not overwrite the original',
    () async {
      final repository = InMemoryConversationSessionRepository();
      final now = DateTime.now();

      final originalSession = ConversationSession(
        id: 'abc123',
        createdAt: now,
        updatedAt: now,
        messages: [
          ConversationMessage(
            id: 'message-001',
            sessionId: 'abc123',
            role: 'user',
            content: 'Original message',
            createdAt: now,
            sequenceNumber: 1,
          ),
        ],
      );

      final duplicateSession = ConversationSession(
        id: 'abc123',
        createdAt: now,
        updatedAt: now,
        messages: [
          ConversationMessage(
            id: 'message-002',
            sessionId: 'abc123',
            role: 'user',
            content: 'Different message',
            createdAt: now,
            sequenceNumber: 1,
          ),
        ],
      );

      // Save the original session.
      await repository.createSession(originalSession);

      // Attempting to create another session
      // with the same ID must fail.
      await expectLater(
        repository.createSession(duplicateSession),
        throwsStateError,
      );

      // Verify the original session is unchanged.
      final storedSession = await repository.getSession('abc123');

      expect(storedSession, isNotNull);
      expect(storedSession!.id, 'abc123');
      expect(storedSession.messages.length, 1);

      final storedMessage = storedSession.messages.single;

      expect(storedMessage.id, 'message-001');
      expect(storedMessage.sessionId, 'abc123');
      expect(storedMessage.content, 'Original message');
      expect(storedMessage.sequenceNumber, 1);
      expect(storedMessage.createdAt, now);
      expect(storedMessage.role, 'user');
    },
  );
}
