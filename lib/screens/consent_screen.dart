import 'package:flutter/material.dart';
import 'package:bimamitra/services/language_service.dart';
import 'package:bimamitra/services/ai_service.dart';
import 'package:bimamitra/widgets/ai_avatar.dart';
import 'package:bimamitra/screens/kyc_screen.dart';

class ConsentScreen extends StatefulWidget {
  final AIService aiService;
  final String selectedPolicy;
  final String premium;

  ConsentScreen({
    required this.aiService,
    required this.selectedPolicy,
    required this.premium,
  });

  @override
  _ConsentScreenState createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  bool _hasRecorded = false;
  String _recordingStatus = "";
  int _recordingDuration = 0;
  bool _isProcessing = false;

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation1;
  late Animation<double> _waveAnimation2;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _waveAnimation1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _waveAnimation2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Welcome message
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        widget.aiService.speakText(
          LanguageService.getText("please_confirm_consent") ??
              "Please confirm your consent",
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isProcessing) return;

    if (_isRecording) {
      // Stop recording
      await _stopRecording();
    } else {
      // Start recording
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      setState(() {
        _isProcessing = true;
      });

      // Start animation
      _animationController.repeat();

      setState(() {
        _isRecording = true;
        _hasRecorded = false;
        _recordingStatus =
            LanguageService.getText("recording") ?? "Recording...";
        _recordingDuration = 0;
        _isProcessing = false;
      });

      // AI feedback
      widget.aiService.speakText(
        LanguageService.getText("record_voice_approval") ??
            "Recording your consent",
      );

      // Start duration counter
      _startDurationCounter();

      // Auto-stop after 15 seconds
      Future.delayed(Duration(seconds: 15), () {
        if (mounted && _isRecording) {
          _stopRecording();
        }
      });
    } catch (e) {
      print('Error starting recording: $e');
      setState(() {
        _isProcessing = false;
      });
      _showError('Failed to start recording');
    }
  }

  void _startDurationCounter() {
    Future.doWhile(() async {
      if (!_isRecording || !mounted) return false;

      await Future.delayed(Duration(seconds: 1));
      if (mounted && _isRecording) {
        setState(() {
          _recordingDuration++;
        });
      }
      return _isRecording;
    });
  }

  Future<void> _stopRecording() async {
    try {
      setState(() {
        _isProcessing = true;
      });

      // Stop animation
      _animationController.stop();
      _animationController.reset();

      setState(() {
        _isRecording = false;
        _hasRecorded = true;
        _recordingStatus =
            LanguageService.getText("recorded") ??
            "Consent recorded successfully";
        _isProcessing = false;
      });

      // AI feedback
      widget.aiService.speakText("Consent recorded successfully");

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Consent recorded successfully'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error stopping recording: $e');
      setState(() {
        _isProcessing = false;
      });
      _showError('Failed to stop recording');
    }
  }

  void _reRecord() {
    setState(() {
      _hasRecorded = false;
      _recordingStatus = "";
      _recordingDuration = 0;
    });

    widget.aiService.speakText("Ready to record again");
  }

  void _submitConsent() {
    if (!_hasRecorded) {
      _showError('Please record your consent first');
      widget.aiService.speakText("Please record your consent first");
      return;
    }

    // Navigate to KYC screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KYCVerificationScreen(
          aiService: widget.aiService,
          selectedPolicy: widget.selectedPolicy,
          premium: widget.premium,
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
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
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 24,
                      bottom: 100, // Space for AI avatar
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPolicyDetailsCard(),
                        SizedBox(height: 32),
                        _buildRecordingSection(),
                        SizedBox(height: 32),
                        _buildInstructions(),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                _buildSubmitButton(),
              ],
            ),
            AIAvatar(aiService: widget.aiService),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LanguageService.getText("please_confirm_consent") ??
                      "Consent Required",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  LanguageService.getText("record_voice_approval") ??
                      "Record your voice approval",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyDetailsCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.shield, color: Color(0xFF2563EB), size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.selectedPolicy,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      LanguageService.getText("premium") ?? "Premium",
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Text(
                "${widget.premium}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(color: Color(0xFFE2E8F0)),
          SizedBox(height: 16),
          _buildPolicyDetail(
            LanguageService.getText("coverage") ?? "Coverage",
            LanguageService.getText("accidental_death_disability") ??
                "Accidental Death & Disability",
          ),
          SizedBox(height: 12),
          _buildPolicyDetail(
            LanguageService.getText("exclusions") ?? "Exclusions",
            LanguageService.getText("self_inflicted_injuries") ??
                "Self-inflicted injuries, war, nuclear risks",
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 14, color: Color(0xFF1E293B), height: 1.4),
        ),
      ],
    );
  }

  Widget _buildRecordingSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _isRecording
                ? "Recording in progress..."
                : _hasRecorded
                ? "Recording completed"
                : "Tap to start recording",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 24),

          // Recording button with waves
          _buildRecordingButton(),

          SizedBox(height: 24),

          // Status and duration
          _buildRecordingStatus(),

          // Re-record button
          if (_hasRecorded) ...[
            SizedBox(height: 16),
            TextButton.icon(
              onPressed: _reRecord,
              icon: Icon(Icons.refresh, size: 20),
              label: Text('Record Again'),
              style: TextButton.styleFrom(foregroundColor: Color(0xFF2563EB)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordingButton() {
    return GestureDetector(
      onTap: _isProcessing ? null : _toggleRecording,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated waves
          if (_isRecording) ...[
            AnimatedBuilder(
              animation: _waveAnimation1,
              builder: (context, child) {
                return Container(
                  width: 180 + (80 * _waveAnimation1.value),
                  height: 180 + (80 * _waveAnimation1.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color(
                        0xFFEF4444,
                      ).withOpacity(0.4 - (0.4 * _waveAnimation1.value)),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _waveAnimation2,
              builder: (context, child) {
                return Container(
                  width: 180 + (80 * _waveAnimation2.value),
                  height: 180 + (80 * _waveAnimation2.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color(
                        0xFFEF4444,
                      ).withOpacity(0.3 - (0.3 * _waveAnimation2.value)),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
          ],

          // Main button
          AnimatedBuilder(
            animation: _isRecording
                ? _pulseAnimation
                : AlwaysStoppedAnimation(1.0),
            builder: (context, child) {
              return Transform.scale(
                scale: _isRecording ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isRecording
                          ? [Color(0xFFEF4444), Color(0xFFDC2626)]
                          : _hasRecorded
                          ? [Color(0xFF10B981), Color(0xFF059669)]
                          : [Color(0xFF2563EB), Color(0xFF1E40AF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_isRecording
                                    ? Color(0xFFEF4444)
                                    : _hasRecorded
                                    ? Color(0xFF10B981)
                                    : Color(0xFF2563EB))
                                .withOpacity(0.4),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: _isProcessing
                      ? Center(
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 3,
                            ),
                          ),
                        )
                      : Icon(
                          _hasRecorded
                              ? Icons.check_circle
                              : _isRecording
                              ? Icons.stop
                              : Icons.mic,
                          size: 60,
                          color: Colors.white,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingStatus() {
    return Column(
      children: [
        if (_isRecording || _hasRecorded)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: (_isRecording ? Color(0xFFEF4444) : Color(0xFF10B981))
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isRecording)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                if (_isRecording) SizedBox(width: 8),
                Text(
                  _isRecording ? "${_recordingDuration}s" : "✓ Recorded",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isRecording ? Color(0xFFEF4444) : Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        if (_isRecording) ...[
          SizedBox(height: 12),
          Text(
            "Speak clearly into the microphone",
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2563EB).withOpacity(0.05),
            Color(0xFF1E40AF).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF2563EB).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.info_outline, size: 20, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text(
                LanguageService.getText("please_say") ?? "Please say:",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "I, [Your Name], agree to purchase this policy with the stated terms and conditions.",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13, // slightly reduce size
                    height: 1.3, // tighter line spacing
                    color: Color(0xFF1E293B),
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.mic, size: 16, color: Color(0xFF64748B)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Tap the microphone button and speak clearly",
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasRecorded)
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: Color(0xFF10B981),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Consent recorded successfully",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _hasRecorded && !_isProcessing ? _submitConsent : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2563EB),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Color(0xFFE2E8F0),
                disabledForegroundColor: Color(0xFF94A3B8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    LanguageService.getText("submit_consent") ??
                        "Submit & Continue",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
