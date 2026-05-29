import 'package:griot/features/griot/domain/entities/conversation_message.dart';
import 'package:griot/features/griot/domain/entities/griot_memory.dart';
import 'package:griot/features/griot/domain/gateways/llm_gateway.dart';
import 'package:griot/features/griot/domain/repositories/memory_repository.dart';
import 'package:griot/features/griot/domain/usecases/calculate_memory_importance.dart';
import 'package:griot/features/griot/domain/usecases/should_remember.dart';

import 'build_prompt.dart';

class RunGriotCoreLoop {
  final MemoryRepository memoryRepository;
  final LLMGateway llmGateway;
  final BuildPrompt buildPrompt;

  RunGriotCoreLoop({
    required this.memoryRepository,
    required this.llmGateway,
    required this.buildPrompt,
  });

  Future<String> call(
    String userInput, {
    List<ConversationMessage> conversationHistory = const [],
  }) async {
    final memories = await memoryRepository.searchMemories(userInput);

    final prompt = buildPrompt(
      userInput: userInput,
      memories: memories,
      conversationHistory: conversationHistory,
    );

    final response = await llmGateway.generateResponse(prompt: prompt);

    if (shouldRemember(userInput)) {
      final now = DateTime.now();

      await memoryRepository.saveMemory(
        GriotMemory(
          id: now.microsecondsSinceEpoch.toString(),
          content: userInput,
          tags: ['user-input'],
          createdAt: now,
          updatedAt: now,
          importance: calculateMemoryImportance(userInput),
        ),
      );
    }

    return response;
  }
}
