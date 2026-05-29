import 'package:griot/features/griot/domain/repositories/memory_repository.dart';

class DeleteMemory {
  const DeleteMemory(this.repository);

  final MemoryRepository repository;

  Future<void> call(String id) {
    return repository.deleteMemory(id);
  }
}
