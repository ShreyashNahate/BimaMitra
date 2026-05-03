import 'dart:io';
import 'package:bimamitra/services/ai_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'payment_screen.dart';

class KYCVerificationScreen extends StatefulWidget {
  final String selectedPolicy;
  final String premium;
  final AIService aiService;

  KYCVerificationScreen({
    required this.selectedPolicy,
    required this.premium,
    required this.aiService,
  });

  @override
  _KYCVerificationScreenState createState() => _KYCVerificationScreenState();
}

class _KYCVerificationScreenState extends State<KYCVerificationScreen>
    with TickerProviderStateMixin {
  File? _aadharImage;
  bool _isUploaded = false;
  final ImagePicker _picker = ImagePicker();

  // Simulated location and timestamp
  String _location = "";
  String _timestamp = "";
  String _qrData = "";

  late AnimationController _uploadAnimationController;
  late AnimationController _checkmarkAnimationController;
  late Animation<double> _uploadScaleAnimation;
  late Animation<double> _checkmarkScaleAnimation;
  late Animation<double> _checkmarkRotationAnimation;

  @override
  void initState() {
    super.initState();

    // Upload animation
    _uploadAnimationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _uploadScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _uploadAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    // Checkmark animation
    _checkmarkAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _checkmarkScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkmarkAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _checkmarkRotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkmarkAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _uploadAnimationController.dispose();
    _checkmarkAnimationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _aadharImage = File(pickedFile.path);
          _isUploaded = true;

          // Simulate GPS location
          _location = "19.0760° N, 72.8777° E\nMumbai, Maharashtra";

          // Capture timestamp
          _timestamp = DateFormat(
            'dd MMM yyyy, hh:mm a',
          ).format(DateTime.now());

          // Generate QR data based on policy info
          _qrData =
              "BIMAMITRA|${widget.selectedPolicy}|${_timestamp}|KYC_VERIFIED";
        });

        _uploadAnimationController.forward();
        _checkmarkAnimationController.forward();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aadhar card uploaded successfully'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Upload Aadhar Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 24),
            _buildImageSourceOption(
              icon: Icons.camera_alt,
              title: "Take Photo",
              subtitle: "Use camera to capture",
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            SizedBox(height: 12),
            _buildImageSourceOption(
              icon: Icons.photo_library,
              title: "Choose from Gallery",
              subtitle: "Select existing photo",
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Color(0xFF2563EB), size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  void _submitKYC() {
    if (!_isUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload Aadhar card first'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          policyName: widget.selectedPolicy,
          premium: widget.premium,
          policyId: 'POL-${DateTime.now().millisecondsSinceEpoch}',
          kycData: {
            'location': _location,
            'timestamp': _timestamp,
            'verified': true,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('KYC Verification'),
        backgroundColor: Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload your Aadhar card',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please upload a clear photo of your Aadhar card',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  SizedBox(height: 24),
                  _buildUploadSection(),
                  if (_isUploaded) ...[
                    SizedBox(height: 24),
                    _buildCapturedInfoSection(),
                    SizedBox(height: 24),
                    _buildBlockchainBadge(),
                    SizedBox(height: 24),
                    _buildQRCodeSection(),
                  ],
                  SizedBox(height: 24),
                  _buildInstructions(),
                ],
              ),
            ),
          ),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return GestureDetector(
      onTap: _isUploaded ? null : _showImageSourceDialog,
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isUploaded ? Color(0xFF10B981) : Color(0xFFE2E8F0),
            width: _isUploaded ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: _aadharImage == null
            ? _buildUploadPlaceholder()
            : _buildUploadedImage(),
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFF2563EB).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.credit_card, size: 48, color: Color(0xFF2563EB)),
        ),
        SizedBox(height: 20),
        Text(
          'Position Aadhar Card',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Front side first',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _showImageSourceDialog,
          icon: Icon(Icons.upload),
          label: Text('Upload Aadhar Photo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadedImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            _aadharImage!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: ScaleTransition(
            scale: _checkmarkScaleAnimation,
            child: RotationTransition(
              turns: _checkmarkRotationAnimation,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF10B981).withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(Icons.check, color: Colors.white, size: 24),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  "Aadhar Card Uploaded",
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
    );
  }

  Widget _buildCapturedInfoSection() {
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
              Icon(Icons.verified_user, color: Color(0xFF10B981), size: 20),
              SizedBox(width: 8),
              Text(
                'Automatically Captured',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(color: Color(0xFFE2E8F0)),
          SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.location_on,
            label: 'GPS Location',
            value: _location,
            iconColor: Color(0xFFEF4444),
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.access_time,
            label: 'Timestamp',
            value: _timestamp,
            iconColor: Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        SizedBox(width: 12),
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
                  color: Color(0xFF1E293B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlockchainBadge() {
    return ScaleTransition(
      scale: _uploadScaleAnimation,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF2563EB).withOpacity(0.3),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.security, color: Colors.white, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verified via Blockchain',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tamper-proof verification',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.verified, color: Color(0xFF10B981), size: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return ScaleTransition(
      scale: _uploadScaleAnimation,
      child: Container(
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
          children: [
            Text(
              "Verification QR Code",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFE2E8F0)),
              ),
              child: QrImageView(
                data: _qrData,
                version: QrVersions.auto,
                size: 160,
                backgroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Scan for instant verification",
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text(
                'Instructions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildInstructionItem('Ensure all details are visible'),
          SizedBox(height: 8),
          _buildInstructionItem('Avoid glare and shadows'),
          SizedBox(height: 8),
          _buildInstructionItem('Upload both sides if required'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Color(0xFF2563EB),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
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
        onPressed: _isUploaded ? _submitKYC : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF2563EB),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Color(0xFF94A3B8),
          elevation: 0,
          minimumSize: Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _isUploaded ? 'Continue to Payment' : 'Upload Photo First',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
