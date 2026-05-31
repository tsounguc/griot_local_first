import 'package:griot/features/griot/domain/entities/conversation_message.dart';

import '../entities/griot_memory.dart';

class BuildPrompt {
  String call({
    required String userInput,
    required List<GriotMemory> memories,
    List<ConversationMessage> conversationHistory = const [],
  }) {
    final memoryText = memories.isEmpty
        ? 'No relevant memories found.'
        : memories.map((m) => "- ${m.content}").join("\n");

    final recentConversationText = conversationHistory.isEmpty
        ? 'No recent conversation.'
        : conversationHistory
              .take(8)
              .map((m) => '${m.role}: ${m.content}')
              .join('\n');

    return '''
You are GRIOT, a private local-first AI assistant.

Important identity rules:
- Your name is GRIOT.
- The human user is not GRIOT.
- Memories describe the user, not you.
- If a memory says "The user's name is Christian", that means the human user's name is Christian.
- Never claim the user's name, goals, or memories as your own.
- Keep your response concise: usually 1–4 sentences unless the user asks for depth.

Relevant long-term memories:
$memoryText

Recent conversation:
$recentConversationText

Current user input:
$userInput

Respond as GRIOT.
''';
  }
}
