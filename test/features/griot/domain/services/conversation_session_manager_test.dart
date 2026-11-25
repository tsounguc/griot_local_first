import 'package:flutter_test/flutter_test.dart';
import 'package:griot/features/griot/data/repositories/in_memory_conversation_session_repository.dart';
import 'package:griot/features/griot/domain/entities/conversation_session.dart';
import 'package:griot/features/griot/domain/entities/conversation_session_cursor.dart';
import 'package:griot/features/griot/domain/entities/new_conversation_message.dart';
import 'package:griot/features/griot/domain/services/conversation_session_manager.dart';

void main() {
  test('createSession creates independent sessions', () async {
    final repository = InMemoryConversationSessionRepository();
    final manager = ConversationSessionManager(repository);

    final sessionA = await manager.createSession();
    final sessionB = await manager.createSession();

    expect(sessionA.id, isNot(sessionB.id));

    expect(await manager.getMessages(sessionA.id), isEmpty);
    expect(await manager.getMessages(sessionB.id), isEmpty);

    expect(await manager.getSession(sessionA.id), isNotNull);
    expect(await manager.getSession(sessionB.id), isNotNull);
  });

  test("modifying one session doesn't modify another", () async {
    final repository = InMemoryConversationSessionRepository();
    final manager = ConversationSessionManager(repository);

    final sessionA = await manager.createSession();
    final sessionB = await manager.createSession();

    await manager.addMessage(
      const NewConversationMessage(role: 'user', content: 'Hello'),
      sessionA.id,
    );

    final updatedA = await manager.getSession(sessionA.id);
    final updatedB = await manager.getSession(sessionB.id);

    expect(sessionA.id, isNot(sessionB.id));

    expect(updatedA!.id, equals(sessionA.id));
    expect(updatedB!.id, equals(sessionB.id));

    final messagesA = await manager.getMessages(sessionA.id);
    final messagesB = await manager.getMessages(sessionB.id);

    expect(messagesA.length, 1);
    expect(messagesB, isEmpty);

    expect(messagesA.single.content, 'Hello');
  });

  test('concurrent messages are not lost', () async {
    final repository = InMemoryConversationSessionRepository();
    final manager = ConversationSessionManager(repository);

    final session = await manager.createSession();

    await Future.wait([
      manager.addMessage(
        const NewConversationMessage(role: 'user', content: 'Hello'),
        session.id,
      ),
      manager.addMessage(
        const NewConversationMessage(role: 'user', content: 'How are you?'),
        session.id,
      ),
    ]);

    final updated = await manager.getSession(session.id);

    expect(updated, isNotNull);

    final messages = await manager.getMessages(session.id);

    expect(messages.length, 2);

    // Verify that sequence numbers are unique and ordered.
    expect(
      messages.map((message) => message.sequenceNumber),
      orderedEquals([1, 2]),
    );

    // Verify that both messages have unique IDs.
    expect(messages.map((message) => message.id).toSet().length, 2);

    expect(
      messages.map((message) => message.content),
      containsAll(['Hello', 'How are you?']),
    );
  });

  test('each session has independent sequence numbers', () async {
    final repository = InMemoryConversationSessionRepository();
    final manager = ConversationSessionManager(repository);

    final sessionA = await manager.createSession();
    final sessionB = await manager.createSession();

    final messageA1 = await manager.addMessage(
      const NewConversationMessage(role: 'user', content: 'Hello from A'),
      sessionA.id,
    );

    final messageB1 = await manager.addMessage(
      const NewConversationMessage(role: 'user', content: 'Hello from B'),
      sessionB.id,
    );

    final messageA2 = await manager.addMessage(
      const NewConversationMessage(role: 'assistant', content: 'Response to A'),
      sessionA.id,
    );

    expect(messageA1.sequenceNumber, 1);
    expect(messageB1.sequenceNumber, 1);
    expect(messageA2.sequenceNumber, 2);

    expect({messageA1.id, messageB1.id, messageA2.id}.length, 3);
  });

  test('appending to a nonexistent session throws an error', () async {
    final repository = InMemoryConversationSessionRepository();
    final manager = ConversationSessionManager(repository);

    await expectLater(
      manager.addMessage(
        const NewConversationMessage(role: 'user', content: 'Hello'),
        'nonexistent-session',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('manager respects conversation pagination limit', () async {
    final repository = InMemoryConversationSessionRepository();
    final manager = ConversationSessionManager(repository);

    await manager.createSession();
    await manager.createSession();
    await manager.createSession();

    final sessions = await manager.getSessions(limit: 2);

    expect(sessions.length, 2);
  });

  test('manager retrieves next conversation page using cursor', () async {
    final repository = InMemoryConversationSessionRepository();
    final manager = ConversationSessionManager(repository);

    final timestamp = DateTime.utc(2026, 11, 25);

    for (final id in ['C', 'A', 'D', 'B']) {
      await repository.createSession(
        ConversationSession(
          id: id,
          title: 'Conversation $id',
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
    }

    final firstPage = await manager.getSessions(limit: 2);

    final cursor = ConversationSessionCursor(
      updatedAt: firstPage.last.updatedAt,
      id: firstPage.last.id,
    );

    final secondPage = await manager.getSessions(limit: 2, cursor: cursor);

    expect(firstPage.map((session) => session.id), orderedEquals(['A', 'B']));

    expect(secondPage.map((session) => session.id), orderedEquals(['C', 'D']));
  });
}
