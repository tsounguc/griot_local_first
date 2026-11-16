import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class LocalServiceManager {
  static const String ollamaUrl = 'http://127.0.0.1:11434';
  static const String kokoroUrl = 'http://127.0.0.1:8765';

  Process? _ollamaProcess;
  Process? _kokoroProcess;

  Future<void> startOllama() async {
    if (await isOllamaRunning()) {
      debugPrint('Ollama is already running.');
      return;
    }

    debugPrint('Starting Ollama...');

    // Process.start() ask the operating system to launch a separate process.
    // Ollama does not run inside Dart's execution environment.

    // detachedWithStdio lets the process continue independently.
    // This is convenient initially, but we'll need a deliberate shutdown strategy later.
    _ollamaProcess = await Process.start('ollama', [
      'serve',
    ], mode: ProcessStartMode.detachedWithStdio);

    // A successful process launch does not guarantee
    // that the HTTP server is ready yet.
    for (int attempt = 0; attempt < 30; attempt++) {
      if (await isOllamaRunning()) {
        debugPrint('Ollama is ready.');
        return;
      }

      await Future.delayed(const Duration(seconds: 1));
    }

    throw StateError('Ollama did not become ready within the startup period.');
  }

  // Instead of activating the environment through a shell, Dart can launch its Python interpreter directly:
  // Process.start(
  // '/Users/<your-username>/griot-kokoro-env/bin/python',
  // ['kokoro_server.py'],
  // workingDirectory: '/Users/<your-username>/griot-tools/kokoro',
  // );
  //
  //
  // We'll use Platform.environment['HOME'] to construct those paths rather than hardcoding your username.

  // GRIOT is becoming a process supervisor.
  //
  // It's beginning to manage a collection of independent programs that
  // cooperate to provide a single application experience. This is a small-scale
  // version of what operating systems and distributed orchestration systems do.
  Future<void> startKokoro() async {
    if (await isKokoroRunning()) {
      print('Kokoro is already running.');
      return;
    }

    final home = Platform.environment['HOME'];

    if (home == null) {
      throw StateError('Cannot determine the user home directory.');
    }

    final pythonPath = '$home/griot-kokoro-env/bin/python';
    final serverDirectory = '$home/griot-tools/kokoro';
    final serverPath = '$serverDirectory/kokoro_server.py';

    if (!File(pythonPath).existsSync()) {
      throw StateError('Kokoro Python interpreter not found: $pythonPath');
    }

    if (!File(serverPath).existsSync()) {
      throw StateError('Kokoro server script not found: $serverPath');
    }

    print('Starting Kokoro...');

    _kokoroProcess = await Process.start(
      pythonPath,
      [serverPath],
      workingDirectory: serverDirectory,
      mode: ProcessStartMode.normal,
    );

    // Consume both streams to avoid filling OS pipe buffers.
    _kokoroProcess!.stdout
        .transform(systemEncoding.decoder)
        .listen((message) => print('Kokoro: $message'));

    _kokoroProcess!.stderr
        .transform(systemEncoding.decoder)
        .listen((message) => print('Kokoro error: $message'));

    // Kokoro can take longer to initialize because it loads
    // a neural network before the HTTP server becomes ready.
    for (int attempt = 0; attempt < 90; attempt++) {
      if (await isKokoroRunning()) {
        print('Kokoro is ready.');
        return;
      }

      await Future.delayed(const Duration(seconds: 1));
    }

    throw StateError('Kokoro did not become ready within the startup period.');
  }

  Future<bool> isOllamaRunning() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);

    try {
      final request = await client.getUrl(Uri.parse(ollamaUrl));
      final response = await request.close();
      await response.drain<void>();

      return response.statusCode == HttpStatus.ok;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  Future<bool> isKokoroRunning() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);

    try {
      final request = await client.getUrl(Uri.parse('$kokoroUrl/openapi.json'));

      final response = await request.close();
      await response.drain<void>();

      return response.statusCode == HttpStatus.ok;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> stopKokoro() async {
    final process = _kokoroProcess;

    if (process == null) {
      debugPrint('Kokoro was not started by this manager.');
      return;
    }

    debugPrint('Stopping Kokoro (PID: ${process.pid})...');

    final exited = process.exitCode;
    final signalSent = process.kill(ProcessSignal.sigterm);

    if (!signalSent) {
      debugPrint('Kokoro process was not signaled.');
      return;
    }

    try {
      final exitCode = await exited.timeout(const Duration(seconds: 5));

      debugPrint('Kokoro exited with code $exitCode.');

      if (identical(_kokoroProcess, process)) {
        _kokoroProcess = null;
      }
    } on TimeoutException {
      debugPrint('Kokoro did not exit within 5 seconds.');
      // Keep the reference because termination is unconfirmed.
    }
  }
}
