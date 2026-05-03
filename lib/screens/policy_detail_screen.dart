import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bimamitra/services/language_service.dart';
import 'package:bimamitra/services/ai_service.dart';
import 'package:bimamitra/services/firebase_service.dart';
import 'package:bimamitra/widgets/ai_avatar.dart';
import 'package:share_plus/share_plus.dart';

class PolicyDetailScreen extends StatefulWidget {
  final AIService aiService;
  final Map<String, dynamic> policy;

  PolicyDetailScreen({required this.aiService, required this.policy});

  @override
  _PolicyDetailScreenState createState() => _PolicyDetailScreenState();
}

class _PolicyDetailScreenState extends State<PolicyDetailScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Static hospital data
  final List<Map<String, dynamic>> _nearbyHospitals = [
    {
      'name': 'Apollo Hospital',
      'location': 'Baner, Pune',
      'distance': '1.2 km',
      'cashless': true,
    },
    {
      'name': 'Ruby Hall Clinic',
      'location': 'Wanowrie, Pune',
      'distance': '2.5 km',
      'cashless': true,
    },
    {
      'name': 'Jehangir Hospital',
      'location': 'Sassoon Road, Pune',
      'distance': '3.1 km',
      'cashless': true,
    },
    {
      'name': 'Sahyadri Hospital',
      'location': 'Deccan, Pune',
      'distance': '3.8 km',
      'cashless': true,
    },
    {
      'name': 'KEM Hospital',
      'location': 'Rasta Peth, Pune',
      'distance': '4.2 km',
      'cashless': false,
    },
    {
      'name': 'Deenanath Mangeshkar',
      'location': 'Erandwane, Pune',
      'distance': '5.0 km',
      'cashless': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
    Future.delayed(Duration(milliseconds: 500), () {
      widget.aiService.speakText("Here are your policy details");
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getString(String key, [String defaultValue = '']) {
    final value = widget.policy[key];
    if (value == null) return defaultValue;
    return value.toString();
  }

  Map<String, dynamic> _getSurveyData() {
    final surveyData = widget.policy['surveyData'];
    if (surveyData == null) return {};
    if (surveyData is Map) {
      return Map<String, dynamic>.from(
        surveyData.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return {};
  }

  Future<void> _sharePolicy() async {
    final shareText =
        '''
🛡️ My Insurance Policy Details

Policy: ${_getString('policyName', 'Insurance Policy')}
Policy Number: ${_getString('policyNumber', 'N/A')}
Premium: ${_getString('premium', '₹0')}/year
Start Date: ${_getString('startDate', 'N/A')}
Status: ${_getString('status', 'Active')}

Powered by BimaMitra 📱
''';
    try {
      await Share.share(
        shareText,
        subject: 'My Insurance Policy - ${_getString('policyName')}',
      );
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

  void _copyPolicyNumber() {
    Clipboard.setData(ClipboardData(text: _getString('policyNumber')));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Policy number copied!'),
          ],
        ),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String status = _getString('status', 'Active');
    Color statusColor = _getStatusColor(status);

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatusBanner(status, statusColor),
                            SizedBox(height: 20),
                            _buildSecuritySection(), // 🔐 Goal 5
                            SizedBox(height: 20),
                            _buildPolicyInfoCard(),
                            SizedBox(height: 20),
                            _buildCoverageDetailsCard(), // 📄 Goal 4a
                            SizedBox(height: 20),
                            _buildExclusionsCard(), // 📄 Goal 4b
                            SizedBox(height: 20),
                            _buildClaimProcessCard(), // 📄 Goal 4c
                            SizedBox(height: 20),
                            _buildRequiredDocumentsCard(), // 📄 Goal 4d
                            SizedBox(height: 20),
                            _buildHospitalListCard(), // 🏥 Goal 4
                            SizedBox(height: 20),
                            _buildSurveyDataCard(),
                            SizedBox(height: 20),
                            _buildActionButtons(),
                            SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
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

  // ─── Security Section ───────────────────────────────────────────
  Widget _buildSecuritySection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF10B981).withOpacity(0.1),
            Color(0xFF059669).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFF10B981).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock, color: Color(0xFF10B981), size: 22),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Your data is secure",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF065F46),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "SSL",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  "All data is encrypted via HTTPS/SSL. We never share your personal information with third parties.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF065F46).withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Coverage Details ────────────────────────────────────────────
  Widget _buildCoverageDetailsCard() {
    final coverageItems = [
      {
        'icon': Icons.personal_injury,
        'title': 'Accidental Death',
        'amount': '₹2,00,000',
        'color': Color(0xFF2563EB),
      },
      {
        'icon': Icons.accessible,
        'title': 'Permanent Disability',
        'amount': '₹2,00,000',
        'color': Color(0xFF7C3AED),
      },
      {
        'icon': Icons.healing,
        'title': 'Partial Disability',
        'amount': '₹1,00,000',
        'color': Color(0xFFF59E0B),
      },
      {
        'icon': Icons.local_hospital,
        'title': 'Hospitalization',
        'amount': '₹50,000',
        'color': Color(0xFF10B981),
      },
    ];

    return _buildSectionCard(
      icon: Icons.security,
      iconColor: Color(0xFF2563EB),
      title: "Coverage Details",
      child: Column(
        children: coverageItems
            .map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: item['color'] as Color,
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item['title'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      item['amount'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ─── Exclusions ──────────────────────────────────────────────────
  Widget _buildExclusionsCard() {
    final exclusions = [
      "Self-inflicted injuries or suicide attempts",
      "Injuries under influence of alcohol or drugs",
      "War, riots, or nuclear risks",
      "Pre-existing critical illnesses (unless declared)",
      "Cosmetic or elective surgeries",
    ];

    return _buildSectionCard(
      icon: Icons.not_interested,
      iconColor: Color(0xFFEF4444),
      title: "Exclusions",
      child: Column(
        children: exclusions
            .map(
              (e) => Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.cancel_outlined,
                      size: 16,
                      color: Color(0xFFEF4444),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ─── Claim Process ────────────────────────────────────────────────
  Widget _buildClaimProcessCard() {
    final steps = [
      {
        'title': 'Notify Insurer',
        'desc':
            'Call helpline or visit nearest branch within 24 hours of incident.',
      },
      {
        'title': 'Fill Claim Form',
        'desc': 'Download and fill the claim form from the official portal.',
      },
      {
        'title': 'Submit Documents',
        'desc': 'Attach required documents (FIR, hospital bills, ID proof).',
      },
      {
        'title': 'Claim Verification',
        'desc': 'Insurer verifies documents — typically takes 7–15 days.',
      },
      {
        'title': 'Settlement',
        'desc': 'Amount credited to registered bank account after approval.',
      },
    ];

    return _buildSectionCard(
      icon: Icons.assignment_turned_in,
      iconColor: Color(0xFF10B981),
      title: "Claim Process",
      child: Column(
        children: List.generate(
          steps.length,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: i < steps.length - 1 ? 0 : 0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step line
                  Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            "${i + 1}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (i < steps.length - 1)
                        Container(
                          width: 2,
                          height: 36,
                          color: Color(0xFF10B981).withOpacity(0.3),
                        ),
                    ],
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i]['title']!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            steps[i]['desc']!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
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

  // ─── Required Documents ───────────────────────────────────────────
  Widget _buildRequiredDocumentsCard() {
    final docs = [
      {'icon': Icons.badge, 'doc': 'Aadhaar Card / Voter ID'},
      {'icon': Icons.description, 'doc': 'Policy Document Copy'},
      {'icon': Icons.local_hospital, 'doc': 'Hospital Discharge Summary'},
      {'icon': Icons.receipt_long, 'doc': 'Medical Bills & Receipts'},
      {
        'icon': Icons.account_balance,
        'doc': 'Bank Account Details (Cancelled Cheque)',
      },
      {'icon': Icons.gavel, 'doc': 'FIR Copy (for accident claims)'},
    ];

    return _buildSectionCard(
      icon: Icons.folder_open,
      iconColor: Color(0xFF7C3AED),
      title: "Required Documents",
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: docs
            .map(
              (d) => Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      d['icon'] as IconData,
                      size: 14,
                      color: Color(0xFF7C3AED),
                    ),
                    SizedBox(width: 6),
                    Text(
                      d['doc'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ─── Hospital List ────────────────────────────────────────────────
  Widget _buildHospitalListCard() {
    return _buildSectionCard(
      icon: Icons.local_hospital,
      iconColor: Color(0xFFEF4444),
      title: "Nearby Cashless Hospitals",
      child: Column(
        children: _nearbyHospitals
            .map(
              (h) => Container(
                margin: EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.local_hospital,
                        color: Color(0xFFEF4444),
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h['name'],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 11,
                                color: Color(0xFF64748B),
                              ),
                              SizedBox(width: 2),
                              Text(
                                h['location'],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.directions_walk,
                                size: 11,
                                color: Color(0xFF64748B),
                              ),
                              SizedBox(width: 2),
                              Text(
                                h['distance'],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: h['cashless']
                            ? Color(0xFF10B981).withOpacity(0.1)
                            : Color(0xFF94A3B8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        h['cashless'] ? "Cashless" : "Reimbursement",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: h['cashless']
                              ? Color(0xFF10B981)
                              : Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ─── Reusable section card wrapper ───────────────────────────────
  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
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
              Icon(icon, color: iconColor, size: 22),
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  // ─── Keep all existing methods below unchanged ─────────────────

  Widget _buildHeader() {
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
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Policy Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _getString('policyNumber', 'N/A'),
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(String status, Color statusColor) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 12,
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
            child: Icon(_getStatusIcon(status), color: Colors.white, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Policy Status',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (status == 'Active') ...[
            Icon(Icons.verified, color: Colors.white, size: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildPolicyInfoCard() {
    String location = _getString('location');
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.policy, color: Color(0xFF2563EB), size: 24),
              SizedBox(width: 12),
              Text(
                'Policy Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildInfoRow(
            icon: Icons.description,
            label: 'Policy Name',
            value: _getString('policyName', 'Insurance Policy'),
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.confirmation_number,
            label: 'Policy Number',
            value: _getString('policyNumber', 'N/A'),
            isCopyable: true,
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.account_balance_wallet,
            label: 'Premium',
            value: '${_getString('premium', '₹0')}/year',
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Start Date',
            value: _getString('startDate', 'N/A'),
          ),
          if (location.isNotEmpty) ...[
            SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'Location',
              value: location,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSurveyDataCard() {
    Map<String, dynamic> surveyData = _getSurveyData();
    if (surveyData.isEmpty) return SizedBox.shrink();
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Color(0xFF7C3AED), size: 24),
              SizedBox(width: 12),
              Text(
                'Additional Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          ...surveyData.entries.map((entry) {
            if (entry.value == null || entry.value.toString().isEmpty)
              return SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: _buildSurveyItem(
                _formatLabel(entry.key),
                entry.value.toString(),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  String _formatLabel(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .split(' ')
        .map(
          (w) => w.isEmpty
              ? ''
              : w[0].toUpperCase() + w.substring(1).toLowerCase(),
        )
        .join(' ')
        .trim();
  }

  Widget _buildSurveyItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: Color(0xFF7C3AED),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isCopyable = false,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF2563EB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Color(0xFF2563EB), size: 20),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
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
            onPressed: _copyPolicyNumber,
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _sharePolicy,
            icon: Icon(Icons.share),
            label: Text(
              'Share Policy',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Download feature coming soon!'),
                behavior: SnackBarBehavior.floating,
              ),
            ),
            icon: Icon(Icons.download),
            label: Text(
              'Download PDF',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Color(0xFF2563EB),
              side: BorderSide(color: Color(0xFF2563EB), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Color(0xFF10B981);
      case 'Expired':
        return Color(0xFFEF4444);
      case 'Pending':
        return Color(0xFFF59E0B);
      default:
        return Color(0xFF64748B);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Active':
        return Icons.check_circle;
      case 'Expired':
        return Icons.cancel;
      case 'Pending':
        return Icons.schedule;
      default:
        return Icons.info;
    }
  }
}
