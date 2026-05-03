import 'package:flutter/material.dart';
import 'package:bimamitra/services/language_service.dart';
import 'package:bimamitra/services/ai_service.dart';
import 'package:bimamitra/services/firebase_service.dart';
import 'package:bimamitra/widgets/ai_avatar.dart';
import 'package:bimamitra/screens/policy_detail_screen.dart';

class InsuranceHistoryScreen extends StatefulWidget {
  final AIService aiService;

  InsuranceHistoryScreen({required this.aiService});

  @override
  _InsuranceHistoryScreenState createState() => _InsuranceHistoryScreenState();
}

class _InsuranceHistoryScreenState extends State<InsuranceHistoryScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();

  List<Map<String, dynamic>> _allPolicies = [];
  List<Map<String, dynamic>> _filteredPolicies = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

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
    _loadPolicies();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPolicies() async {
    setState(() => _isLoading = true);

    try {
      print('🔄 Loading policies from Firebase...');
      final policies = await _firebaseService.getAllPolicies();
      print('✅ Loaded ${policies.length} policies');

      if (mounted) {
        setState(() {
          _allPolicies = policies;
          _filteredPolicies = policies;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading policies: $e');
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load policies: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _filterPolicies(String filter) {
    setState(() {
      _selectedFilter = filter;

      if (filter == 'All') {
        _filteredPolicies = _allPolicies;
      } else {
        _filteredPolicies = _allPolicies
            .where((policy) => policy['status'] == filter)
            .toList();
      }
    });
  }

  void _navigateToPolicyDetail(Map<String, dynamic> policy) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PolicyDetailScreen(aiService: widget.aiService, policy: policy),
      ),
    ).then((_) => _loadPolicies());
  }

  // Safe getter methods with null checks and defaults
  String _getPolicyName(Map<String, dynamic> policy) {
    return policy['policyName']?.toString() ?? 'Insurance Policy';
  }

  String _getPolicyNumber(Map<String, dynamic> policy) {
    return policy['policyNumber']?.toString() ?? 'N/A';
  }

  String _getStatus(Map<String, dynamic> policy) {
    return policy['status']?.toString() ?? 'Active';
  }

  String _getStartDate(Map<String, dynamic> policy) {
    return policy['startDate']?.toString() ?? 'N/A';
  }

  String _getPremium(Map<String, dynamic> policy) {
    return policy['premium']?.toString() ?? '₹0';
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
                _buildFilterChips(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadPolicies,
                    color: Color(0xFF2563EB),
                    child: _isLoading
                        ? _buildLoadingState()
                        : _filteredPolicies.isEmpty
                        ? _buildEmptyState()
                        : _buildPoliciesList(),
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
                  'Insurance History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${_filteredPolicies.length} ${_filteredPolicies.length == 1 ? 'policy' : 'policies'}',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFF2563EB)),
            onPressed: _loadPolicies,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All'),
            SizedBox(width: 8),
            _buildFilterChip('Active'),
            SizedBox(width: 8),
            _buildFilterChip('Expired'),
            SizedBox(width: 8),
            _buildFilterChip('Pending'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;

    return GestureDetector(
      onTap: () => _filterPolicies(label),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(0xFF2563EB) : Color(0xFFE2E8F0),
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
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading policies...',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 60),
                Icon(Icons.search_off, size: 80, color: Color(0xFF94A3B8)),
                SizedBox(height: 24),
                Text(
                  _selectedFilter == 'All'
                      ? 'No Policies Found'
                      : 'No $_selectedFilter Policies',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  _selectedFilter == 'All'
                      ? 'You haven\'t applied for any insurance yet'
                      : 'Try selecting a different filter',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliciesList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: _filteredPolicies.length,
        itemBuilder: (context, index) {
          return _buildPolicyCard(_filteredPolicies[index]);
        },
      ),
    );
  }

  Widget _buildPolicyCard(Map<String, dynamic> policy) {
    String status = _getStatus(policy);
    Color statusColor = _getStatusColor(status);
    IconData statusIcon = _getStatusIcon(status);

    return GestureDetector(
      onTap: () => _navigateToPolicyDetail(policy),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
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
            // Header
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.shield,
                      color: Color(0xFF2563EB),
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getPolicyName(policy),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _getPolicyNumber(policy),
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Details
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.calendar_today,
                      label: 'Start Date',
                      value: _getStartDate(policy),
                    ),
                  ),
                  Container(width: 1, height: 40, color: Color(0xFFE2E8F0)),
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.account_balance_wallet,
                      label: 'Premium',
                      value: '${_getPremium(policy)}/year',
                    ),
                  ),
                ],
              ),
            ),

            // Action Button
            Container(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToPolicyDetail(policy),
                      icon: Icon(Icons.visibility, size: 18),
                      label: Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF2563EB),
                        side: BorderSide(color: Color(0xFF2563EB)),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
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

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Color(0xFF64748B)),
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
          textAlign: TextAlign.center,
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
