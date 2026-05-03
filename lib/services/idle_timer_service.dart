import 'dart:async';
import 'ai_service.dart';

class IdleTimerService {
  Timer? _timer;

  void startTimer(AIService aiService) {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: 10), () {
      // aiService.speakText("Help");
    });
  }

  void resetTimer(AIService aiService) {
    startTimer(aiService);
  }

  void stopTimer() {
    _timer?.cancel();
  }
}
