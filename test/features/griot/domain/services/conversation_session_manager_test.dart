import 'package:flutter_test/flutter_test.dart';
import 'package:griot/features/griot/data/repositories/in_memory_conversation_session_repository.dart';
import 'package:griot/features/griot/domain/entities/conversation_message.dart';
import 'package:griot/features/griot/domain/services/conversation_session_manager.dart';

void main() {
  test('createSession creates independent sessions', () async {
    final repository = InMemoryConversationSessionRepository();
    final manager = ConversationSessionManager(repository);

    final sessionA = await manager.createSession();
    final sessionB = await manager.createSession();

    expect(sessionA.id, isNot(sessionB.id));

    expect(sessionA.messages, isEmpty);
    expect(sessionB.messages, isEmpty);

    expect(await manager.getSession(sessionA.id), isNotNull);

    expect(await manager.getSession(sessionB.id), isNotNull);
  });

  test("modifying one session doesn't modify another", () async {
    final repository = InMemoryConversationSessionRepository();
    final manager = ConversationSessionManager(repository);

    final sessionA = await manager.createSession();
    final sessionB = await manager.createSession();

    await manager.addMessage(
      ConversationMessage(role: "user", content: "Hello"),
      sessionA.id,
    );

    final updatedA = await manager.getSession(sessionA.id);
    final updatedB = await manager.getSession(sessionB.id);

    expect(sessionA.id, isNot(sessionB.id));

    expect(updatedA!.id, equals(sessionA.id));
    expect(updatedB!.id, equals(sessionB.id));

    expect(updatedA.messages.length, 1);
    expect(updatedB.messages.length, 0);

    expect(updatedA.messages.single.content, "Hello");
    expect(updatedB.messages, isEmpty);
  });

  test('concurrent messages are not lost', () async {
    final repository = InMemoryConversationSessionRepository();
    final manager = ConversationSessionManager(repository);

    final session = await manager.createSession();

    await Future.wait([
      manager.addMessage(
        ConversationMessage(role: 'user', content: 'Hello'),
        session.id,
      ),
      manager.addMessage(
        ConversationMessage(role: 'user', content: 'How are you?'),
        session.id,
      ),
    ]);

    final updated = await manager.getSession(session.id);

    expect(updated, isNotNull);
    expect(updated!.messages.length, 2);

    expect(
      updated.messages.map((message) => message.content),
      containsAll(['Hello', 'How are you?']),
    );
  });
}
