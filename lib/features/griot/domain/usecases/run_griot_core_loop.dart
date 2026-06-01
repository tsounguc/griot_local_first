import 'package:griot/features/griot/domain/entities/conversation_message.dart';
import 'package:griot/features/griot/domain/entities/griot_memory.dart';
import 'package:griot/features/griot/domain/entities/griot_model_route.dart';
import 'package:griot/features/griot/domain/gateways/llm_gateway.dart';
import 'package:griot/features/griot/domain/repositories/memory_repository.dart';
import 'package:griot/features/griot/domain/usecases/build_prompt.dart';
import 'package:griot/features/griot/domain/usecases/calculate_memory_importance.dart';
import 'package:griot/features/griot/domain/usecases/normalize_memory.dart';
import 'package:griot/features/griot/domain/usecases/select_model_route.dart';
import 'package:griot/features/griot/domain/usecases/should_remember.dart';

class RunGriotCoreLoop {
  RunGriotCoreLoop({
    required this.memoryRepository,
    required this.llmGateway,
    required this.buildPrompt,
    required this.selectModelRoute,
  });

  final MemoryRepository memoryRepository;
  final LLMGateway llmGateway;
  final BuildPrompt buildPrompt;
  final SelectModelRoute selectModelRoute;

  GriotModelRoute selectRoute(String input) {
    return selectModelRoute(input);
  }

  Future<String> call(
    String userInput, {
    List<ConversationMessage> conversationHistory = const [],
  }) async {
    final route = selectModelRoute(userInput);

    final matchingMemories = await memoryRepository.searchMemories(userInput);
    final recentMemories = await memoryRepository.getRecentMemories();

    final identityMemories = _isIdentityQuery(userInput)
        ? await memoryRepository.searchMemories('user name identity')
        : <GriotMemory>[];

    final memories = {
      for (final memory in [
        ...identityMemories,
        ...matchingMemories,
        ...recentMemories,
      ])
        memory.id: memory,
    }.values.toList();

    final prompt = buildPrompt(
      userInput: userInput,
      memories: memories,
      conversationHistory: conversationHistory,
    );

    final response = await llmGateway.generateResponse(
      prompt: prompt,
      model: route.modelName,
    );

    if (shouldRemember(userInput)) {
      final now = DateTime.now();
      final normalizedMemory = normalizeMemory(userInput);

      await memoryRepository.saveMemory(
        GriotMemory(
          id: now.microsecondsSinceEpoch.toString(),
          content: normalizedMemory,
          tags: _tagsForMemory(normalizedMemory),
          createdAt: now,
          updatedAt: now,
          importance: calculateMemoryImportance(userInput),
        ),
      );
    }

    return response;
  }

  bool _isIdentityQuery(String input) {
    final lower = input.toLowerCase();

    return lower.contains('what is my name') ||
        lower.contains("what's my name") ||
        lower.contains('who am i') ||
        lower.contains('who am i?');
  }

  List<String> _tagsForMemory(String normalizedMemory) {
    final lower = normalizedMemory.toLowerCase();

    if (lower.contains('user\'s name')) {
      return ['user-input', 'identity', 'name'];
    }

    if (lower.contains('goal')) {
      return ['user-input', 'goal'];
    }

    return ['user-input'];
  }
}
