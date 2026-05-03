import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:bimamitra/services/ai_service.dart';
import 'package:bimamitra/services/language_service.dart';
import 'package:bimamitra/widgets/ai_avatar.dart';

// Claim step enum
enum ClaimStep { selectReason, uploadPhoto, review, success }

class ClaimScreen extends StatefulWidget {
  final AIService aiService;
  const ClaimScreen({required this.aiService});

  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen>
    with SingleTickerProviderStateMixin {
  ClaimStep _currentStep = ClaimStep.selectReason;

  // Claim data
  String? _selectedReason;
  String? _selectedPolicy;
  File? _uploadedPhoto;
  bool _isSubmitting = false;
  String _claimReferenceNumber = "";

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _claimReasons = [
    {
      'id': 'accident',
      'label': 'Accident',
      'icon': Icons.car_crash,
      'color': Color(0xFFEF4444),
      'description': 'Road accident, fall, or physical injury',
    },
    {
      'id': 'hospitalization',
      'label': 'Hospitalization',
      'icon': Icons.local_hospital,
      'color': Color(0xFF2563EB),
      'description': 'Admitted to hospital for treatment',
    },
    {
      'id': 'death',
      'label': 'Death Claim',
      'icon': Icons.sentiment_very_dissatisfied,
      'color': Color(0xFF64748B),
      'description': 'Filing on behalf of a deceased member',
    },
    {
      'id': 'disability',
      'label': 'Disability',
      'icon': Icons.accessible,
      'color': Color(0xFF7C3AED),
      'description': 'Permanent or partial disability due to injury',
    },
    {
      'id': 'critical_illness',
      'label': 'Critical Illness',
      'icon': Icons.monitor_heart,
      'color': Color(0xFFF59E0B),
      'description': 'Diagnosed with a covered critical illness',
    },
  ];

  final List<String> _mockPolicies = [
    'Pradhan Mantri Suraksha Bima (PM-SBY)',
    'Pradhan Mantri Jeevan Jyoti Bima (PMJJBY)',
    'Pradhan Mantri Fasal Bima Yojana',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    Future.delayed(Duration(milliseconds: 400), () {
      widget.aiService.speakText(
        "Let's file your claim. Please select the reason.",
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ─── Step navigation ──────────────────────────────────────────────

  void _goToStep(ClaimStep step) {
    _animationController.reset();
    setState(() => _currentStep = step);
    _animationController.forward();
  }

  void _nextFromReason() {
    if (_selectedReason == null || _selectedPolicy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a reason and policy'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    widget.aiService.speakText("Now upload a supporting photo or document.");
    _goToStep(ClaimStep.uploadPhoto);
  }

  void _nextFromUpload() {
    // Photo is optional — user can skip
    widget.aiService.speakText("Please review your claim before submitting.");
    _goToStep(ClaimStep.review);
  }

  Future<void> _submitClaim() async {
    setState(() => _isSubmitting = true);

    // Simulate network call (replace with real API/Firebase later)
    await Future.delayed(Duration(seconds: 2));

    // Generate mock claim reference
    final now = DateTime.now();
    _claimReferenceNumber =
        "CLM${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.millisecond}";

    setState(() => _isSubmitting = false);

    widget.aiService.speakText(
      "Your claim has been submitted successfully. Reference number: $_claimReferenceNumber",
    );
    _goToStep(ClaimStep.success);
  }

  // ─── Photo picker ─────────────────────────────────────────────────

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1200,
      );
      if (file != null) {
        setState(() => _uploadedPhoto = File(file.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not pick image: $e'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Add Supporting Document",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 20),
              _buildPhotoOption(
                icon: Icons.camera_alt,
                label: "Take Photo",
                color: Color(0xFF2563EB),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              SizedBox(height: 12),
              _buildPhotoOption(
                icon: Icons.photo_library,
                label: "Choose from Gallery",
                color: Color(0xFF7C3AED),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              SizedBox(height: 12),
              _buildPhotoOption(
                icon: Icons.skip_next,
                label: "Skip for now",
                color: Color(0xFF64748B),
                onTap: () {
                  Navigator.pop(context);
                  _nextFromUpload();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────

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
                if (_currentStep != ClaimStep.success) _buildStepIndicator(),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildCurrentStep(),
                  ),
                ),
              ],
            ),
            AIAvatar(aiService: widget.aiService),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titles = {
      ClaimStep.selectReason: "File a Claim",
      ClaimStep.uploadPhoto: "Upload Document",
      ClaimStep.review: "Review Claim",
      ClaimStep.success: "Claim Submitted!",
    };

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep != ClaimStep.success)
            GestureDetector(
              onTap: () {
                if (_currentStep == ClaimStep.selectReason) {
                  Navigator.pop(context);
                } else if (_currentStep == ClaimStep.uploadPhoto) {
                  _goToStep(ClaimStep.selectReason);
                } else if (_currentStep == ClaimStep.review) {
                  _goToStep(ClaimStep.uploadPhoto);
                }
              },
              child: Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
            ),
          if (_currentStep != ClaimStep.success) SizedBox(width: 16),
          Expanded(
            child: Text(
              titles[_currentStep] ?? "File a Claim",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = [
      ClaimStep.selectReason,
      ClaimStep.uploadPhoto,
      ClaimStep.review,
    ];
    final labels = ["Reason", "Document", "Review"];
    final currentIndex = steps.indexOf(_currentStep).clamp(0, 2);

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final lineIndex = i ~/ 2;
            final isCompleted = currentIndex > lineIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted ? Color(0xFF2563EB) : Color(0xFFE2E8F0),
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isCompleted = currentIndex > stepIndex;
          final isActive = currentIndex == stepIndex;
          return Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? Color(0xFF2563EB)
                      : isActive
                      ? Color(0xFF2563EB)
                      : Color(0xFFE2E8F0),
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          "${stepIndex + 1}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.white : Color(0xFF94A3B8),
                          ),
                        ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                labels[stepIndex],
                style: TextStyle(
                  fontSize: 10,
                  color: isActive || isCompleted
                      ? Color(0xFF2563EB)
                      : Color(0xFF94A3B8),
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case ClaimStep.selectReason:
        return _buildSelectReasonStep();
      case ClaimStep.uploadPhoto:
        return _buildUploadPhotoStep();
      case ClaimStep.review:
        return _buildReviewStep();
      case ClaimStep.success:
        return _buildSuccessStep();
    }
  }

  // ─── Step 1: Select Reason ────────────────────────────────────────

  Widget _buildSelectReasonStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What are you claiming for?",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 16),

          // Reason cards
          ..._claimReasons.map((reason) {
            final isSelected = _selectedReason == reason['id'];
            return GestureDetector(
              onTap: () {
                setState(() => _selectedReason = reason['id']);
                widget.aiService.speakText(reason['label']);
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (reason['color'] as Color).withOpacity(0.07)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? reason['color'] as Color
                        : Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: (reason['color'] as Color).withOpacity(0.15),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (reason['color'] as Color).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        reason['icon'] as IconData,
                        color: reason['color'] as Color,
                        size: 22,
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reason['label'],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            reason['description'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: reason['color'] as Color,
                        ),
                        child: Icon(Icons.check, size: 14, color: Colors.white),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),

          SizedBox(height: 24),

          // Policy selector
          Text(
            "Select Policy",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedPolicy != null
                    ? Color(0xFF2563EB)
                    : Color(0xFFE2E8F0),
                width: _selectedPolicy != null ? 2 : 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPolicy,
                hint: Text(
                  "Choose your policy",
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                items: _mockPolicies
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                          p,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedPolicy = val),
              ),
            ),
          ),

          SizedBox(height: 32),
          _buildNextButton("Next: Upload Document", _nextFromReason),
          SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─── Step 2: Upload Photo ─────────────────────────────────────────

  Widget _buildUploadPhotoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Upload Supporting Document",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Hospital bill, FIR copy, discharge summary, or any relevant document",
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          SizedBox(height: 24),

          // Upload area
          GestureDetector(
            onTap: _showPhotoOptions,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: double.infinity,
              height: _uploadedPhoto != null ? 240 : 180,
              decoration: BoxDecoration(
                color: _uploadedPhoto != null
                    ? Colors.transparent
                    : Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _uploadedPhoto != null
                      ? Color(0xFF2563EB)
                      : Color(0xFFCBD5E1),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: _uploadedPhoto != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            _uploadedPhoto!,
                            width: double.infinity,
                            height: 240,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _uploadedPhoto = null),
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Document uploaded",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFF2563EB).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.upload_file,
                            size: 36,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "Tap to upload document",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Camera or Gallery",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          SizedBox(height: 16),

          // Document tips
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xFFF59E0B).withOpacity(0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFFF59E0B),
                  size: 18,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Tip: Clear photos of bills or discharge papers speed up your claim by up to 3x.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF92400E),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 32),
          _buildNextButton(
            _uploadedPhoto != null ? "Next: Review Claim" : "Skip & Review",
            _nextFromUpload,
          ),
          SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─── Step 3: Review ───────────────────────────────────────────────

  Widget _buildReviewStep() {
    final reason = _claimReasons.firstWhere(
      (r) => r['id'] == _selectedReason,
      orElse: () => _claimReasons.first,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Review your claim details",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Please confirm before submitting",
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          SizedBox(height: 20),

          // Summary card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildReviewRow(
                  icon: Icons.assignment,
                  label: "Claim Type",
                  value: reason['label'],
                  valueColor: reason['color'] as Color,
                ),
                Divider(height: 24, color: Color(0xFFE2E8F0)),
                _buildReviewRow(
                  icon: Icons.policy,
                  label: "Policy",
                  value: _selectedPolicy ?? "—",
                ),
                Divider(height: 24, color: Color(0xFFE2E8F0)),
                _buildReviewRow(
                  icon: Icons.attach_file,
                  label: "Document",
                  value: _uploadedPhoto != null
                      ? "1 file uploaded ✓"
                      : "No document (optional)",
                  valueColor: _uploadedPhoto != null
                      ? Color(0xFF10B981)
                      : Color(0xFF94A3B8),
                ),
                Divider(height: 24, color: Color(0xFFE2E8F0)),
                _buildReviewRow(
                  icon: Icons.calendar_today,
                  label: "Date",
                  value: _formatDate(DateTime.now()),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Photo thumbnail if uploaded
          if (_uploadedPhoto != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _uploadedPhoto!,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 16),
          ],

          // Declaration
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFF10B981), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "I confirm that the above information is correct. False claims may result in policy termination.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF065F46),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 32),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmitting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Submitting...",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send, size: 20),
                        SizedBox(width: 10),
                        Text(
                          "Submit Claim",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildReviewRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF2563EB).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Color(0xFF2563EB), size: 18),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
              SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Step 4: Success ──────────────────────────────────────────────

  Widget _buildSuccessStep() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated check
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, val, child) =>
                  Transform.scale(scale: val, child: child),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF10B981).withOpacity(0.4),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(Icons.check, color: Colors.white, size: 52),
              ),
            ),

            SizedBox(height: 28),
            Text(
              "Claim Submitted!",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Our team will review and respond within 7–15 business days",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),

            SizedBox(height: 28),

            // Reference number
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Claim Reference Number",
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _claimReferenceNumber,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Save this number for tracking",
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // What happens next
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "What happens next?",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF065F46),
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildNextStep("1", "Claim received & registered"),
                  _buildNextStep("2", "Documents verified by insurer"),
                  _buildNextStep("3", "Amount credited to your bank"),
                ],
              ),
            ),

            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  "Back to Dashboard",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextStep(String num, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 13, color: Color(0xFF065F46))),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  Widget _buildNextButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return "${dt.day} ${months[dt.month]} ${dt.year}";
  }
}
