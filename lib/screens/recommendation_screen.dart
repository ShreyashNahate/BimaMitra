import 'package:flutter/material.dart';
import 'package:bimamitra/services/language_service.dart';
import 'package:bimamitra/services/ai_service.dart';
import 'package:bimamitra/widgets/ai_avatar.dart';
import 'package:bimamitra/screens/consent_screen.dart';

class RecommendationScreen extends StatefulWidget {
  final AIService aiService;
  final String policy;
  final String reason;
  final String premium;
  final Map<String, dynamic> userProfile;

  RecommendationScreen({
    required this.aiService,
    required this.policy,
    required this.reason,
    required this.premium,
    this.userProfile = const {},
  });

  @override
  _RecommendationScreenState createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedPolicy;
  bool _showWhyPolicy = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _continueToConsent() {
    if (_selectedPolicy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a policy to continue'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConsentScreen(
          aiService: widget.aiService,
          selectedPolicy: _selectedPolicy!,
          premium: widget.premium,
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
                _buildHeader(),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ListView(
                      padding: EdgeInsets.all(24),
                      children: [
                        // User profile summary chips
                        if (widget.userProfile.isNotEmpty)
                          _buildProfileSummary(),
                        SizedBox(height: 16),

                        _buildPolicyCard(
                          policyName: LanguageService.getText(
                            "pradhan_mantri_suraksha_bima",
                          ),
                          premium: "₹12",
                          benefits: [
                            LanguageService.getText(
                              "accidental_death_coverage",
                            ),
                            LanguageService.getText(
                              "permanent_disability_coverage",
                            ),
                            LanguageService.getText(
                              "partial_disability_coverage",
                            ),
                          ],
                          isRecommended:
                              widget.policy.contains("Pradhan") ||
                              widget.policy.contains("Suraksha"),
                          badge: "Government-backed",
                        ),
                        SizedBox(height: 16),
                        _buildPolicyCard(
                          policyName: LanguageService.getText(
                            "jeevan_jyoti_bima_yojana",
                          ),
                          premium: "₹436",
                          benefits: [
                            LanguageService.getText("life_cover"),
                            LanguageService.getText("renewable_every_year"),
                            LanguageService.getText("tax_benefits_80c"),
                          ],
                          isRecommended:
                              widget.policy.contains("Jeevan") ||
                              widget.policy.contains("Jyoti"),
                          badge: "Trusted Scheme",
                        ),
                      ],
                    ),
                  ),
                ),
                _buildContinueButton(),
              ],
            ),
            AIAvatar(aiService: widget.aiService),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummary() {
    final profile = widget.userProfile;
    final List<Map<String, String>> chips = [];

    if ((profile['fullName'] ?? '').toString().isNotEmpty)
      chips.add({'icon': '👤', 'label': profile['fullName'].toString()});
    if ((profile['occupation'] ?? '').toString().isNotEmpty)
      chips.add({'icon': '💼', 'label': profile['occupation'].toString()});
    if ((profile['age'] ?? 0) > 0)
      chips.add({'icon': '🎂', 'label': 'Age ${profile['age']}'});
    if ((profile['incomeRange'] ?? '').toString().isNotEmpty)
      chips.add({'icon': '💰', 'label': profile['incomeRange'].toString()});
    if ((profile['familySize'] ?? 0) > 0)
      chips.add({
        'icon': '👨‍👩‍👧',
        'label': 'Family of ${profile['familySize']}',
      });

    if (chips.isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF2563EB).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your Profile",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2563EB),
            ),
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips
                .map(
                  (chip) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Color(0xFF2563EB).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      "${chip['icon']} ${chip['label']}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard({
    required String policyName,
    required String premium,
    required List<String> benefits,
    bool isRecommended = false,
    String badge = "",
  }) {
    final bool isSelected = _selectedPolicy == policyName;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedPolicy = policyName;
        _showWhyPolicy = false;
      }),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isRecommended ? Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Color(0xFF2563EB)
                : (isRecommended ? Color(0xFF2563EB) : Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Color(0xFF2563EB).withOpacity(0.2)
                  : Colors.black.withOpacity(0.03),
              blurRadius: isSelected ? 12 : 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          policyName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isRecommended
                                ? Colors.white
                                : Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isRecommended
                                ? Colors.white
                                : Color(0xFF2563EB),
                          ),
                          child: Icon(
                            Icons.check,
                            size: 16,
                            color: isRecommended
                                ? Color(0xFF2563EB)
                                : Colors.white,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Trust badges
                  _buildTrustBadges(badge, isRecommended),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        "${LanguageService.getText('premium')}: ",
                        style: TextStyle(
                          fontSize: 14,
                          color: isRecommended
                              ? Colors.white.withOpacity(0.9)
                              : Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        "$premium${LanguageService.getText('per_year')}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isRecommended
                              ? Colors.white
                              : Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Divider
            isRecommended
                ? Container(height: 1, color: Colors.white.withOpacity(0.2))
                : Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Benefits
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LanguageService.getText("key_benefits"),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isRecommended
                          ? Colors.white.withOpacity(0.9)
                          : Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(height: 12),
                  ...benefits
                      .map((b) => _buildBenefitItem(b, isRecommended))
                      .toList(),
                ],
              ),
            ),

            // Why this policy
            Padding(
              padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      _showWhyPolicy = _selectedPolicy == policyName
                          ? !_showWhyPolicy
                          : true;
                      _selectedPolicy = policyName;
                    }),
                    child: Row(
                      children: [
                        Icon(
                          Icons.help_outline,
                          size: 20,
                          color: isRecommended
                              ? Colors.white
                              : Color(0xFF2563EB),
                        ),
                        SizedBox(width: 8),
                        Text(
                          LanguageService.getText("why_this_policy"),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isRecommended
                                ? Colors.white
                                : Color(0xFF2563EB),
                          ),
                        ),
                        Spacer(),
                        Icon(
                          _showWhyPolicy && _selectedPolicy == policyName
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 20,
                          color: isRecommended
                              ? Colors.white
                              : Color(0xFF2563EB),
                        ),
                      ],
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: SizedBox.shrink(),
                    secondChild: _buildWhyPolicySection(isRecommended),
                    crossFadeState:
                        _showWhyPolicy && _selectedPolicy == policyName
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),

            // Exclusions
            if (isSelected)
              Container(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LanguageService.getText("exclusions"),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isRecommended
                            ? Colors.white.withOpacity(0.7)
                            : Color(0xFF94A3B8),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      LanguageService.getText("self_inflicted_injuries"),
                      style: TextStyle(
                        fontSize: 12,
                        color: isRecommended
                            ? Colors.white.withOpacity(0.7)
                            : Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBadges(String badge, bool isRecommended) {
    if (badge.isEmpty) return SizedBox.shrink();
    final isGov = badge.contains("Government");
    return Wrap(
      spacing: 6,
      children: [
        _buildBadge(
          icon: isGov ? Icons.account_balance : Icons.verified,
          label: badge,
          color: isRecommended
              ? Colors.white
              : (isGov ? Color(0xFF10B981) : Color(0xFF7C3AED)),
          bgColor: isRecommended
              ? Colors.white.withOpacity(0.2)
              : (isGov
                    ? Color(0xFF10B981).withOpacity(0.1)
                    : Color(0xFF7C3AED).withOpacity(0.1)),
        ),
        _buildBadge(
          icon: Icons.check_circle_outline,
          label: "Verified Policy",
          color: isRecommended ? Colors.white : Color(0xFF2563EB),
          bgColor: isRecommended
              ? Colors.white.withOpacity(0.2)
              : Color(0xFF2563EB).withOpacity(0.1),
        ),
      ],
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyPolicySection(bool isRecommended) {
    final profile = widget.userProfile;
    final List<String> reasons = [widget.reason];

    // Add profile-specific reasons
    if ((profile['occupation'] ?? '').toString().isNotEmpty)
      reasons.add("✅ Matched to your occupation: ${profile['occupation']}");
    if ((profile['incomeRange'] ?? '').toString().isNotEmpty)
      reasons.add("✅ Fits your income range: ${profile['incomeRange']}");
    if ((profile['familySize'] ?? 0) > 0)
      reasons.add("✅ Covers a family of ${profile['familySize']}");
    if ((profile['age'] ?? 0) > 0)
      reasons.add("✅ Suitable for age ${profile['age']}");

    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRecommended
            ? Colors.white.withOpacity(0.1)
            : Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: reasons
            .map(
              (r) => Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  r,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: isRecommended ? Colors.white : Color(0xFF475569),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildBenefitItem(String benefit, bool isRecommended) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 18,
            color: isRecommended ? Colors.white : Color(0xFF10B981),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              benefit,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isRecommended ? Colors.white : Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                  LanguageService.getText("recommended_for_you"),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  LanguageService.getText("based_on_your_profile"),
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
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
        onPressed: _continueToConsent,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              LanguageService.getText("continue"),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }
}
