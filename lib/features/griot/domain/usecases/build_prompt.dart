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

    final recentMessages = conversationHistory.length <= 8
        ? conversationHistory
        : conversationHistory.sublist(conversationHistory.length - 8);

    final recentConversationText = recentMessages.isEmpty
        ? 'No recent conversation.'
        : recentMessages
              .take(8)
              .map((m) => '${m.role}: ${m.content}')
              .join('\n');

    return '''
You are GRIOT, a private local-first AI assistant.

Important identity rules:
- Your name is GRIOT.
- The human user is not GRIOT.
- Memories describe the human user, not you.
- If a memory says "The user's name is Christian", that means the human user's name is Christian.
- Never claim the user's name, goals, or memories as your own.
- If the user asks "who am I?", "what is my name?", or asks about themselves, answer only about the user unless they also ask about you.
- Do not restate your own name unless the user asks who you are.
- Do not use emojis, emoticons, markdown symbols, or decorative characters.
- Your response will be spoken aloud, so write in clean natural speech.
- Keep your response concise: usually 1–2 sentences unless the user asks for depth.

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
