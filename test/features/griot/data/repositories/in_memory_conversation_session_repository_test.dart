import 'package:flutter_test/flutter_test.dart';
import 'package:griot/features/griot/data/repositories/in_memory_conversation_session_repository.dart';
import 'package:griot/features/griot/domain/entities/conversation_session.dart';
import 'package:griot/features/griot/domain/entities/conversation_session_cursor.dart';
import 'package:griot/features/griot/domain/entities/new_conversation_message.dart';

void main() {
  late InMemoryConversationSessionRepository repository;

  final initialTime = DateTime.utc(2000);

  // Helper for constructing conversation metadata.
  ConversationSession session(String id, {String title = 'Original'}) {
    return ConversationSession(
      id: id,
      title: title,
      createdAt: initialTime,
      updatedAt: initialTime,
    );
  }

  // Helper for appending multiple messages.
  Future<void> append(int count, {String id = 'A'}) async {
    for (var i = 0; i < count; i++) {
      await repository.appendMessage(
        id,
        NewConversationMessage(role: 'user', content: 'Message $i'),
      );
    }
  }

  // Helper for retrieving message sequence numbers.
  Future<List<int>> sequences({int limit = 20, int? before}) async {
    final messages = await repository.getMessages(
      'A',
      limit: limit,
      beforeSequenceNumber: before,
    );

    return messages.map((message) => message.sequenceNumber).toList();
  }

  // Every test starts with a fresh repository and an empty session.
  setUp(() async {
    repository = InMemoryConversationSessionRepository();

    await repository.createSession(session('A'));
  });

  // TEST 1
  test(
    'creating a session with a duplicate ID does not overwrite the original',
    () async {
      final original = await repository.appendMessage(
        'A',
        const NewConversationMessage(role: 'user', content: 'Original message'),
      );

      final metadata = (await repository.getSession('A'))!;

      await expectLater(
        repository.createSession(session('A', title: 'Different')),
        throwsStateError,
      );

      final stored = (await repository.getSession('A'))!;

      // Verify that the original metadata is unchanged.
      expect(stored.id, 'A');
      expect(stored.title, metadata.title);
      expect(stored.createdAt, metadata.createdAt);
      expect(stored.updatedAt, metadata.updatedAt);

      // Verify that the original message is unchanged.
      final message = (await repository.getMessages('A')).single;

      expect(message.id, original.id);
      expect(message.sessionId, 'A');
      expect(message.role, 'user');
      expect(message.content, 'Original message');
      expect(message.createdAt, original.createdAt);
      expect(message.sequenceNumber, 1);
    },
  );

  // TEST 2
  test('latest page returns the newest ten in ascending order', () async {
    await append(25);

    expect(
      await sequences(limit: 10),
      orderedEquals(List.generate(10, (i) => i + 16)),
    );
  });

  // TEST 3
  test('cursor retrieves preceding page', () async {
    await append(25);

    final first = await sequences(limit: 10);

    expect(
      await sequences(limit: 10, before: first.first),
      orderedEquals(List.generate(10, (i) => i + 6)),
    );
  });

  // TEST 4
  test('oldest page may contain fewer than limit', () async {
    await append(25);

    expect(
      await sequences(limit: 10, before: 6),
      orderedEquals([1, 2, 3, 4, 5]),
    );
  });

  // TEST 5
  test('cursor before first message returns empty', () async {
    await append(3);

    expect(await sequences(before: 1), isEmpty);
  });

  // TEST 6
  test('empty session returns empty page', () async {
    expect(await sequences(), isEmpty);
  });

  // TEST 7
  test('limit larger than history returns all messages', () async {
    await append(3);

    expect(await sequences(limit: 100), orderedEquals([1, 2, 3]));
  });

  // TEST 8
  test('cursor beyond newest message returns latest matching page', () async {
    await append(3);

    expect(await sequences(limit: 2, before: 100), orderedEquals([2, 3]));
  });

  // TEST 9
  test('nonpositive limits are rejected', () async {
    for (final limit in [0, -1]) {
      await expectLater(
        repository.getMessages('A', limit: limit),
        throwsArgumentError,
      );
    }
  });

  // TEST 10
  test('retrieving messages for nonexistent session fails', () async {
    await expectLater(repository.getMessages('missing'), throwsStateError);
  });

  // TEST 11
  test('returned message list is unmodifiable', () async {
    await append(1);

    final page = await repository.getMessages('A');

    expect(() => page.clear(), throwsUnsupportedError);

    // Verify that storage was not modified.
    expect(await sequences(), orderedEquals([1]));
  });

  // TEST 12
  test('retrieved page remains unchanged after append', () async {
    await append(2);

    final page = await repository.getMessages('A');

    await append(1);

    // The previously retrieved snapshot must remain unchanged.
    expect(
      page.map((message) => message.sequenceNumber),
      orderedEquals([1, 2]),
    );

    // A new retrieval should include the newly appended message.
    expect(await sequences(), orderedEquals([1, 2, 3]));
  });

  // TEST 13
  test('deleting a session removes metadata and accessible messages', () async {
    await append(3);

    await repository.deleteSession('A');

    // Session metadata must no longer exist.
    expect(await repository.getSession('A'), isNull);

    // Retrieving messages must fail.
    await expectLater(repository.getMessages('A'), throwsStateError);

    // Appending messages must also fail.
    await expectLater(
      repository.appendMessage(
        'A',
        const NewConversationMessage(role: 'user', content: 'Deleted'),
      ),
      throwsStateError,
    );

    // Recreate the session using the same ID.
    await repository.createSession(session('A'));

    // No previous messages should be accessible.
    expect(await sequences(), isEmpty);

    await append(1);

    // Sequence numbering must start from 1 again.
    expect(await sequences(), orderedEquals([1]));
  });

  // TEST 14
  test('deleting one session leaves another unchanged', () async {
    await repository.createSession(session('B'));

    await append(2, id: 'B');
    await append(3);

    final before = await repository.getMessages('B');

    await repository.deleteSession('A');

    expect(await repository.getSession('B'), isNotNull);

    final after = await repository.getMessages('B');

    expect(
      after.map((message) => message.id),
      orderedEquals(before.map((message) => message.id)),
    );
  });

  // TEST 15
  test(
    'append updates last activity without changing other metadata',
    () async {
      final message = await repository.appendMessage(
        'A',
        const NewConversationMessage(role: 'user', content: 'Hello'),
      );

      final updated = (await repository.getSession('A'))!;

      // Last activity must have changed.
      expect(updated.updatedAt.isAfter(initialTime), isTrue);

      expect(updated.updatedAt, message.createdAt);

      // Original metadata must remain unchanged.
      expect(updated.createdAt, initialTime);
      expect(updated.title, 'Original');
      expect(updated.id, 'A');
    },
  );

  // TEST 16
  test('new appends do not shift older cursor pages', () async {
    await append(10);

    // Retrieve messages 6 through 10.
    final first = await sequences(limit: 5);

    // Simulate new messages arriving.
    await append(2);

    // Retrieve older messages using the original cursor.
    final older = await sequences(limit: 5, before: first.first);

    expect(first, orderedEquals([6, 7, 8, 9, 10]));

    expect(older, orderedEquals([1, 2, 3, 4, 5]));

    // Verify that the newly appended messages also exist.
    expect(await sequences(limit: 2), orderedEquals([11, 12]));
  });

  group('Conversation session pagination', () {
    late InMemoryConversationSessionRepository repository;

    final older = DateTime.utc(2026, 11, 20);
    final newer = DateTime.utc(2026, 11, 24);

    setUp(() {
      repository = InMemoryConversationSessionRepository();
    });

    Future<void> createSession(String id, DateTime updatedAt) async {
      await repository.createSession(
        ConversationSession(
          id: id,
          title: 'Conversation $id',
          createdAt: updatedAt,
          updatedAt: updatedAt,
        ),
      );
    }

    ConversationSessionCursor cursorFrom(ConversationSession session) {
      return ConversationSessionCursor(
        updatedAt: session.updatedAt,
        id: session.id,
      );
    }

    test('empty repository returns an empty list', () async {
      final sessions = await repository.getSessions();

      expect(sessions, isEmpty);
    });

    test('sessions are ordered by updatedAt descending', () async {
      await createSession('A', older);
      await createSession('B', newer);
      await createSession('C', DateTime.utc(2026, 11, 22));

      final sessions = await repository.getSessions();

      expect(sessions.map((session) => session.id).toList(), ['B', 'C', 'A']);
    });

    test('identical timestamps are ordered by ID ascending', () async {
      await createSession('C', newer);
      await createSession('A', newer);
      await createSession('B', newer);

      final sessions = await repository.getSessions();

      expect(sessions.map((session) => session.id).toList(), ['A', 'B', 'C']);
    });

    test('requested page size is respected', () async {
      await createSession('A', newer);
      await createSession('B', newer);
      await createSession('C', older);

      final sessions = await repository.getSessions(limit: 2);

      expect(sessions.length, 2);

      expect(sessions.map((session) => session.id).toList(), ['A', 'B']);
    });

    test('composite cursor retrieves the next page', () async {
      await createSession('A', newer);
      await createSession('B', newer);
      await createSession('C', newer);
      await createSession('D', older);

      final firstPage = await repository.getSessions(limit: 2);

      final secondPage = await repository.getSessions(
        limit: 2,
        cursor: cursorFrom(firstPage.last),
      );

      expect(firstPage.map((session) => session.id).toList(), ['A', 'B']);

      expect(secondPage.map((session) => session.id).toList(), ['C', 'D']);
    });

    test('pagination does not skip or duplicate sessions', () async {
      await createSession('E', older);
      await createSession('C', newer);
      await createSession('A', newer);
      await createSession('D', older);
      await createSession('B', newer);

      final retrievedIds = <String>[];

      ConversationSessionCursor? cursor;

      // Bounded iteration prevents a broken cursor from
      // causing an infinite test loop.
      for (var i = 0; i < 4; i++) {
        final page = await repository.getSessions(limit: 2, cursor: cursor);

        if (page.isEmpty) {
          break;
        }

        retrievedIds.addAll(page.map((session) => session.id));

        cursor = cursorFrom(page.last);
      }

      expect(retrievedIds, ['A', 'B', 'C', 'D', 'E']);
      expect(retrievedIds.toSet().length, 5);
    });

    test('cursor remains valid after its session is deleted', () async {
      await createSession('A', newer);
      await createSession('B', newer);
      await createSession('C', older);
      await createSession('D', older);

      final firstPage = await repository.getSessions(limit: 2);

      final cursor = cursorFrom(firstPage.last);

      await repository.deleteSession('B');

      final secondPage = await repository.getSessions(limit: 2, cursor: cursor);

      expect(secondPage.map((session) => session.id).toList(), ['C', 'D']);
    });

    test('cursor at the final session returns an empty page', () async {
      await createSession('A', newer);
      await createSession('B', older);

      final firstPage = await repository.getSessions();

      final nextPage = await repository.getSessions(
        cursor: cursorFrom(firstPage.last),
      );

      expect(nextPage, isEmpty);
    });

    test('zero and negative limits are rejected', () async {
      await expectLater(repository.getSessions(limit: 0), throwsArgumentError);

      await expectLater(repository.getSessions(limit: -1), throwsArgumentError);
    });

    test('appending a message moves a session to the top', () async {
      await createSession('A', older);
      await createSession('B', newer);

      final before = await repository.getSessions();

      expect(before.map((session) => session.id).toList(), ['B', 'A']);

      await repository.appendMessage(
        'A',
        const NewConversationMessage(
          role: 'user',
          content: 'Continuing an older conversation',
        ),
      );

      final after = await repository.getSessions();

      expect(after.map((session) => session.id).toList(), ['A', 'B']);

      expect(after.first.updatedAt.isAfter(newer), isTrue);
    });
  });
}
