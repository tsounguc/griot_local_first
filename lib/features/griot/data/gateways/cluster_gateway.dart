import 'dart:convert';

import 'package:http/http.dart' as http;

class ClusterGateway {
  ClusterGateway({required this.baseUrl});

  final String baseUrl;

  Future<String> routeTask({
    required String task,
    required String message,
  }) async {
    final uri = Uri.parse('$baseUrl/route');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'task': task, 'message': message}),
    );

    if (response.statusCode != 200) {
      throw Exception('Cluster request failed: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final workerResult = json['worker_result'] as Map<String, dynamic>;

    return workerResult['result'].toString();
  }
}
