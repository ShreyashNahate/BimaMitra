import 'package:bimamitra/screens/dashboard_screen.dart';
import 'package:bimamitra/screens/admin_screen.dart';
import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../services/ai_service.dart';
import '../services/idle_timer_service.dart';
import '../widgets/ai_avatar.dart';

class LanguageScreen extends StatefulWidget {
  @override
  _LanguageScreenState createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen>
    with SingleTickerProviderStateMixin {
  final AIService _aiService = AIService();
  final IdleTimerService _idleTimer = IdleTimerService();
  final LanguageService _languageService = LanguageService();

  String? _selectedLanguage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    Future.delayed(Duration(milliseconds: 500), () {
      _aiService.speakText("welcome");
      _idleTimer.startTimer(_aiService);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void selectLanguage(String lang) {
    setState(() {
      _selectedLanguage = lang;
    });

    _languageService.setLanguage(lang);
    _aiService.setLanguage(lang);
    _idleTimer.resetTimer(_aiService);
  }

  void continueToOnboarding() {
    if (_selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a language first'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardScreen(aiService: _aiService),
      ),
    );
  }

  void navigateToAdmin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 40.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 48),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLanguageCard(
                            languageCode: 'hi',
                            languageName: 'हिंदी',
                            subtitle: 'Hindi',
                            flag: '🇮🇳',
                          ),
                          SizedBox(height: 16),
                          _buildLanguageCard(
                            languageCode: 'mr',
                            languageName: 'मराठी',
                            subtitle: 'Marathi',
                            flag: '🇮🇳',
                          ),
                          SizedBox(height: 16),
                          _buildLanguageCard(
                            languageCode: 'en',
                            languageName: 'English',
                            subtitle: 'English',
                            flag: '🇬🇧',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    _buildVoiceButton(),
                    SizedBox(height: 16),
                    _buildAdminButton(),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            AIAvatar(aiService: _aiService),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: Duration(milliseconds: 400),
                child: Text(
                  LanguageService.getText("choose_language"),
                  key: ValueKey(LanguageService().currentLanguage),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                LanguageService.getText("start_with_voice"),
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageCard({
    required String languageCode,
    required String languageName,
    required String subtitle,
    required String flag,
  }) {
    final bool isSelected = _selectedLanguage == languageCode;

    return GestureDetector(
      onTap: () => selectLanguage(languageCode),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Color(0xFF2563EB) : Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF2563EB).withOpacity(0.2),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Text(flag, style: TextStyle(fontSize: 28)),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                languageName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Color(0xFF2563EB) : Color(0xFF1E293B),
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.white, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceButton() {
    return AnimatedOpacity(
      opacity: _selectedLanguage != null ? 1.0 : 0.5,
      duration: Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: _selectedLanguage != null
              ? LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _selectedLanguage == null ? Color(0xFFE2E8F0) : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _selectedLanguage != null
              ? [
                  BoxShadow(
                    color: Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _selectedLanguage != null ? continueToOnboarding : null,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    LanguageService.getText("start_with_voice"),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF7C3AED).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: navigateToAdmin,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
