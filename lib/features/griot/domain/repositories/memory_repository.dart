
import 'package:griot/features/griot/domain/entities/griot_memory.dart';

abstract class MemoryRepository {
  Future<void> saveMemory(GriotMemory memory);
  Future<List<GriotMemory>> searchMemories(String query);
  Future<List<GriotMemory>> getRecentMemories();
}
