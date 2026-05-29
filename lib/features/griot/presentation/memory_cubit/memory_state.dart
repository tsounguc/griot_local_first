part of 'memory_cubit.dart';

sealed class MemoryState extends Equatable {
  const MemoryState();

  @override
  List<Object?> get props => [];
}

final class MemoryInitial extends MemoryState {
  const MemoryInitial();
}

final class MemoryLoading extends MemoryState {
  const MemoryLoading();
}

final class MemoryLoaded extends MemoryState {
  const MemoryLoaded(this.memories);

  final List<GriotMemory> memories;

  @override
  List<Object?> get props => [memories];
}

final class MemoryFailure extends MemoryState {
  const MemoryFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
