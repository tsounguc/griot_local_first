
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
          'model': 'qwen3:1.7b',
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

}