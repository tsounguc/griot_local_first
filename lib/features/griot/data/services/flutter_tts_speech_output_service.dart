import 'package:flutter_tts/flutter_tts.dart';

import '../../domain/services/speech_output_service.dart';

class FlutterTTSSpeechOutputService implements SpeechOutputService {
  final FlutterTts _tts = FlutterTts();

  FlutterTTSSpeechOutputService() {
    _configure();
  }

  Future<void> _configure() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
  }

  @override
  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}