// import 'package:griot/features/griot/domain/services/voice_input_service.dart';
// import 'package:speech_to_text/speech_to_text.dart';

// class SpeechToTextVoiceInputService implements VoiceInputService {
//   SpeechToTextVoiceInputService();
//
//   final SpeechToText _speech = SpeechToText();
//
//   bool _isListening = false;
//
//   @override
//   bool get isListening => _isListening;
//
//   @override
//   Future<bool> initialize() async {
//     return await _speech.initialize();
//   }
//
//   @override
//   Future<void> startListening({
//     required Function(String recognizedText) onResult,
//   }) async {
//     _isListening = true;
//
//     await _speech.listen(
//       onResult: (result) {
//         onResult(result.recognizedWords);
//       },
//     );
//   }
//
//   @override
//   Future<void> stopListening() async {
//     _isListening = false;
//     await _speech.stop();
//   }
// }
