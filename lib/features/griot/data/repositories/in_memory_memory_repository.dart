import 'package:griot/features/griot/domain/entities/griot_memory.dart';
import 'package:griot/features/griot/domain/repositories/memory_repository.dart';

class InMemoryMemoryRepository implements MemoryRepository {
  final List<GriotMemory> _memories = [];

  @override
  Future<void> saveMemory(GriotMemory memory) async {
    _memories.add(memory);
  }

  @override
  Future<List<GriotMemory>> searchMemories(String query) async {
    final queryWords = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 3)
        .toList();

    return _memories.where((memory) {
      final content = memory.content.toLowerCase();
      final tags = memory.tags.map((tag) => tag.toLowerCase()).join(' ');

      return queryWords.any((word) {
        return content.contains(word) || tags.contains(word);
      });
    }).toList();
  }

  @override
  Future<List<GriotMemory>> getRecentMemories() async {
    final sorted = [..._memories]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return sorted.take(10).toList();
  }

  @override
  Future<List<GriotMemory>> getAllMemories() async {
    final sorted = [..._memories]
      ..sort((a, b) {
        final importanceCompare = b.importance.compareTo(a.importance);
        if (importanceCompare != 0) return importanceCompare;

        return b.updatedAt.compareTo(a.updatedAt);
      });

    return sorted;
  }

  @override
  Future<void> deleteMemory(String id) async {
    _memories.removeWhere((memory) => memory.id == id);
  }
}
