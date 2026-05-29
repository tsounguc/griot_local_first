abstract class SpeechOutputService {
  Future<void> speak(String text);
  Future<void> stop();
}