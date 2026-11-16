import 'package:equatable/equatable.dart';
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
      _conversationHistory.add(
        ConversationMessage(role: 'user', content: input),
      );

      if (input.startsWith('/summarize ')) {
        final clusterMessage = input.replaceFirst('/summarize ', '');

        final response = await routeClusterTask(
          task: 'summarize_text',
          message: clusterMessage,
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

        // await speechOutputService.speak(response);
        await _speakSafely(response);
        return;
      }

      if (input.startsWith('/chat ')) {
        final clusterMessage = input.replaceFirst('/chat ', '');

        final response = await routeClusterTask(
          task: 'ollama_chat',
          message: clusterMessage,
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

        // await speechOutputService.speak(response);
        await _speakSafely(response);
        return;
      }

      final route = runGriotCoreLoop.selectRoute(input);

      final response = await runGriotCoreLoop(
        input,
        conversationHistory: _conversationHistory,
      );
      _conversationHistory.add(
        ConversationMessage(role: 'assistant', content: response),
      );

      emit(
        GriotSpeaking(
          response: response,
          model: route.modelName,
          taskType: route.taskType.name,
        ),
      );
      // await speechOutputService.speak(response);
      await _speakSafely(response);
    } catch (e, stackTrace) {
      print('GRIOT ERROR: $e');
      print(stackTrace);

      final fallbackMessage = 'Something went wrong: $e';

      emit(GriotError(fallbackMessage));
      await speechOutputService.speak('Something went wrong.');
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

  bool _endsSentence(String text) {
    final trimmed = text.trim();
    return trimmed.endsWith('.') ||
        trimmed.endsWith('?') ||
        trimmed.endsWith('!') ||
        trimmed.endsWith('\n');
  }

  Future<void> _speakSafely(String text) async {
    try {
      await speechOutputService.speak(text);
    } catch (e) {
      print('GRIOT speech output unavailable: $e');
    }
  }
}
