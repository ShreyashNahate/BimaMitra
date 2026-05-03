import 'dart:async';
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

String fixEncoding(String text) {
  return utf8.decode(latin1.encode(text));
}

class AIService {
  final FlutterTts _tts = FlutterTts();

  String currentLanguage = "en";

  int userAge = 0;
  double userIncome = 0;
  String userOccupation = "";

  AIService() {
    _initTTS();
  }

  Future<void> _initTTS() async {
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
  }

  void setLanguage(String lang) {
    currentLanguage = lang;
  }

  void storeSurveyData(int age, double income, String occupation) {
    userAge = age;
    userIncome = income;
    userOccupation = occupation;
  }

  bool _isSpeaking = false;
  Future<void> speakText(String text) async {
    if (_isSpeaking) return;
    _isSpeaking = true;
    try {
      await _tts.stop();

      // 1️⃣ Remove markdown formatting
      text = text.replaceAll(RegExp(r'\*\*'), '');
      text = text.replaceAll(RegExp(r'\n'), ' ');
      text = text.replaceAll(RegExp(r'\r'), ' ');
      text = text.replaceAll(RegExp(r'[_`~]'), '');

      // 2️⃣ Remove percentage and special symbols
      text = text.replaceAll('%', ' percent ');
      text = text.replaceAll(
        RegExp(r'[^\u0000-\u007F\u0900-\u097F\s.,!?]'),
        '',
      );

      // 3️⃣ Limit length (TTS crashes on long text)
      if (text.length > 350) {
        text = text.substring(0, 350);
      }

      // 4️⃣ Set language properly
      if (currentLanguage == "hi") {
        await _tts.setLanguage("hi-IN");
      } else if (currentLanguage == "mr") {
        await _tts.setLanguage("mr-IN");
      } else {
        await _tts.setLanguage("en-IN");
      }

      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);

      await _tts.speak(text);
    } catch (e) {
      print("TTS ERROR: $e");
    } finally {
      _isSpeaking = false;
    }
  }

  Future<String> askAI(String userMessage) async {
    const String GROQ_API_KEY = ""; // 🔑 Replace with your Groq API key

    const url = 'https://api.groq.com/openai/v1/chat/completions';

    try {
      final body = jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {
            'role': 'system',
            'content':
                '''You are BimaMitra, a rural insurance assistant for India.

Speak in ${currentLanguage == "hi"
                    ? "Hindi"
                    : currentLanguage == "mr"
                    ? "Marathi"
                    : "English"}.

- Give direct answer only
- Maximum 4-5 sentences
- Use simple words
- No greetings or introductions
- No "I am" statements
- Just answer the question
No markdown.
No symbols like %, *, **.''',
          },
          {'role': 'user', 'content': userMessage},
        ],
        'max_tokens': 512,
        'temperature': 0.4,
      });

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $GROQ_API_KEY',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      print("🤖 Using Groq API");
      print("📡 STATUS CODE: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final text = data['choices']?[0]?['message']?['content'] as String?;
        if (text != null && text.isNotEmpty) {
          print("✅ Success with Groq API");
          return text.trim();
        } else {
          print("❌ Empty response from Groq");
          return _getFallbackResponse(userMessage);
        }
      } else if (response.statusCode == 429) {
        print("⚠️ Rate limit hit");
        return _getFallbackResponse(userMessage);
      } else {
        print("❌ Error: ${response.statusCode} - ${response.body}");
        return _getFallbackResponse(userMessage);
      }
    } on TimeoutException {
      print("⏱️ Timeout with Groq API");
      return _getFallbackResponse(userMessage);
    } catch (e) {
      print("❌ Error with Groq API: $e");
      return _getFallbackResponse(userMessage);
    }
  }

  String _getFallbackResponse(String userMessage) {
    String question = userMessage.toLowerCase();

    // Simple rule-based responses for common questions
    if (question.contains('die') ||
        question.contains('death') ||
        question.contains('मर')) {
      if (currentLanguage == 'hi') {
        return 'आपकी मृत्यु पर आपके परिवार को बीमा राशि मिलेगी। यह आपके परिवार की मदद करेगा।';
      } else if (currentLanguage == 'mr') {
        return 'तुमच्या मृत्यूनंतर तुमच्या कुटुंबाला विमा रक्कम मिळेल। हे तुमच्या कुटुंबाला मदत करेल।';
      } else {
        return 'If you die, your family will receive the insurance amount. This will help your family financially.';
      }
    } else if (question.contains('premium') ||
        question.contains('pay') ||
        question.contains('प्रीमियम')) {
      if (currentLanguage == 'hi') {
        return 'प्रीमियम आपकी आय के आधार पर तय होता है। यह बहुत कम है। सरकार मदद करती है।';
      } else if (currentLanguage == 'mr') {
        return 'प्रीमियम तुमच्या उत्पन्नावर अवलंबून आहे। हे खूप कमी आहे। सरकार मदत करते।';
      } else {
        return 'Premium depends on your income. It is very affordable. Government provides subsidies.';
      }
    } else if (question.contains('accident') ||
        question.contains('injury') ||
        question.contains('एक्सीडेंट') ||
        question.contains('अपघात')) {
      if (currentLanguage == 'hi') {
        return 'दुर्घटना में चोट लगने पर बीमा कवर मिलेगा। इलाज का खर्च मिल जाएगा।';
      } else if (currentLanguage == 'mr') {
        return 'अपघातात दुखापत झाल्यास विमा कव्हर मिळेल। उपचाराचा खर्च मिळेल।';
      } else {
        return 'If you have an accident, insurance will cover medical expenses. You will get financial support.';
      }
    } else if (question.contains('claim') ||
        question.contains('क्लेम') ||
        question.contains('दावा')) {
      if (currentLanguage == 'hi') {
        return 'दावा करना आसान है। दस्तावेज जमा करें। पैसा जल्दी मिलेगा।';
      } else if (currentLanguage == 'mr') {
        return 'दावा करणे सोपे आहे। कागदपत्रे सादर करा। पैसे लवकर मिळतील।';
      } else {
        return 'Claiming is easy. Submit documents. Money will come quickly.';
      }
    } else if (question.contains('benefit') ||
        question.contains('फायदा') ||
        question.contains('लाभ')) {
      if (currentLanguage == 'hi') {
        return 'बीमा से परिवार सुरक्षित रहता है। आर्थिक मदद मिलती है। टेंशन कम होता है।';
      } else if (currentLanguage == 'mr') {
        return 'विम्यामुळे कुटुंब सुरक्षित राहते। आर्थिक मदत मिळते। चिंता कमी होते।';
      } else {
        return 'Insurance keeps family safe. Provides financial help. Reduces worry.';
      }
    } else {
      // Generic helpful response
      if (currentLanguage == 'hi') {
        return 'बीमा आपके परिवार की सुरक्षा के लिए है। कम कीमत में अच्छी सुरक्षा। और जानकारी चाहिए?';
      } else if (currentLanguage == 'mr') {
        return 'विमा तुमच्या कुटुंबाच्या सुरक्षेसाठी आहे। कमी किंमतीत चांगली सुरक्षा। अधिक माहिती हवी आहे का?';
      } else {
        return 'Insurance is for your family protection. Good coverage at low cost. Need more information?';
      }
    }
  }

  Future<void> chatWithAI(String userMessage) async {
    String aiReply = await askAI(userMessage);
    await speakText(aiReply);
  }
}
