import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../services/language_service.dart';
import '../services/ai_service.dart';
import '../widgets/ai_avatar.dart';

class PolicySuccessScreen extends StatefulWidget {
  final AIService aiService;
  final String selectedPolicy;
  final String premium;

  PolicySuccessScreen({
    required this.aiService,
    required this.selectedPolicy,
    required this.premium,
  });

  @override
  _PolicySuccessScreenState createState() => _PolicySuccessScreenState();
}

class _PolicySuccessScreenState extends State<PolicySuccessScreen>
    with TickerProviderStateMixin {
  late String _policyNumber;
  late String _startDate;
  bool _isGeneratingPDF = false;

  late AnimationController _successAnimationController;
  late AnimationController _waveAnimationController;
  late AnimationController _floatAnimationController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // Generate policy number and start date
    _policyNumber = _generatePolicyNumber();
    _startDate = DateFormat('dd MMM yyyy').format(DateTime.now());

    // Success scale animation
    _successAnimationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successAnimationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Wave animation
    _waveAnimationController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _waveAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Float animation
    _floatAnimationController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _floatAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    Future.delayed(Duration(milliseconds: 300), () {
      _successAnimationController.forward();
      _waveAnimationController.repeat();
      widget.aiService.speakText(
        "Congratulations! Your policy has been successfully activated",
      );
    });
  }

  @override
  void dispose() {
    _successAnimationController.dispose();
    _waveAnimationController.dispose();
    _floatAnimationController.dispose();
    super.dispose();
  }

  String _generatePolicyNumber() {
    final now = DateTime.now();
    final random = (now.millisecondsSinceEpoch % 100000).toString().padLeft(
      6,
      '0',
    );
    return "BM-${now.year}-$random";
  }

  Future<void> _downloadPolicy() async {
    setState(() => _isGeneratingPDF = true);

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: pw.EdgeInsets.all(20),
                  color: PdfColors.blue700,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BimaMitra',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Insurance Policy Certificate',
                        style: pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 40),

                // Policy Details
                pw.Text(
                  'POLICY DETAILS',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),

                _buildPDFRow('Policy Number:', _policyNumber),
                _buildPDFRow('Policy Name:', widget.selectedPolicy),
                _buildPDFRow('Premium:', '${widget.premium}/year'),
                _buildPDFRow('Start Date:', _startDate),
                _buildPDFRow('Status:', 'Active'),

                pw.SizedBox(height: 40),

                // Coverage Details
                pw.Text(
                  'COVERAGE DETAILS',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),

                pw.Bullet(
                  text: 'Accidental Death Coverage: ₹2,00,000',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 8),
                pw.Bullet(
                  text: 'Permanent Disability Coverage: ₹2,00,000',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 8),
                pw.Bullet(
                  text: 'Partial Disability Coverage: ₹1,00,000',
                  style: pw.TextStyle(fontSize: 14),
                ),

                pw.SizedBox(height: 40),

                // Exclusions
                pw.Text(
                  'EXCLUSIONS',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),

                pw.Text(
                  'Self-inflicted injuries, war, nuclear risks',
                  style: pw.TextStyle(fontSize: 14),
                ),

                pw.Spacer(),

                // Footer
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    'This is a computer-generated document and does not require a signature.',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/Policy_$_policyNumber.pdf");
      await file.writeAsBytes(await pdf.save());

      setState(() => _isGeneratingPDF = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Policy downloaded successfully!'),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () {
              // Open PDF (you can use open_file package)
            },
          ),
        ),
      );

      widget.aiService.speakText("Policy downloaded successfully");
    } catch (e) {
      setState(() => _isGeneratingPDF = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download policy: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  pw.Widget _buildPDFRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Future<void> _sharePolicy() async {
    final shareText =
        '''
🎉 My Insurance Policy is Active!

Policy Number: $_policyNumber
Policy: ${widget.selectedPolicy}
Premium: ${widget.premium}/year
Start Date: $_startDate

Coverage:
• Accidental Death: ₹2,00,000
• Permanent Disability: ₹2,00,000
• Partial Disability: ₹1,00,000

Powered by BimaMitra 🛡️
''';

    try {
      await Share.share(shareText, subject: 'My BimaMitra Insurance Policy');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _goToHome() {
    // Pop all screens and go back to home
    Navigator.of(context).popUntil((route) => route.isFirst);
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        SizedBox(height: 40),
                        _buildSuccessAnimation(),
                        SizedBox(height: 32),
                        _buildSuccessMessage(),
                        SizedBox(height: 32),
                        _buildPolicyDetailsCard(),
                        SizedBox(height: 24),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
                _buildBottomButton(),
              ],
            ),
            AIAvatar(aiService: widget.aiService),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Animated waves
        AnimatedBuilder(
          animation: _waveAnimation,
          builder: (context, child) {
            return Container(
              width: 200 + (80 * _waveAnimation.value),
              height: 200 + (80 * _waveAnimation.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color(
                    0xFF10B981,
                  ).withOpacity(0.3 - (0.3 * _waveAnimation.value)),
                  width: 2,
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _waveAnimation,
          builder: (context, child) {
            final delayedValue = (_waveAnimation.value - 0.3).clamp(0.0, 1.0);
            return Container(
              width: 200 + (80 * delayedValue),
              height: 200 + (80 * delayedValue),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color(
                    0xFF10B981,
                  ).withOpacity(0.3 - (0.3 * delayedValue)),
                  width: 2,
                ),
              ),
            );
          },
        ),

        // Main success icon
        AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatAnimation.value),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 140,
                  height: 140,
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
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(Icons.check, size: 70, color: Colors.white),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSuccessMessage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Text(
            LanguageService.getText("your_policy_is_active"),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              LanguageService.getText("policy_successfully_issued"),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyDetailsCard() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildDetailRow(
              icon: Icons.policy,
              label: LanguageService.getText("policy_name"),
              value: widget.selectedPolicy,
              iconColor: Color(0xFF2563EB),
            ),
            SizedBox(height: 20),
            Divider(color: Color(0xFFE2E8F0)),
            SizedBox(height: 20),
            _buildDetailRow(
              icon: Icons.confirmation_number,
              label: LanguageService.getText("policy_number"),
              value: _policyNumber,
              iconColor: Color(0xFF7C3AED),
              isCopyable: true,
            ),
            SizedBox(height: 20),
            Divider(color: Color(0xFFE2E8F0)),
            SizedBox(height: 20),
            _buildDetailRow(
              icon: Icons.calendar_today,
              label: LanguageService.getText("start_date"),
              value: _startDate,
              iconColor: Color(0xFF10B981),
            ),
            SizedBox(height: 20),
            Divider(color: Color(0xFFE2E8F0)),
            SizedBox(height: 20),
            _buildDetailRow(
              icon: Icons.account_balance_wallet,
              label: LanguageService.getText("premium"),
              value: "${widget.premium}/year",
              iconColor: Color(0xFFF59E0B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    bool isCopyable = false,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
        if (isCopyable)
          IconButton(
            icon: Icon(Icons.copy, size: 20),
            color: Color(0xFF64748B),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Policy number copied!'),
                  backgroundColor: Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.download,
            label: LanguageService.getText("download_policy"),
            color: Color(0xFF2563EB),
            isLoading: _isGeneratingPDF,
            onPressed: _downloadPolicy,
          ),
          SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.share,
            label: LanguageService.getText("share_policy"),
            color: Color(0xFF10B981),
            onPressed: _sharePolicy,
          ),
          SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.description,
            label: LanguageService.getText("view_details"),
            color: Color(0xFF7C3AED),
            onPressed: () {
              // Navigate to policy details view
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Policy details feature coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon),
        label: Text(
          isLoading ? 'Generating...' : label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
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
      child: ElevatedButton(
        onPressed: _goToHome,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          LanguageService.getText("go_to_home"),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
