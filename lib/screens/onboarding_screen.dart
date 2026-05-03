import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../services/ai_service.dart';
import '../services/idle_timer_service.dart';
import '../widgets/ai_avatar.dart';
import 'recommendation_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class OnboardingScreen extends StatefulWidget {
  final AIService aiService;

  OnboardingScreen({required this.aiService});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final IdleTimerService _idleTimer = IdleTimerService();
  final PageController _pageController = PageController();

  // User data
  String occupation = "";
  int age = 0;
  double income = 0;
  bool hasDependents = false;
  String healthConditions = "";
  late stt.SpeechToText _speech;
  bool _speechEnabled = false;

  // Current question index (0-4)
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Voice/Text input
  bool _isListening = false;
  final TextEditingController _textController = TextEditingController();
  String _voiceTranscript = ""; // Store voice input temporarily

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  // Questions list
  final List<Map<String, dynamic>> _questions = [
    {
      'key': 'what_is_your_occupation',
      'type': 'text',
      'options': [
        'farmer',
        'shopkeeper',
        'daily_wage_worker',
        'government_employee',
        'private_employee',
        'self_employed',
        'homemaker',
        'student',
        'other',
      ],
    },
    {'key': 'what_is_your_age', 'type': 'number'},
    {'key': 'what_is_your_income', 'type': 'number'},
    {'key': 'do_you_have_dependents', 'type': 'boolean'},
    {'key': 'any_existing_health_conditions', 'type': 'text'},
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: 500), () {
      widget.aiService.speakText(LanguageService.getText(_questions[0]['key']));
      _idleTimer.startTimer(widget.aiService);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    await Permission.microphone.request();
    _speechEnabled = await _speech.initialize(
      onStatus: (status) {
        print("Speech status: $status");
      },
      onError: (error) {
        print("Speech error: $error");
      },
    );
  }

  void _handleVoiceInput() async {
    if (!_speechEnabled) {
      print("Speech not enabled");
      return;
    }

    if (!_isListening) {
      setState(() {
        _isListening = true;
      });

      await _speech.listen(
        onResult: (result) {
          String recognizedWords = result.recognizedWords;

          setState(() {
            _voiceTranscript = recognizedWords;
            _textController.text = recognizedWords;
          });

          _handleTextInput(recognizedWords);
        },
        listenMode: stt.ListenMode.confirmation,
      );
    } else {
      setState(() {
        _isListening = false;
      });

      await _speech.stop();
    }
  }

  void _handleTextInput(String value) {
    _idleTimer.resetTimer(widget.aiService);

    switch (_currentStep) {
      case 0:
        occupation = value;
        break;
      case 1:
        age = int.tryParse(value) ?? 0;
        break;
      case 2:
        income = double.tryParse(value) ?? 0;
        break;
      case 4:
        healthConditions = value;
        break;
    }
  }

  void _nextStep() {
    // Validate current step before proceeding
    if (!_validateCurrentStep()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageService.getText("please_answer_question")),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _textController.clear();
      _voiceTranscript = "";

      // Speak next question
      Future.delayed(Duration(milliseconds: 300), () {
        widget.aiService.speakText(
          LanguageService.getText(_questions[_currentStep]['key']),
        );
      });
    } else {
      _recommendPolicy();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return occupation.isNotEmpty;
      case 1:
        return age > 0 && age < 120;
      case 2:
        return income >= 0;
      case 3:
        return true; // Boolean always has a value
      case 4:
        return true; // Health conditions can be empty
      default:
        return true;
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );

      // Restore previous answer to TextField
      _restorePreviousAnswer();
    }
  }

  void _restorePreviousAnswer() {
    switch (_currentStep) {
      case 0:
        _textController.text = occupation;
        break;
      case 1:
        _textController.text = age > 0 ? age.toString() : '';
        break;
      case 2:
        _textController.text = income > 0 ? income.toString() : '';
        break;
      case 4:
        _textController.text = healthConditions;
        break;
    }
  }

  void _recommendPolicy() {
    _idleTimer.resetTimer(widget.aiService);

    String policy = "";
    String reason = "";
    String premium = "";

    if (income < 15000) {
      policy = LanguageService.getText("pradhan_mantri_suraksha_bima");
      premium = "₹12/year";
      reason =
          "Because your income is below ₹15,000, this low premium protection plan is best for you.";
    } else if (occupation.toLowerCase() == "farmer" ||
        occupation.toLowerCase() ==
            LanguageService.getText("farmer").toLowerCase()) {
      policy = "Pradhan Mantri Fasal Bima Yojana";
      premium = "₹500/year";
      reason =
          "Since you are a farmer, crop insurance will protect your harvest from loss.";
    } else if (age > 50) {
      policy = "Senior Health Protection Plan";
      premium = "₹5,000/year";
      reason =
          "Since your age is above 50, health coverage is important for financial safety.";
    } else {
      policy = LanguageService.getText("jeevan_jyoti_bima_yojana");
      premium = "₹436/year";
      reason =
          "Based on your profile, this balanced life protection plan suits your needs.";
    }

    widget.aiService.speakText(reason);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecommendationScreen(
          aiService: widget.aiService,
          policy: policy,
          reason: reason,
          premium: premium,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Progress Header
                _buildProgressHeader(),

                // Question Content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _totalSteps,
                    itemBuilder: (context, index) {
                      return _buildQuestionPage(_questions[index]);
                    },
                  ),
                ),

                // Navigation Buttons
                _buildNavigationButtons(),
              ],
            ),

            // Floating AI Avatar
            AIAvatar(aiService: widget.aiService),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: EdgeInsets.all(24),
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
            LanguageService.getText("tell_us_about_yourself"),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Text(
                "${LanguageService.getText('progress')} ${_currentStep + 1}/$_totalSteps",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(Map<String, dynamic> question) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),

          // Question Text
          Text(
            LanguageService.getText(question['key']),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),

          SizedBox(height: 32),

          // Voice Input Button (Compact)
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _handleVoiceInput,
                  child: ScaleTransition(
                    scale: _isListening
                        ? _pulseAnimation
                        : AlwaysStoppedAnimation(1.0),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? Color(0xFFEF4444)
                            : Color(0xFF2563EB),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_isListening
                                        ? Color(0xFFEF4444)
                                        : Color(0xFF2563EB))
                                    .withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: _isListening ? 10 : 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  _isListening
                      ? LanguageService.getText("listening")
                      : LanguageService.getText("tap_to_speak"),
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Options (if available) - Above text input
          if (question['type'] == 'text' && question['options'] != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LanguageService.getText("quick_select"),
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                _buildOptionsInput(question['options']),
                SizedBox(height: 24),
              ],
            ),

          // Boolean Input (Yes/No)
          if (question['type'] == 'boolean')
            Column(children: [_buildBooleanInput(), SizedBox(height: 24)]),

          // Always show text input field for verification and manual entry
          if (question['type'] != 'boolean')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LanguageService.getText("or_type_your_answer"),
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                _buildInputField(question),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInputField(Map<String, dynamic> question) {
    final String type = question['type'];

    if (type == 'number') {
      return _buildNumberInput();
    } else {
      return _buildTextInput();
    }
  }

  Widget _buildTextInput() {
    return TextField(
      controller: _textController,
      onChanged: _handleTextInput,
      decoration: InputDecoration(
        hintText: LanguageService.getText("type_here"),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(Icons.edit, color: Color(0xFF64748B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        contentPadding: EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildNumberInput() {
    return TextField(
      controller: _textController,
      onChanged: _handleTextInput,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: LanguageService.getText("type_here"),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(Icons.numbers, color: Color(0xFF64748B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        contentPadding: EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildBooleanInput() {
    return Row(
      children: [
        Expanded(
          child: _buildOptionButton(
            text: LanguageService.getText("yes"),
            isSelected: hasDependents == true,
            onTap: () {
              setState(() {
                hasDependents = true;
              });
              _idleTimer.resetTimer(widget.aiService);
            },
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildOptionButton(
            text: LanguageService.getText("no"),
            isSelected: hasDependents == false,
            onTap: () {
              setState(() {
                hasDependents = false;
              });
              _idleTimer.resetTimer(widget.aiService);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsInput(List<String> options) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final String displayText = LanguageService.getText(option);
        final bool isSelected =
            occupation.toLowerCase() == option.toLowerCase() ||
            occupation.toLowerCase() == displayText.toLowerCase();

        return GestureDetector(
          onTap: () {
            setState(() {
              occupation = option;
              _textController.text = displayText; // Update TextField
            });
            _idleTimer.resetTimer(widget.aiService);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFF2563EB) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Color(0xFF2563EB) : Color(0xFFE2E8F0),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Color(0xFF2563EB).withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              displayText,
              style: TextStyle(
                color: isSelected ? Colors.white : Color(0xFF1E293B),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOptionButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF2563EB) : Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF2563EB).withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color(0xFF2563EB),
                  side: BorderSide(color: Color(0xFF2563EB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  LanguageService.getText("previous"),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

          if (_currentStep > 0) SizedBox(width: 16),

          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _currentStep < _totalSteps - 1
                    ? LanguageService.getText("next")
                    : LanguageService.getText("continue"),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
