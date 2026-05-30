import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:griot/features/griot/domain/entities/conversation_message.dart';
import 'package:griot/features/griot/domain/services/speech_output_service.dart';
import 'package:griot/features/griot/domain/services/voice_input_service.dart';
import 'package:griot/features/griot/domain/usecases/run_griot_core_loop.dart';

part 'griot_state.dart';

class GriotCubit extends Cubit<GriotState> {
  GriotCubit({
    required this.runGriotCoreLoop,
    required this.speechOutputService,
    required this.voiceInputService,
  }) : super(GriotIdle());

  final RunGriotCoreLoop runGriotCoreLoop;
  final SpeechOutputService speechOutputService;
  final VoiceInputService voiceInputService;
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

    emit(const GriotThinking());

    try {
      final transcript = await voiceInputService.stopListeningAndTranscribe();

      if (transcript.trim().isEmpty) {
        emit(const GriotError('I did not hear anything clearly.'));
        return;
      }

      await submitTextInput(transcript);
    } catch (e) {
      emit(GriotError('Voice input failed: $e'));
    }
  }

  Future<void> submitTextInput(String input) async {
    if (input.trim().isEmpty) return;

    emit(const GriotThinking());

    try {
      _conversationHistory.add(
        ConversationMessage(role: 'user', content: input),
      );

      final response = await runGriotCoreLoop(
        input,
        conversationHistory: _conversationHistory,
      );
      _conversationHistory.add(
        ConversationMessage(role: 'assistant', content: response),
      );

      emit(GriotSpeaking(response));
      await speechOutputService.speak(response);
    } catch (e) {
      const fallbackMessage = 'Something went wrong.';

      emit(const GriotError(fallbackMessage));
      await speechOutputService.speak(fallbackMessage);
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
}
