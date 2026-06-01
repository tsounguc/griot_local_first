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
    final lowerQuery = query.toLowerCase();

    final queryWords = lowerQuery
        .split(RegExp(r'\s+'))
        .map((word) => word.replaceAll(RegExp(r'[^a-z0-9]'), ''))
        .where((word) => word.length > 2)
        .toList();

    final isIdentityQuery = _isIdentityQuery(lowerQuery);

    final results = _memories.where((memory) {
      final content = memory.content.toLowerCase();
      final tags = memory.tags.map((tag) => tag.toLowerCase()).join(' ');

      if (isIdentityQuery) {
        return content.contains('user\'s name') ||
            content.contains('user name') ||
            tags.contains('identity') ||
            tags.contains('name');
      }

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
    final sorted = [..._memories]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return sorted.take(10).toList();
  }

  @override
  Future<List<GriotMemory>> getAllMemories() async {
    final sorted = [..._memories]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return sorted;
  }

  @override
  Future<void> deleteMemory(String id) async {
    _memories.removeWhere((memory) => memory.id == id);
  }

  bool _isIdentityQuery(String input) {
    return input.contains('what is my name') ||
        input.contains("what's my name") ||
        input.contains('who am i') ||
        input.contains('who am i?') ||
        input.contains('my name');
  }
}
