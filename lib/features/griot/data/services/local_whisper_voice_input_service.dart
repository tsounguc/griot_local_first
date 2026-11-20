import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:griot/features/griot/domain/services/voice_input_service.dart';

class LocalWhisperVoiceInputService implements VoiceInputService {
  LocalWhisperVoiceInputService({
    this.audioPath = '/tmp/griot_voice_input.wav',
    this.mic = 2,
    this.modelPath,
  });

  final String audioPath;
  final String? modelPath;
  final int mic;
  Process? _recordingProcess;

  @override
  Future<void> startListening() async {
    if (_recordingProcess != null) return;

    final file = File(audioPath);

    if (await file.exists()) {
      await file.delete();
    }

    debugPrint('GRIOT: Starting microphone recording');
    debugPrint('GRIOT: Microphone index: $mic');

    final process = await Process.start('ffmpeg', [
      '-y',
      '-f',
      'avfoundation',
      '-i',
      ':$mic',
      '-ar',
      '16000',
      '-ac',
      '1',
      audioPath,
    ], runInShell: false);

    _recordingProcess = process;

    debugPrint('GRIOT: FFmpeg PID: ${process.pid}');

    process.stderr.transform(systemEncoding.decoder).listen((output) {
      debugPrint('GRIOT FFmpeg: $output');
    });

    process.stdout.transform(systemEncoding.decoder).listen((output) {
      debugPrint('GRIOT FFmpeg stdout: $output');
    });
  }

  @override
  Future<String> stopListeningAndTranscribe() async {
    final process = _recordingProcess;

    if (process == null) {
      throw Exception('No active recording process.');
    }

    process.stdin.write('q');
    await process.stdin.close();
    await process.exitCode;

    _recordingProcess = null;

    final rawOutput = await _transcribeAudio();
    return _extractTranscript(rawOutput);
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
    ], runInShell: true);

    if (result.exitCode != 0) {
      throw Exception('Whisper failed: ${result.stderr}');
    }

    return '${result.stdout}\n${result.stderr}';
  }

  String _extractTranscript(String output) {
    final regex = RegExp(
      r'\[\d{2}:\d{2}:\d{2}\.\d{3}\s+-->\s+\d{2}:\d{2}:\d{2}\.\d{3}\]\s+(.*)',
    );

    return regex
        .allMatches(output)
        .map((m) => m.group(1)?.trim() ?? '')
        .where((line) => line.isNotEmpty)
        .join(' ')
        .trim();
  }
}
