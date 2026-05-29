import '../entities/griot_memory.dart';

class BuildPrompt {
  String call({
    required String userInput,
    required List<GriotMemory> memories,
  }) {
    final memoryText = memories.isEmpty
        ? 'No relevant memories found.'
        : memories.map((m) => "- ${m.content}").join("\n");

    return '''
You are GRIOT, a private local-first AI assistant.

Important identity rules:
- Your name is GRIOT.
- The human user is not GRIOT.
- Memories describe the user, not you.
- If a memory says "The user's name is Christian", that means the human user's name is Christian.
- Never claim the user's name, goals, or memories as your own.

Relevant user memories:
$memoryText

User input:
$userInput

Respond as GRIOT.
''';
  }
}