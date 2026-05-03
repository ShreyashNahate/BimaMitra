import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bimamitra/services/admin_service.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();

  List<Map<String, dynamic>> _allPolicies = [];
  List<Map<String, dynamic>> _filteredPolicies = [];
  Map<String, dynamic> _stats = {};

  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  int _selectedTabIndex = 0;

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTabIndex = _tabController.index);
    });
    _loadAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);

    try {
      final policies = await _adminService.getAllPoliciesFromAllUsers();
      final stats = await _adminService.getAdminStats();

      if (mounted) {
        setState(() {
          _allPolicies = policies;
          _filteredPolicies = policies;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = _allPolicies;

    // Apply status filter
    filtered = _adminService.filterByStatus(filtered, _selectedFilter);

    // Apply search filter
    filtered = _adminService.searchPolicies(filtered, _searchQuery);

    setState(() {
      _filteredPolicies = filtered;
    });
  }

  void _showPolicyDetails(Map<String, dynamic> policy) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPolicyDetailsSheet(policy),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> policy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Policy'),
        content: Text('Are you sure you want to delete this policy?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePolicy(policy);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePolicy(Map<String, dynamic> policy) async {
    try {
      await _adminService.deletePolicy(
        userId: policy['userId'],
        policyId: policy['policyKey'],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Policy deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _loadAdminData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting policy: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updatePolicyStatus(
    Map<String, dynamic> policy,
    String newStatus,
  ) async {
    try {
      await _adminService.updatePolicyStatus(
        userId: policy['userId'],
        policyId: policy['policyKey'],
        status: newStatus,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Policy status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );

      _loadAdminData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboardTab(),
                  _buildPoliciesTab(),
                  _buildAnalyticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
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
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Manage all policies',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadAdminData,
              tooltip: 'Refresh',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Color(0xFF2563EB),
        unselectedLabelColor: Color(0xFF64748B),
        indicatorColor: Color(0xFF2563EB),
        indicatorWeight: 3,
        tabs: [
          Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
          Tab(icon: Icon(Icons.policy), text: 'Policies'),
          Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAdminData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 16),
            _buildStatsGrid(),
            SizedBox(height: 24),
            Text(
              'Recent Policies',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 12),
            ..._filteredPolicies
                .take(5)
                .map((policy) => _buildPolicyCard(policy, isCompact: true))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPoliciesTab() {
    return Column(
      children: [
        _buildSearchAndFilter(),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _filteredPolicies.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadAdminData,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _filteredPolicies.length,
                    itemBuilder: (context, index) =>
                        _buildPolicyCard(_filteredPolicies[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    final policyDistribution = _adminService.getPolicyTypeDistribution(
      _allPolicies,
    );

    return RefreshIndicator(
      onRefresh: _loadAdminData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Policy Distribution',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 16),
            _buildPolicyDistributionChart(policyDistribution),
            SizedBox(height: 24),
            Text(
              'Export Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 12),
            _buildExportButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          title: 'Total Policies',
          value: _stats['totalPolicies']?.toString() ?? '0',
          icon: Icons.policy,
          color: Color(0xFF2563EB),
          gradient: [Color(0xFF2563EB), Color(0xFF1E40AF)],
        ),
        _buildStatCard(
          title: 'Active',
          value: _stats['activePolicies']?.toString() ?? '0',
          icon: Icons.check_circle,
          color: Color(0xFF10B981),
          gradient: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        _buildStatCard(
          title: 'Total Users',
          value: _stats['totalUsers']?.toString() ?? '0',
          icon: Icons.people,
          color: Color(0xFF7C3AED),
          gradient: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
        ),
        _buildStatCard(
          title: 'Total Premium',
          value: '₹${_stats['totalPremium'] ?? 0}',
          icon: Icons.currency_rupee,
          color: Color(0xFFF59E0B),
          gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
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
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by policy name, number, or user ID',
              prefixIcon: Icon(Icons.search, color: Color(0xFF64748B)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Color(0xFF64748B)),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        _applyFilters();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _applyFilters();
            },
          ),
          SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All'),
                SizedBox(width: 8),
                _buildFilterChip('Active'),
                SizedBox(width: 8),
                _buildFilterChip('Pending'),
                SizedBox(width: 8),
                _buildFilterChip('Expired'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = label);
        _applyFilters();
      },
      selectedColor: Color(0xFF2563EB),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Color(0xFF64748B),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? Color(0xFF2563EB) : Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildPolicyCard(
    Map<String, dynamic> policy, {
    bool isCompact = false,
  }) {
    String status = policy['status']?.toString() ?? 'Unknown';
    Color statusColor = _getStatusColor(status);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showPolicyDetails(policy),
          child: Padding(
            padding: EdgeInsets.all(16),
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
                      child: Icon(
                        Icons.shield,
                        color: Color(0xFF2563EB),
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            policy['policyName']?.toString() ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            policy['policyNumber']?.toString() ?? 'N/A',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
                if (!isCompact) ...[
                  SizedBox(height: 12),
                  Divider(height: 1),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          Icons.person,
                          'User: ${policy['userId']?.toString().substring(0, 15) ?? 'N/A'}...',
                        ),
                      ),
                      SizedBox(width: 8),
                      _buildInfoChip(
                        Icons.currency_rupee,
                        policy['premium']?.toString() ?? 'N/A',
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  _buildInfoChip(
                    Icons.calendar_today,
                    'Created: ${_adminService.formatDate(policy['createdAt'] ?? 0)}',
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildActionButton(
                        icon: Icons.edit,
                        label: 'Update',
                        color: Color(0xFF2563EB),
                        onTap: () => _showStatusUpdateDialog(policy),
                      ),
                      SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.delete,
                        label: 'Delete',
                        color: Color(0xFFEF4444),
                        onTap: () => _showDeleteConfirmation(policy),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Color(0xFF64748B)),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyDetailsSheet(Map<String, dynamic> policy) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Policy Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(20),
                  children: [
                    _buildDetailRow('Policy Name', policy['policyName']),
                    _buildDetailRow('Policy Number', policy['policyNumber']),
                    _buildDetailRow('Premium', policy['premium']),
                    _buildDetailRow('Status', policy['status']),
                    _buildDetailRow('Start Date', policy['startDate']),
                    _buildDetailRow('User ID', policy['userId']),
                    _buildDetailRow(
                      'Created At',
                      _adminService.formatTimestamp(policy['createdAt'] ?? 0),
                    ),
                    if (policy['location'] != null &&
                        policy['location'].toString().isNotEmpty)
                      _buildDetailRow('Location', policy['location']),
                    if (policy['surveyData'] != null) ...[
                      SizedBox(height: 16),
                      Text(
                        'Survey Data',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 8),
                      _buildSurveyData(policy['surveyData']),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyData(Map<dynamic, dynamic> surveyData) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: surveyData.entries.map((entry) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  '${entry.key}: ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  entry.value.toString(),
                  style: TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showStatusUpdateDialog(Map<String, dynamic> policy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Policy Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Active'),
              leading: Radio<String>(
                value: 'Active',
                groupValue: policy['status'],
                onChanged: (value) {
                  Navigator.pop(context);
                  _updatePolicyStatus(policy, 'Active');
                },
              ),
            ),
            ListTile(
              title: Text('Pending'),
              leading: Radio<String>(
                value: 'Pending',
                groupValue: policy['status'],
                onChanged: (value) {
                  Navigator.pop(context);
                  _updatePolicyStatus(policy, 'Pending');
                },
              ),
            ),
            ListTile(
              title: Text('Expired'),
              leading: Radio<String>(
                value: 'Expired',
                groupValue: policy['status'],
                onChanged: (value) {
                  Navigator.pop(context);
                  _updatePolicyStatus(policy, 'Expired');
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyDistributionChart(Map<String, int> distribution) {
    if (distribution.isEmpty) {
      return Center(child: Text('No data available'));
    }

    final colors = [
      Color(0xFF2563EB),
      Color(0xFF10B981),
      Color(0xFF7C3AED),
      Color(0xFFF59E0B),
      Color(0xFFEC4899),
    ];

    return Column(
      children: distribution.entries.toList().asMap().entries.map((entry) {
        int index = entry.key;
        var data = entry.value;
        String policyType = data.key;
        int count = data.value;
        Color color = colors[index % colors.length];

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  policyType,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExportButton() {
    return ElevatedButton.icon(
      onPressed: () {
        final csv = _adminService.exportPoliciesToCSV(_allPolicies);
        Clipboard.setData(ClipboardData(text: csv));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV data copied to clipboard'),
            backgroundColor: Colors.green,
          ),
        );
      },
      icon: Icon(Icons.download),
      label: Text('Export to CSV'),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.policy_outlined, size: 64, color: Color(0xFF94A3B8)),
          SizedBox(height: 16),
          Text(
            'No Policies Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Color(0xFF10B981);
      case 'pending':
        return Color(0xFFF59E0B);
      case 'expired':
        return Color(0xFFEF4444);
      default:
        return Color(0xFF64748B);
    }
  }
}
