import 'package:flutter/material.dart';
import 'package:bimamitra/services/ai_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class AIHelpScreen extends StatefulWidget {
  final AIService aiService;

  AIHelpScreen({required this.aiService});

  @override
  _AIHelpScreenState createState() => _AIHelpScreenState();
}

class _AIHelpScreenState extends State<AIHelpScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // ── Speech to Text ──────────────────────────
  late stt.SpeechToText _speech;
  bool _speechAvailable = false;

  // ── TTS stop control ─────────────────────────
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _isListening = false;
  String _selectedLanguage = "en";

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, String>> _suggestedQuestions = [
    {
      'en': 'What happens if I die? Will my family get money?',
      'hi': 'अगर मैं मर जाऊं तो क्या होगा? क्या मेरे परिवार को पैसे मिलेंगे?',
      'mr': 'मी मेला तर काय होईल? माझ्या कुटुंबाला पैसे मिळतील का?',
    },
    {
      'en': 'How much premium do I need to pay?',
      'hi': 'मुझे कितना प्रीमियम देना होगा?',
      'mr': 'मला किती प्रीमियम भरावा लागेल?',
    },
    {
      'en': 'What if I have an accident?',
      'hi': 'अगर मेरा एक्सीडेंट हो जाए तो क्या होगा?',
      'mr': 'माझा अपघात झाला तर काय होईल?',
    },
  ];

  @override
  void initState() {
    super.initState();

    _selectedLanguage = widget.aiService.currentLanguage;

    // Init speech-to-text
    _speech = stt.SpeechToText();
    _initSpeech();

    // TTS speaking state listeners
    _tts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });

    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: 500), () {
      _addMessage(_getWelcomeMessage(), isUser: false);
    });
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) {
        debugPrint('STT error: $error');
        if (mounted) setState(() => _isListening = false);
      },
      onStatus: (status) {
        debugPrint('STT status: $status');
        // When STT stops listening on its own, update state
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  String _getWelcomeMessage() {
    switch (_selectedLanguage) {
      case 'hi':
        return 'नमस्ते! मैं आपकी मदद के लिए यहां हूं। बीमा के बारे में कुछ भी पूछें।';
      case 'mr':
        return 'नमस्कार! मी तुमची मदत करण्यासाठी येथे आहे. विम्याबद्दल काहीही विचारा.';
      default:
        return 'Hello! I am here to help you. Ask me anything about insurance.';
    }
  }

  void _changeLanguage(String lang) {
    setState(() {
      _selectedLanguage = lang;
      widget.aiService.setLanguage(lang);
    });

    String announcement = '';
    switch (lang) {
      case 'hi':
        announcement = 'भाषा हिंदी में बदल गई';
        break;
      case 'mr':
        announcement = 'भाषा मराठीत बदलली';
        break;
      default:
        announcement = 'Language changed to English';
    }

    widget.aiService.speakText(announcement);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(announcement),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _addMessage(String text, {required bool isUser}) {
    setState(() {
      _messages.add({
        'text': text,
        'isUser': isUser,
        'timestamp': DateTime.now(),
      });
    });
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    _addMessage(message, isUser: true);
    _messageController.clear();

    setState(() => _isTyping = true);

    String aiResponse = await widget.aiService.askAI(message);

    setState(() => _isTyping = false);

    _addMessage(aiResponse, isUser: false);

    // Speak using our local TTS so we can track _isSpeaking
    await _speakResponse(aiResponse);
  }

  // ── Speak using local TTS (so stop button works) ──
  Future<void> _speakResponse(String text) async {
    // Clean text same way AIService does
    text = text.replaceAll(RegExp(r'\*\*'), '');
    text = text.replaceAll(RegExp(r'\n'), ' ');
    text = text.replaceAll(RegExp(r'[_`~]'), '');
    text = text.replaceAll('%', ' percent ');
    if (text.length > 350) text = text.substring(0, 350);

    final lang = _selectedLanguage == 'hi'
        ? 'hi-IN'
        : _selectedLanguage == 'mr'
        ? 'mr-IN'
        : 'en-IN';

    await _tts.setLanguage(lang);
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.speak(text);
  }

  // ── Stop TTS ─────────────────────────────────
  Future<void> _stopSpeaking() async {
    await _tts.stop();
    setState(() => _isSpeaking = false);
  }

  // ── Real Voice Input ──────────────────────────
  Future<void> _handleVoiceInput() async {
    // If already listening → stop
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Microphone not available on this device.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Stop TTS before listening
    await _tts.stop();

    setState(() => _isListening = true);

    // Locale based on selected language
    final localeId = _selectedLanguage == 'hi'
        ? 'hi_IN'
        : _selectedLanguage == 'mr'
        ? 'mr_IN'
        : 'en_IN';

    _speech.listen(
      localeId: localeId,
      listenFor: Duration(seconds: 30),
      pauseFor: Duration(seconds: 3),
      onResult: (result) {
        // Update text field as user speaks (live feedback)
        if (mounted) {
          setState(() {
            _messageController.text = result.recognizedWords;
          });
        }

        // When final result → send automatically
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          setState(() => _isListening = false);
          _sendMessage(result.recognizedWords.trim());
          _messageController.clear();
        }
      },
    );
  }

  void _askSuggestedQuestion(int index) {
    String question = _suggestedQuestions[index][_selectedLanguage] ?? '';
    _sendMessage(question);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _selectedLanguage == 'hi'
              ? 'AI सहायता'
              : _selectedLanguage == 'mr'
              ? 'AI मदत'
              : 'AI Help',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF2563EB),
        elevation: 0,
        actions: [
          // ── Stop Speaking Button ─────────────
          if (_isSpeaking)
            IconButton(
              icon: Icon(Icons.stop_circle, color: Colors.redAccent, size: 28),
              tooltip: 'Stop speaking',
              onPressed: _stopSpeaking,
            ),

          // Language Selector
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              icon: Icon(Icons.language, color: Colors.white),
              onSelected: _changeLanguage,
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'en',
                  child: Row(
                    children: [
                      Icon(
                        Icons.check,
                        color: _selectedLanguage == 'en'
                            ? Color(0xFF2563EB)
                            : Colors.transparent,
                      ),
                      SizedBox(width: 8),
                      Text('English'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'hi',
                  child: Row(
                    children: [
                      Icon(
                        Icons.check,
                        color: _selectedLanguage == 'hi'
                            ? Color(0xFF2563EB)
                            : Colors.transparent,
                      ),
                      SizedBox(width: 8),
                      Text('हिंदी (Hindi)'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'mr',
                  child: Row(
                    children: [
                      Icon(
                        Icons.check,
                        color: _selectedLanguage == 'mr'
                            ? Color(0xFF2563EB)
                            : Colors.transparent,
                      ),
                      SizedBox(width: 8),
                      Text('मराठी (Marathi)'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_messages.length <= 1) _buildSuggestedQuestions(),

          // Listening banner
          AnimatedSize(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: _isListening ? _buildListeningBanner() : SizedBox.shrink(),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _buildMessageBubble(_messages[index]);
                }
                if (_isTyping && index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return SizedBox.shrink();
              },
            ),
          ),

          _buildInputArea(),
        ],
      ),
    );
  }

  // ── Listening banner shown while mic is active ──
  Widget _buildListeningBanner() {
    final hint = _selectedLanguage == 'hi'
        ? 'सुन रहा हूं... बोलिए'
        : _selectedLanguage == 'mr'
        ? 'ऐकतोय... बोला'
        : 'Listening... speak now';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: Color(0xFFF1F5F9), // ← neutral grey instead of red
      child: Row(
        children: [
          Icon(Icons.mic, color: Color(0xFFEF4444), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _messageController.text.isNotEmpty
                  ? _messageController.text
                  : hint,
              style: TextStyle(
                color: Color(0xFF475569), // ← neutral text
                fontSize: 14,
                fontStyle: _messageController.text.isEmpty
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              await _speech.stop();
              setState(() => _isListening = false);
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedQuestions() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedLanguage == 'hi'
                ? 'सुझाए गए सवाल'
                : _selectedLanguage == 'mr'
                ? 'सूचित प्रश्न'
                : 'Suggested Questions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_suggestedQuestions.length, (index) {
              return GestureDetector(
                onTap: () => _askSuggestedQuestion(index),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.help_outline,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _suggestedQuestions[index][_selectedLanguage] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    bool isUser = message['isUser'];
    String text = message['text'];

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Color(0xFF2563EB) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 16 : 4),
                  topRight: Radius.circular(isUser ? 4 : 16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.white : Color(0xFF1E293B),
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: _TypingDots(), // ← separate stateful widget, no broken tween
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600),
      builder: (context, double value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Color(
              0xFF64748B,
            ).withOpacity(0.3 + (value * 0.7 * ((index + 1) % 3))),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Mic button
            GestureDetector(
              onTap: _handleVoiceInput,
              child: ScaleTransition(
                scale: _isListening
                    ? _pulseAnimation
                    : AlwaysStoppedAnimation(1.0),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isListening ? Color(0xFFEF4444) : Color(0xFF2563EB),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_isListening
                                    ? Color(0xFFEF4444)
                                    : Color(0xFF2563EB))
                                .withOpacity(0.3),
                        blurRadius: _isListening ? 12 : 8,
                        spreadRadius: _isListening ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),

            SizedBox(width: 12),

            // Text field
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: _isListening
                      ? (_selectedLanguage == 'hi'
                            ? 'सुन रहा हूं...'
                            : _selectedLanguage == 'mr'
                            ? 'ऐकतोय...'
                            : 'Listening...')
                      : (_selectedLanguage == 'hi'
                            ? 'अपना सवाल टाइप करें...'
                            : _selectedLanguage == 'mr'
                            ? 'तुमचा प्रश्न टाइप करा...'
                            : 'Type your question...'),
                  hintStyle: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
              ),
            ),

            SizedBox(width: 12),

            // Send button
            GestureDetector(
              onTap: () => _sendMessage(_messageController.text),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated typing dots — safe, self-contained, no assertion errors
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final step = (_ctrl.value * 3).floor().clamp(0, 2);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF2563EB).withOpacity(i == step ? 1.0 : 0.25),
              ),
            );
          }),
        );
      },
    );
  }
}
