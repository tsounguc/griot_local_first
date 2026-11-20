import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:griot/features/griot/domain/entities/conversation_message.dart';
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
  }) : super(GriotIdle());

  final RunGriotCoreLoop runGriotCoreLoop;
  final SpeechOutputService speechOutputService;
  final VoiceInputService voiceInputService;
  final RouteClusterTask routeClusterTask;

  final List<ConversationMessage> _conversationHistory = [];

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

  // Future<void> submitTextInput(String input, {bool emitThinking = true}) async {
  //   if (input.trim().isEmpty) return;
  //
  //   if (emitThinking) {
  //     emit(const GriotThinking());
  //   }
  //
  //   try {
  //     _conversationHistory.add(
  //       ConversationMessage(role: 'user', content: input),
  //     );
  //
  //     final fullResponse = StringBuffer();
  //     final sentenceBuffer = StringBuffer();
  //
  //     final route = runGriotCoreLoop.selectRoute(input);
  //
  //     await for (final token in runGriotCoreLoop.stream(
  //       input,
  //       conversationHistory: _conversationHistory,
  //     )) {
  //       fullResponse.write(token);
  //       sentenceBuffer.write(token);
  //
  //       emit(
  //         GriotSpeaking(
  //           response: fullResponse.toString(),
  //           model: route.modelName,
  //           taskType: route.taskType.name,
  //         ),
  //       );
  //
  //       final currentSentence = sentenceBuffer.toString();
  //
  //       if (_endsSentence(currentSentence)) {
  //         final sentence = currentSentence.trim();
  //         sentenceBuffer.clear();
  //
  //         if (sentence.isNotEmpty) {
  //           await speechOutputService.speak(sentence);
  //         }
  //       }
  //     }
  //
  //     final leftover = sentenceBuffer.toString().trim();
  //
  //     if (leftover.isNotEmpty) {
  //       await speechOutputService.speak(leftover);
  //     }
  //
  //     final finalResponse = fullResponse.toString().trim();
  //
  //     _conversationHistory.add(
  //       ConversationMessage(role: 'assistant', content: finalResponse),
  //     );
  //
  //     emit(
  //       GriotSpeaking(
  //         response: finalResponse,
  //         model: route.modelName,
  //         taskType: route.taskType.name,
  //       ),
  //     );
  //   } catch (e) {
  //     const fallbackMessage = 'Something went wrong.';
  //
  //     emit(const GriotError(fallbackMessage));
  //     await speechOutputService.speak(fallbackMessage);
  //   }
  // }

  Future<void> submitTextInput(String input, {bool emitThinking = true}) async {
    if (input.trim().isEmpty) return;

    if (emitThinking) {
      emit(const GriotThinking());
    }

    try {
      // Handle distributed summarization.
      if (input.startsWith('/summarize ')) {
        final clusterMessage = input.replaceFirst('/summarize ', '');

        final response = await routeClusterTask(
          task: 'summarize_text',
          message: clusterMessage,
        );

        _conversationHistory.add(
          ConversationMessage(role: 'user', content: input),
        );

        _conversationHistory.add(
          ConversationMessage(role: 'assistant', content: response),
        );

        emit(
          GriotSpeaking(
            response: response,
            model: 'GRIOT Cluster',
            taskType: 'summarize_text',
          ),
        );

        await _speakSafely(response);
        return;
      }

      // Handle distributed chat.
      if (input.startsWith('/chat ')) {
        final clusterMessage = input.replaceFirst('/chat ', '');

        final response = await routeClusterTask(
          task: 'ollama_chat',
          message: clusterMessage,
        );

        _conversationHistory.add(
          ConversationMessage(role: 'user', content: input),
        );

        _conversationHistory.add(
          ConversationMessage(role: 'assistant', content: response),
        );

        emit(
          GriotSpeaking(
            response: response,
            model: 'GRIOT Cluster',
            taskType: 'ollama_chat',
          ),
        );

        await _speakSafely(response);
        return;
      }

      // Execute GRIOT's core conversation loop.
      // Pass only previous conversation turns.
      final conversationResults = await runGriotCoreLoop(
        input,
        conversationHistory: List.unmodifiable(_conversationHistory),
      );

      // Record the completed conversation turn.
      _conversationHistory.add(
        ConversationMessage(role: 'user', content: input),
      );

      _conversationHistory.add(
        ConversationMessage(
          role: 'assistant',
          content: conversationResults.response,
        ),
      );

      // Update the UI with the response and selected model.
      emit(
        GriotSpeaking(
          response: conversationResults.response,
          model: conversationResults.route.modelName,
          taskType: conversationResults.route.taskType.name,
        ),
      );

      await _speakSafely(conversationResults.response);
    } catch (e, stackTrace) {
      debugPrint('GRIOT ERROR: $e');
      debugPrint('$stackTrace');

      final fallbackMessage = 'Something went wrong: $e';

      emit(GriotError(fallbackMessage));
      await _speakSafely('Something went wrong.');
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
