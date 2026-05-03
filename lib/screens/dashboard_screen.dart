import 'package:flutter/material.dart';
import 'package:bimamitra/services/language_service.dart';
import 'package:bimamitra/services/ai_service.dart';
import 'package:bimamitra/services/firebase_service.dart';
import 'package:bimamitra/widgets/ai_avatar.dart';
import 'package:bimamitra/screens/onboarding_screen.dart';
import 'package:bimamitra/screens/insurance_history_screen.dart';
import 'package:bimamitra/screens/ai_help_screen.dart';
import 'package:bimamitra/screens/claim_screen.dart';

class DashboardScreen extends StatefulWidget {
  final AIService aiService;

  DashboardScreen({required this.aiService});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final FirebaseService _firebaseService = FirebaseService();

  int _activePoliciesCount = 0;
  String _totalPremium = '₹0';
  List<Map<String, dynamic>> _recentPolicies = [];
  bool _isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();

    _loadDashboardData();

    // Welcome message
    Future.delayed(Duration(milliseconds: 500), () {
      widget.aiService.speakText("Welcome to BimaMitra Dashboard");
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDashboardData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToClaim() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClaimScreen(aiService: widget.aiService),
      ),
    ).then((_) => _loadDashboardData());
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      print('🔄 Loading dashboard data...');

      final activePolicies = await _firebaseService.getActivePoliciesCount();
      final totalPremium = await _firebaseService.getTotalPremiumAmount();
      final allPolicies = await _firebaseService.getAllPolicies();

      print('✅ Loaded: $activePolicies policies, $totalPremium total');
      print('📋 Recent policies: ${allPolicies.length}');

      if (mounted) {
        setState(() {
          _activePoliciesCount = activePolicies;
          _totalPremium = totalPremium;
          _recentPolicies = allPolicies.take(3).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading dashboard: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToNewInsurance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingScreen(aiService: widget.aiService),
      ),
    ).then((_) => _loadDashboardData());
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            InsuranceHistoryScreen(aiService: widget.aiService),
      ),
    ).then((_) => _loadDashboardData());
  }

  void _navigateToAIHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIHelpScreen(aiService: widget.aiService),
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
            RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: Color(0xFF2563EB),
              child: CustomScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildAppBar(),
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatsCards(),
                              SizedBox(height: 24),
                              _buildTrustBanner(), // ← ADD THIS
                              SizedBox(height: 24),
                              _buildQuickActions(),
                              SizedBox(height: 32),
                              _buildRecentPoliciesSection(),
                              SizedBox(height: 24),
                              _buildUpcomingFeatures(),
                              SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AIAvatar(aiService: widget.aiService),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBanner() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF10B981).withOpacity(0.08),
            Color(0xFF2563EB).withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF10B981).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user, color: Color(0xFF10B981), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Your data is protected with SSL encryption. BimaMitra is a trusted, secure platform.",
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1E293B),
                height: 1.4,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Color(0xFF10B981),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "SECURE",
              style: TextStyle(
                fontSize: 9,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Color(0xFF2563EB),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final isCollapsed = constraints.biggest.height <= kToolbarHeight + 60;

          return FlexibleSpaceBar(
            centerTitle: false,
            titlePadding: EdgeInsets.only(left: 16, bottom: 16),
            title: isCollapsed
                ? Text(
                    'BimaMitra',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 50, 70, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BimaMitra',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        LanguageService.getText("how_can_i_help"),
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadDashboardData,
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No new notifications'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatsCards() {
    if (_isLoading) {
      return Row(
        children: [
          Expanded(child: _buildSkeletonCard()),
          SizedBox(width: 16),
          Expanded(child: _buildSkeletonCard()),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.shield,
            title: 'Active Policies',
            value: _activePoliciesCount.toString(),
            color: Color(0xFF10B981),
            gradient: [Color(0xFF10B981), Color(0xFF059669)],
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.account_balance_wallet,
            title: 'Total Premium',
            value: _totalPremium,
            color: Color(0xFF2563EB),
            gradient: [Color(0xFF2563EB), Color(0xFF1E40AF)],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 16),

        // Existing Row (UNCHANGED)
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.add_circle_outline,
                label: 'New Insurance',
                color: Color(0xFF2563EB),
                onTap: _navigateToNewInsurance,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.history,
                label: 'View History',
                color: Color(0xFF7C3AED),
                onTap: _navigateToHistory,
              ),
            ),
          ],
        ),

        SizedBox(height: 12),

        // Existing AI Help button (UNCHANGED)
        _buildActionButton(
          icon: Icons.support_agent,
          label: 'AI Help',
          color: Color(0xFF10B981),
          onTap: _navigateToAIHelp,
          isFullWidth: true,
        ),

        SizedBox(height: 12),

        // ✅ NEW CLAIM BUTTON
        _buildActionButton(
          icon: Icons.assignment_turned_in,
          label: 'File a Claim',
          color: Color(0xFFEF4444),
          onTap: _navigateToClaim,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: isFullWidth
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  SizedBox(height: 12),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRecentPoliciesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Policies',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            if (_recentPolicies.isNotEmpty)
              TextButton(
                onPressed: _navigateToHistory,
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 16),
        _isLoading
            ? _buildLoadingPolicies()
            : _recentPolicies.isEmpty
            ? _buildEmptyState()
            : Column(
                children: _recentPolicies
                    .map((policy) => _buildPolicyCard(policy))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildLoadingPolicies() {
    return Column(
      children: List.generate(
        2,
        (index) => Container(
          height: 100,
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFF94A3B8)),
          SizedBox(height: 16),
          Text(
            'No Policies Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Get started by applying for your first insurance',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToNewInsurance,
            icon: Icon(Icons.add),
            label: Text('Apply Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard(Map<String, dynamic> policy) {
    String status = policy['status']?.toString() ?? 'Active';
    Color statusColor = status == 'Active'
        ? Color(0xFF10B981)
        : Color(0xFF94A3B8);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
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
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.shield, color: Color(0xFF2563EB), size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  policy['policyName']?.toString() ?? 'Policy',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  policy['policyNumber']?.toString() ?? '',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Coming Soon',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 16),
        _buildFeatureCard(
          icon: Icons.headset_mic,
          title: '24/7 Support',
          description: 'Get instant help from our AI assistant',
          color: Color(0xFFF59E0B),
        ),
        SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.compare,
          title: 'Policy Comparison',
          description: 'Compare multiple policies side by side',
          color: Color(0xFF8B5CF6),
        ),
        SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.notifications_active,
          title: 'Premium Reminders',
          description: 'Never miss a payment deadline',
          color: Color(0xFFEC4899),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Soon',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
