import 'dart:io';

import 'package:griot/features/griot/domain/services/voice_input_service.dart';

class LocalWhisperVoiceInputService implements VoiceInputService {
  LocalWhisperVoiceInputService({
    this.audioPath = '/tmp/griot_voice_input.wav',
    this.modelPath,
  });

  final String audioPath;
  final String? modelPath;

  @override
  Future<String> listen() async {
    await _recordAudio();
    final rawOutput = await _transcribeAudio();
    return _extractTranscript(rawOutput);
  }

  Future<void> _recordAudio() async {
    final result = await Process.run('ffmpeg', [
      '-y',
      '-f',
      'avfoundation',
      '-i',
      ':0',
      '-t',
      '5',
      '-ar',
      '16000',
      '-ac',
      '1',
      audioPath,
    ]);

    if (result.exitCode != 0) {
      throw Exception('FFmpeg failed: ${result.stderr}');
    }
  }

  Future<String> _transcribeAudio() async {
    final resolvedModelPath =
        modelPath ??
        '${Platform.environment['HOME']}/whisper-models/ggml-base.en.bin';

    final result = await Process.run('whisper-cli', [
      '-m',
      resolvedModelPath,
      '-f',
      audioPath,
    ]);

    if (result.exitCode != 0) {
      throw Exception('Whisper failed: ${result.stderr}');
    }

    return '${result.stdout}\n${result.stderr}';
  }

  String _extractTranscript(String output) {
    final transcriptRegex = RegExp(
      r'\[\d{2}:\d{2}:\d{2}\.\d{3}\s+-->\s+\d{2}:\d{2}:\d{2}\.\d{3}\]\s+(.*)',
    );

    final matches = transcriptRegex.allMatches(output).toList();

    if (matches.isEmpty) {
      return '';
    }

    return matches
        .map((match) => match.group(1)?.trim() ?? '')
        .where((line) => line.isNotEmpty)
        .join(' ')
        .trim();
  }
}
