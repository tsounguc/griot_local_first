abstract class LLMGateway {
  Future<String> generateResponse({required String prompt});

  Stream<String> streamResponse({required String prompt});
}
