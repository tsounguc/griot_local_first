import 'package:griot/features/griot/domain/entities/griot_memory.dart';
import 'package:griot/features/griot/domain/gateways/llm_gateway.dart';
import 'package:griot/features/griot/domain/repositories/memory_repository.dart';
import 'package:griot/features/griot/domain/usecases/build_prompt.dart';
import 'package:griot/features/griot/domain/usecases/normalize_memory.dart';
import 'package:griot/features/griot/domain/usecases/should_remember.dart';

class RunGriotCoreLoop {
  final MemoryRepository memoryRepository;
  final LLMGateway llmGateway;
  final BuildPrompt buildPrompt;

  RunGriotCoreLoop({
    required this.memoryRepository,
    required this.llmGateway,
    required this.buildPrompt,
  });

  Future<String> call(String userInput) async {
    final matchingMemories = await memoryRepository.searchMemories(userInput);
    final recentMemories = await memoryRepository.getRecentMemories();

    final memories = {
      for (final memory in [...matchingMemories, ...recentMemories])
        memory.id: memory,
    }.values.toList();

    final prompt = buildPrompt(
      userInput: userInput,
      memories: memories,
    );

    final response = await llmGateway.generateResponse(prompt: prompt);

    if (shouldRemember(userInput)) {
      final now = DateTime.now();

      await memoryRepository.saveMemory(
        GriotMemory(
          id: now.microsecondsSinceEpoch.toString(),
          content: normalizeMemory(userInput),
          tags: _extractTags(userInput),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    return response;
  }

  List<String> _extractTags(String input) {
    final lower = input.toLowerCase();

    return [
      if (lower.contains('griot')) 'griot',
      if (lower.contains('local')) 'local-first',
      if (lower.contains('ai')) 'ai',
      if (lower.contains('goal')) 'goal',
      if (lower.contains('architecture')) 'architecture',
      'user-input',
    ];
  }
}