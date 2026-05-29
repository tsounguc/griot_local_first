import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:griot/features/griot/domain/usecases/run_griot_core_loop.dart';

part 'griot_state.dart';

class GriotCubit extends Cubit<GriotState> {
  final RunGriotCoreLoop runGriotCoreLoop;

  GriotCubit(this.runGriotCoreLoop) : super(GriotInitial());

  Future<void> submitInput(String input) async {
    if (input.trim().isEmpty) return;

    emit(GriotLoading());

    try {
      final response = await runGriotCoreLoop(input);
      emit(GriotSuccess(response));
    } catch (e) {
      emit(GriotFailure(e.toString()));
    }
  }
}
