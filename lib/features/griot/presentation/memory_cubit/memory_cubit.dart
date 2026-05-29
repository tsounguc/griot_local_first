import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:griot/features/griot/domain/entities/griot_memory.dart';
import 'package:griot/features/griot/domain/usecases/delete_memory.dart';
import 'package:griot/features/griot/domain/usecases/get_all_memories.dart';

part 'memory_state.dart';

class MemoryCubit extends Cubit<MemoryState> {
  MemoryCubit({required this.getAllMemories, required this.deleteMemory})
    : super(const MemoryInitial());

  final GetAllMemories getAllMemories;
  final DeleteMemory deleteMemory;

  Future<void> loadMemories() async {
    emit(const MemoryLoading());

    try {
      final memories = await getAllMemories();
      emit(MemoryLoaded(memories));
    } catch (e) {
      emit(MemoryFailure(e.toString()));
    }
  }

  Future<void> removeMemory(String id) async {
    try {
      await deleteMemory(id);
      await loadMemories();
    } catch (e) {
      emit(MemoryFailure(e.toString()));
    }
  }
}
