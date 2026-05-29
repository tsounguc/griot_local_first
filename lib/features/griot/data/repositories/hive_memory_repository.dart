import 'package:griot/features/griot/data/models/griot_memory_model.dart';
import 'package:griot/features/griot/domain/entities/griot_memory.dart';
import 'package:griot/features/griot/domain/repositories/memory_repository.dart';
import 'package:hive/hive.dart';

class HiveMemoryRepository implements MemoryRepository {
  HiveMemoryRepository(this.box);

  final Box<GriotMemoryModel> box;

  @override
  Future<void> saveMemory(GriotMemory memory) async {
    final model = GriotMemoryModel.fromEntity(memory);
    await box.put(memory.id, model);
  }

  @override
  Future<List<GriotMemory>> searchMemories(String query) async {
    final queryWords = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 3)
        .toList();

    final memories = box.values.map((model) => model.toEntity()).toList();

    final results = memories.where((memory) {
      final content = memory.content.toLowerCase();
      final tags = memory.tags.map((tag) => tag.toLowerCase()).join(' ');

      return queryWords.any((word) {
        return content.contains(word) || tags.contains(word);
      });
    }).toList();

    results.sort((a, b) {
      final importanceCompare = b.importance.compareTo(a.importance);
      if (importanceCompare != 0) return importanceCompare;

      return b.updatedAt.compareTo(a.updatedAt);
    });

    return results;
  }

  @override
  Future<List<GriotMemory>> getRecentMemories() async {
    final memories = box.values.map((model) => model.toEntity()).toList();

    memories.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return memories.take(10).toList();
  }
}
