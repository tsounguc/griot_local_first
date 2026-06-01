abstract class LLMGateway {
  Future<String> generateResponse({
    required String prompt,
    required String model,
  });

  Stream<String> streamResponse({
    required String prompt,
    required String model,
  });
}
