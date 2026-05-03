import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../services/ai_service.dart';

class AIAvatar extends StatefulWidget {
  final AIService aiService;

  const AIAvatar({Key? key, required this.aiService}) : super(key: key);

  @override
  State<AIAvatar> createState() => _AIAvatarState();
}

class _AIAvatarState extends State<AIAvatar> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;

  Future<void> _startListening() async {
    bool available = await _speech.initialize();

    if (available) {
      setState(() => _isListening = true);

      _speech.listen(
        listenFor: Duration(seconds: 10),
        onResult: (result) async {
          if (result.finalResult) {
            setState(() => _isListening = false);

            String userSpeech = result.recognizedWords;

            if (userSpeech.isNotEmpty) {
              await widget.aiService.chatWithAI(userSpeech);
            }
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: GestureDetector(
        onTap: _startListening,
        child: CircleAvatar(
          radius: 30,
          backgroundColor: _isListening ? Colors.red : Colors.blue,
          child: Icon(Icons.mic, color: Colors.white),
        ),
      ),
    );
  }
}
