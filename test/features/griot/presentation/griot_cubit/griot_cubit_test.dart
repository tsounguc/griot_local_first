import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:griot/features/griot/data/repositories/in_memory_conversation_session_repository.dart';
import 'package:griot/features/griot/domain/entities/conversation_message.dart';
import 'package:griot/features/griot/domain/entities/conversation_session.dart';
import 'package:griot/features/griot/domain/entities/griot_conversation_result.dart';
import 'package:griot/features/griot/domain/entities/griot_model_route.dart';
import 'package:griot/features/griot/domain/entities/griot_task_type.dart';
import 'package:griot/features/griot/domain/services/conversation_session_manager.dart';
import 'package:griot/features/griot/domain/services/speech_output_service.dart';
import 'package:griot/features/griot/domain/services/voice_input_service.dart';
import 'package:griot/features/griot/domain/usecases/run_griot_core_loop.dart';
import 'package:griot/features/griot/domain/usecases/route_cluster_task.dart';
import 'package:griot/features/griot/presentation/griot_cubit/griot_cubit.dart';

class FakeSpeechOutputService implements SpeechOutputService {
  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}

class FakeVoiceInputService implements VoiceInputService {
  @override
  Future<void> startListening() async {}

  @override
  Future<String> stopListeningAndTranscribe() async => 'Test message';
}

// These two fakes are placeholders for this specific test.
// The test never invokes their methods.
class FakeCoreLoop implements RunGriotCoreLoop {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeClusterTask implements RouteClusterTask {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CountingSessionRepository extends InMemoryConversationSessionRepository {
  int creationCount = 0;

  @override
  Future<void> createSession(ConversationSession session) async {
    await super.createSession(session);
    creationCount++;
  }
}

class ControlledCoreLoop implements RunGriotCoreLoop {
  final started = Completer<void>();
  final responseCompleter = Completer<GriotConversationResult>();

  @override
  Future<GriotConversationResult> call(
    String userInput, {
    List<ConversationMessage> conversationHistory = const [],
  }) {
    if (!started.isCompleted) {
      started.complete();
    }

    return responseCompleter.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DelayedSessionRepository extends CountingSessionRepository {
  final creationStarted = Completer<void>();
  final allowCreationToFinish = Completer<void>();

  bool delayNextCreation = false;

  @override
  Future<void> createSession(ConversationSession session) async {
    if (delayNextCreation) {
      delayNextCreation = false;

      if (!creationStarted.isCompleted) {
        creationStarted.complete();
      }

      // Hold the creation operation until the test releases it.
      await allowCreationToFinish.future;
    }

    await super.createSession(session);
  }
}

void main() {
  test('starting a new conversation does not create a session', () async {
    final repository = CountingSessionRepository();
    final manager = ConversationSessionManager(repository);

    final cubit = GriotCubit(
      runGriotCoreLoop: FakeCoreLoop(),
      speechOutputService: FakeSpeechOutputService(),
      voiceInputService: FakeVoiceInputService(),
      routeClusterTask: FakeClusterTask(),
      sessionManager: manager,
    );

    try {
      cubit.startNewConversation();

      expect(repository.creationCount, 0);
      expect(cubit.state, isA<GriotIdle>());
    } finally {
      await cubit.close();
    }
  });

  test(
    'LLM response remains in its originating session after switching',
    () async {
      final repository = CountingSessionRepository();
      final manager = ConversationSessionManager(repository);
      final coreLoop = ControlledCoreLoop();

      final cubit = GriotCubit(
        runGriotCoreLoop: coreLoop,
        speechOutputService: FakeSpeechOutputService(),
        voiceInputService: FakeVoiceInputService(),
        routeClusterTask: FakeClusterTask(),
        sessionManager: manager,
      );

      try {
        // Create two independent sessions.
        final sessionA = await manager.createSession();
        final sessionB = await manager.createSession();

        // Select Session A.
        await cubit.switchConversation(sessionA.id);

        // Begin a request without waiting for inference to finish.
        final pendingRequest = cubit.submitTextInput('Hello from Session A');

        // Wait until the fake LLM has actually started.
        await coreLoop.started.future;

        // The user switches conversations during inference.
        await cubit.switchConversation(sessionB.id);

        // Now allow the LLM to finish.
        coreLoop.responseCompleter.complete(
          GriotConversationResult(
            response: 'Response for Session A',
            route: const GriotModelRoute(
              taskType: GriotTaskType.general,
              modelName: 'Fake LLM',
            ),
          ),
        );

        await pendingRequest;

        // Retrieve the stored histories.
        final updatedA = await manager.getSession(sessionA.id);
        final updatedB = await manager.getSession(sessionB.id);

        // Session A should contain the complete exchange.
        expect(updatedA, isNotNull);
        expect(updatedA!.messages.length, 2);

        expect(updatedA.messages[0].role, 'user');
        expect(updatedA.messages[0].content, 'Hello from Session A');

        expect(updatedA.messages[1].role, 'assistant');
        expect(updatedA.messages[1].content, 'Response for Session A');

        // Session B must remain untouched.
        expect(updatedB, isNotNull);
        expect(updatedB!.messages, isEmpty);

        // A's response must not become B's visible state.
        expect(cubit.state, isA<GriotIdle>());
      } finally {
        await cubit.close();
      }
    },
  );

  test(
    'a delayed session creation cannot override a newer selection',
    () async {
      final repository = DelayedSessionRepository();
      final manager = ConversationSessionManager(repository);
      final coreLoop = ControlledCoreLoop();

      final cubit = GriotCubit(
        runGriotCoreLoop: coreLoop,
        speechOutputService: FakeSpeechOutputService(),
        voiceInputService: FakeVoiceInputService(),
        routeClusterTask: FakeClusterTask(),
        sessionManager: manager,
      );

      Future<void>? pendingRequest;

      try {
        // Create Session B before enabling the delay.
        final sessionB = await manager.createSession();

        // Start a new conversation without creating a session yet.
        cubit.startNewConversation();

        // Delay the next repository creation.
        repository.delayNextCreation = true;

        // Sending a message triggers lazy session creation.
        pendingRequest = cubit.submitTextInput('Hello from Session A');

        // Wait until creation is blocked inside the repository.
        await repository.creationStarted.future;

        // Select B while A's creation is still pending.
        await cubit.switchConversation(sessionB.id);

        expect(cubit.activeSessionId, sessionB.id);

        // Release the delayed creation of A.
        repository.allowCreationToFinish.complete();

        // Wait until the request reaches the fake LLM.
        await coreLoop.started.future;

        // Verify that A's creation did not replace B.
        expect(cubit.activeSessionId, sessionB.id);

        // Finish the fake LLM request.
        coreLoop.responseCompleter.complete(
          GriotConversationResult(
            response: 'Response for Session A',
            route: const GriotModelRoute(
              taskType: GriotTaskType.general,
              modelName: 'Fake LLM',
            ),
          ),
        );

        await pendingRequest;

        // B must remain selected even after A finishes.
        expect(cubit.activeSessionId, sessionB.id);
        expect(cubit.state, isA<GriotIdle>());

        // B must not receive A's messages.
        final updatedB = await manager.getSession(sessionB.id);

        expect(updatedB, isNotNull);
        expect(updatedB!.messages, isEmpty);
      } finally {
        if (!repository.allowCreationToFinish.isCompleted) {
          repository.allowCreationToFinish.complete();
        }

        if (!coreLoop.responseCompleter.isCompleted) {
          coreLoop.responseCompleter.complete(
            GriotConversationResult(
              response: 'Cleanup response',
              route: const GriotModelRoute(
                taskType: GriotTaskType.general,
                modelName: 'Fake LLM',
              ),
            ),
          );
        }

        if (pendingRequest != null) {
          await pendingRequest;
        }

        await cubit.close();
      }
    },
  );
}
