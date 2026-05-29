import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:griot/features/griot/domain/services/speech_output_service.dart';
import 'package:griot/features/griot/domain/usecases/run_griot_core_loop.dart';

part 'griot_state.dart';

class GriotCubit extends Cubit<GriotState> {
  final RunGriotCoreLoop runGriotCoreLoop;
  final SpeechOutputService speechOutputService;

  GriotCubit({
    required this.runGriotCoreLoop,
    required this.speechOutputService,
  }) : super(GriotInitial());

  Future<void> submitInput(String input) async {
    if (input.trim().isEmpty) return;

    emit(GriotLoading());

    try {
      final response = await runGriotCoreLoop(input);
      await speechOutputService.speak(response);
      emit(GriotSuccess(response));
    } catch (e) {
      await speechOutputService.speak('Something went wrong.');
      emit(GriotFailure(e.toString()));
    }
  }

  Future<void> stopSpeaking() async {
    await speechOutputService.stop();
  }
}
