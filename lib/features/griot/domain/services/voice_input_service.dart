// abstract class VoiceInputService {
//   Future<bool> initialize();
//
//   Future<void> startListening({
//     required Function(String recognizedText) onResult,
//   });
//
//   Future<void> stopListening();
//
//   bool get isListening;
// }

abstract class VoiceInputService {
  Future<String> listen();
}
