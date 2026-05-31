import 'dart:convert';

import 'package:griot/features/griot/domain/gateways/llm_gateway.dart';
import 'package:http/http.dart' as http;

class LocalOllamaGateWay implements LLMGateway {
  @override
  Future<String> generateResponse({required String prompt}) async {
    final String baseUrl = 'http://127.0.0.1:11434/api/generate';
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'qwen3:8b',
          'prompt': prompt,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['response'];
      }
      return 'Griot Error: ${response.statusCode}';
    } catch (e) {
      return 'Offline link failed. Verify Ollama is running.';
    }
  }

  @override
  Stream<String> streamResponse({required String prompt}) async* {
    final request = http.Request(
      'POST',
      Uri.parse('http://127.0.0.1:11434/api/generate'),
    );

    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'model': 'qwen3:8b',
      'prompt': prompt,
      'stream': true,
    });

    final streamedResponse = await request.send();

    if (streamedResponse.statusCode != 200) {
      throw Exception('Ollama stream failed: ${streamedResponse.statusCode}');
    }

    await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
      for (final line in const LineSplitter().convert(chunk)) {
        if (line.trim().isEmpty) continue;

        final json = jsonDecode(line);
        final token = json['response'] as String? ?? '';

        if (token.isNotEmpty) {
          yield token;
        }
      }
    }
  }
}
