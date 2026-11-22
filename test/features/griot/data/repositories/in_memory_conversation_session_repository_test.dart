import 'package:flutter_test/flutter_test.dart';
import 'package:griot/features/griot/data/repositories/in_memory_conversation_session_repository.dart';
import 'package:griot/features/griot/domain/entities/conversation_message.dart';
import 'package:griot/features/griot/domain/entities/conversation_session.dart';

void main() {
  test(
    'creating a session with a duplicate ID does not overwrite the original',
    () async {
      final repository = InMemoryConversationSessionRepository();

      final originalSession = ConversationSession(
        id: 'abc123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messages: [
          ConversationMessage(role: 'user', content: 'Original message'),
        ],
      );

      final duplicateSession = ConversationSession(
        id: 'abc123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messages: [
          ConversationMessage(role: 'user', content: 'Different message'),
        ],
      );

      // Save the original session.
      await repository.createSession(originalSession);

      // Attempting to create another session with the same ID must fail.
      await expectLater(
        repository.createSession(duplicateSession),
        throwsStateError,
      );

      // Verify the original session still exists and is unchanged.
      final storedSession = await repository.getSession('abc123');

      expect(storedSession, isNotNull);
      expect(storedSession!.id, 'abc123');
      expect(storedSession.messages.length, 1);
      expect(storedSession.messages.single.content, 'Original message');
    },
  );
}
