import 'package:griot/features/griot/domain/entities/griot_memory.dart';
import 'package:griot/features/griot/domain/repositories/memory_repository.dart';

class GetAllMemories {
  const GetAllMemories(this.repository);

  final MemoryRepository repository;

  Future<List<GriotMemory>> call() {
    return repository.getAllMemories();
  }
}
