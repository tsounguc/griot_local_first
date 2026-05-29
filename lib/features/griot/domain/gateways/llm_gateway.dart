

abstract class LLMGateway {
  Future<String> generateResponse({
    required String prompt,
  });
}
