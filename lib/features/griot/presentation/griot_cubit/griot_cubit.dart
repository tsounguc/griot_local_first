import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:griot/features/griot/domain/entities/conversation_message.dart';
import 'package:griot/features/griot/domain/services/conversation_session_manager.dart';
import 'package:griot/features/griot/domain/services/speech_output_service.dart';
import 'package:griot/features/griot/domain/services/voice_input_service.dart';
import 'package:griot/features/griot/domain/usecases/route_cluster_task.dart';
import 'package:griot/features/griot/domain/usecases/run_griot_core_loop.dart';

part 'griot_state.dart';

class GriotCubit extends Cubit<GriotState> {
  GriotCubit({
    required this.runGriotCoreLoop,
    required this.speechOutputService,
    required this.voiceInputService,
    required this.routeClusterTask,
    required this.sessionManager,
  }) : super(GriotIdle());

  final RunGriotCoreLoop runGriotCoreLoop;
  final SpeechOutputService speechOutputService;
  final VoiceInputService voiceInputService;
  final RouteClusterTask routeClusterTask;
  final ConversationSessionManager sessionManager;

  String? _activeSessionId;
  Future<String>? _pendingSessionCreation;

  Future<String> _ensureActiveSession() async {
    // A session already exists.
    if (_activeSessionId != null) {
      return Future.value(_activeSessionId!);
    }

    // A session is currently being created.
    // Reuse the existing Future instead of creating another session.
    if (_pendingSessionCreation != null) {
      return _pendingSessionCreation!;
    }

    // No session exists and no creation is in progress.
    final creation = _createActiveSession();
    _pendingSessionCreation = creation;

    return creation;
  }

  Future<String> _createActiveSession() async {
    try {
      final session = await sessionManager.createSession();
      _activeSessionId = session.id;

      return session.id;
    } finally {
      _pendingSessionCreation = null;
    }
  }

  Future<void> startVoiceInput() async {
    try {
      await speechOutputService.stop();
      await voiceInputService.startListening();
      emit(const GriotListening());
    } catch (e) {
      emit(GriotError('Could not start voice input: $e'));
    }
  }

  Future<void> stopVoiceInput() async {
    if (state is! GriotListening) return;

    emit(const GriotTranscribing());

    try {
      final transcript = await voiceInputService.stopListeningAndTranscribe();

      if (transcript.trim().isEmpty) {
        emit(const GriotError('I did not hear anything clearly.'));
        return;
      }

      emit(const GriotThinking());

      await submitTextInput(transcript, emitThinking: false);
    } catch (e) {
      emit(GriotError('Voice input failed: $e'));
    }
  }

  Future<void> submitTextInput(String input, {bool emitThinking = true}) async {
    if (input.trim().isEmpty) return;

    // Capture the session identity for this request.
    String? requestSessionId;

    if (emitThinking) {
      emit(const GriotThinking());
    }

    try {
      requestSessionId = await _ensureActiveSession();

      // Retrieve the conversation before appending the new message.
      final session = await sessionManager.getSession(requestSessionId);

      if (session == null) {
        throw StateError('Session $requestSessionId does not exist');
      }

      final previousHistory = List<ConversationMessage>.unmodifiable(
        session.messages,
      );

      await sessionManager.addMessage(
        ConversationMessage(role: 'user', content: input),
        requestSessionId,
      );

      late final String response;
      late final String model;
      late final String taskType;

      // Handle distributed summarization.
      if (input.startsWith('/summarize ')) {
        response = await routeClusterTask(
          task: 'summarize_text',
          message: input.replaceFirst('/summarize ', ''),
        );

        model = 'GRIOT Cluster';
        taskType = 'summarize_text';
      }
      // Handle distributed chat.
      else if (input.startsWith('/chat ')) {
        response = await routeClusterTask(
          task: 'ollama_chat',
          message: input.replaceFirst('/chat ', ''),
        );

        model = 'GRIOT Cluster';
        taskType = 'ollama_chat';
      } else {
        final result = await runGriotCoreLoop(
          input,
          conversationHistory: previousHistory,
        );

        response = result.response;
        model = result.route.modelName;
        taskType = result.route.taskType.name;
      }

      // Always append to the originating session
      await sessionManager.addMessage(
        ConversationMessage(role: 'assistant', content: response),
        requestSessionId,
      );

      // Only update the visible conversation if it is still active
      if (_activeSessionId == requestSessionId && !isClosed) {
        emit(
          GriotSpeaking(response: response, model: model, taskType: taskType),
        );

        await _speakSafely(response);
      }
    } catch (e, stackTrace) {
      debugPrint('GRIOT ERROR: $e');
      debugPrint('$stackTrace');

      // Don't display error from an inactive session.
      if (!isClosed &&
          (requestSessionId == null || _activeSessionId == requestSessionId)) {
        emit(GriotError('Something went wrong: $e'));
        await _speakSafely('Something went wrong.');
      }
    }
  }

  Future<void> stopSpeaking() async {
    await speechOutputService.stop();

    if (state is GriotSpeaking) {
      emit(const GriotIdle());
    }
  }

  void resetToIdle() {
    emit(const GriotIdle());
  }

  Future<void> _speakSafely(String text) async {
    try {
      await speechOutputService.speak(text);
    } catch (e) {
      debugPrint('GRIOT speech output unavailable: $e');
    }
  }
}
