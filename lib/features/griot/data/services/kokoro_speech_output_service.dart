import 'dart:convert';
import 'dart:io';

import 'package:griot/features/griot/domain/services/speech_output_service.dart';
import 'package:http/http.dart' as http;

// class KokoroSpeechOutputService implements SpeechOutputService {
//   KokoroSpeechOutputService({
//     this.serverUrl = 'http://127.0.0.1:8765/speak',
//     this.voice = 'af_heart',
//   });
//
//   final String serverUrl;
//   final String voice;
//
//   Process? _audioProcess;
//   Future<void> _speechQueue = Future.value();
//   int _counter = 0;
//
//   @override
//   Future<void> speak(String text) {
//     _speechQueue = _speechQueue.then((_) => _speakQueued(text));
//     return _speechQueue;
//   }
//
//   Future<void> _speakQueued(String text) async {
//     final sanitizedText = _sanitizeForSpeech(text);
//
//     if (sanitizedText.isEmpty) {
//       return;
//     }
//
//     final outputPath = '/tmp/griot_kokoro_response_${_counter++}.wav';
//
//     final response = await http.post(
//       Uri.parse(serverUrl),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'text': sanitizedText,
//         'output_path': outputPath,
//         'voice': voice,
//         'speed': 1.0,
//       }),
//     );
//
//     if (response.statusCode != 200) {
//       throw Exception('Kokoro server failed: ${response.body}');
//     }
//
//     _audioProcess = await Process.start('afplay', [
//       outputPath,
//     ], runInShell: true);
//
//     await _audioProcess?.exitCode;
//     _audioProcess = null;
//   }
//
//   @override
//   Future<void> stop() async {
//     _audioProcess?.kill();
//     _audioProcess = null;
//     _speechQueue = Future.value();
//   }
//
//   String _sanitizeForSpeech(String text) {
//     return text
//         .replaceAll(
//           RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true),
//           '',
//         )
//         .replaceAll(RegExp(r'[*_`#>\[\]{}]'), '')
//         .replaceAll(RegExp(r'\s+'), ' ')
//         .trim();
//   }
// }

class KokoroSpeechOutputService implements SpeechOutputService {
  KokoroSpeechOutputService({
    this.serverUrl = 'http://127.0.0.1:8765/speak',
    this.outputPath = '/tmp/griot_kokoro_response.wav',
    this.voice = 'af_heart',
  });

  final String serverUrl;
  final String outputPath;
  final String voice;

  Process? _audioProcess;

  @override
  Future<void> speak(String text) async {
    await stop();

    final response = await http.post(
      Uri.parse(serverUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': text,
        'output_path': outputPath,
        'voice': voice,
        'speed': 1.0,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Kokoro server failed: ${response.body}');
    }

    _audioProcess = await Process.start('afplay', [
      outputPath,
    ], runInShell: true);
  }

  @override
  Future<void> stop() async {
    _audioProcess?.kill();
    _audioProcess = null;
  }
}
