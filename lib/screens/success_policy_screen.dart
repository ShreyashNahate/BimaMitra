import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:bimamitra/services/firebase_service.dart';

class SuccessPolicyScreen extends StatefulWidget {
  final String policyName;
  final String premium;
  final String policyId;
  final String paymentMethod;
  final String transactionId;
  final DateTime policyStartDate;

  SuccessPolicyScreen({
    required this.policyName,
    required this.premium,
    required this.policyId,
    required this.paymentMethod,
    required this.transactionId,
    required this.policyStartDate,
  });

  @override
  _SuccessPolicyScreenState createState() => _SuccessPolicyScreenState();
}

class _SuccessPolicyScreenState extends State<SuccessPolicyScreen>
    with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();

  late String _policyNumber;
  late String _startDate;
  bool _isSavingToFirebase = false;

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

    // Use the provided policy ID
    _policyNumber = widget.policyId;
    _startDate = DateFormat('dd MMM yyyy').format(widget.policyStartDate);

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

      // Save policy to Firebase
      _savePolicyToFirebase();
    });
  }

  Future<void> _savePolicyToFirebase() async {
    setState(() => _isSavingToFirebase = true);

    try {
      await _firebaseService.savePolicy(
        policyName: widget.policyName,
        policyNumber: _policyNumber,
        premium: widget.premium,
        startDate: _startDate,
        status: 'Active',
        surveyData: {
          'paymentMethod': widget.paymentMethod,
          'transactionId': widget.transactionId,
        },
        location: 'Mumbai, Maharashtra',
      );

      print('✅ Policy saved to Firebase successfully!');

      setState(() => _isSavingToFirebase = false);
    } catch (e) {
      print('❌ Failed to save policy: $e');
      setState(() => _isSavingToFirebase = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Policy saved locally, cloud sync failed'),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _successAnimationController.dispose();
    _waveAnimationController.dispose();
    _floatAnimationController.dispose();
    super.dispose();
  }

  void _goToHome() {
    // Pop all screens and go back to home
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goToHome();
        return false;
      },
      child: Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
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
                      _buildPaymentDetailsCard(),
                    ],
                  ),
                ),
              ),
              _buildBottomButton(),
            ],
          ),
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

        // Saving indicator
        if (_isSavingToFirebase)
          Positioned(
            bottom: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Color(0xFF2563EB)),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Saving...',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
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
            'Payment Successful!',
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
              'Your policy is now active',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Policy Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 20),
            _buildDetailRow(
              icon: Icons.policy,
              label: 'Policy Name',
              value: widget.policyName,
              iconColor: Color(0xFF2563EB),
            ),
            SizedBox(height: 16),
            Divider(color: Color(0xFFE2E8F0)),
            SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.confirmation_number,
              label: 'Policy Number',
              value: _policyNumber,
              iconColor: Color(0xFF7C3AED),
              isCopyable: true,
            ),
            SizedBox(height: 16),
            Divider(color: Color(0xFFE2E8F0)),
            SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.calendar_today,
              label: 'Start Date',
              value: _startDate,
              iconColor: Color(0xFF10B981),
            ),
            SizedBox(height: 16),
            Divider(color: Color(0xFFE2E8F0)),
            SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.account_balance_wallet,
              label: 'Premium',
              value: widget.premium,
              iconColor: Color(0xFFF59E0B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsCard() {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 20),
            _buildDetailRow(
              icon: Icons.payment,
              label: 'Payment Method',
              value: widget.paymentMethod,
              iconColor: Color(0xFF2563EB),
            ),
            SizedBox(height: 16),
            Divider(color: Color(0xFFE2E8F0)),
            SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.receipt,
              label: 'Transaction ID',
              value: widget.transactionId,
              iconColor: Color(0xFF10B981),
              isCopyable: true,
            ),
            SizedBox(height: 16),
            Divider(color: Color(0xFFE2E8F0)),
            SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.access_time,
              label: 'Payment Date',
              value: DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
              iconColor: Color(0xFF7C3AED),
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
                  fontSize: 14,
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
                  content: Text('Copied to clipboard!'),
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
          backgroundColor: Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Go to Dashboard',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
