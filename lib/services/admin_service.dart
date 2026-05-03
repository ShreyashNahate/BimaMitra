import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Get all policies from all users
  Future<List<Map<String, dynamic>>> getAllPoliciesFromAllUsers() async {
    try {
      print('🔍 Fetching all policies from Firebase...');

      DatabaseEvent event = await _database.child('users').once();

      if (event.snapshot.value == null) {
        print('⚠️ No users found in database');
        return [];
      }

      Map<dynamic, dynamic> usersMap =
          event.snapshot.value as Map<dynamic, dynamic>;

      List<Map<String, dynamic>> allPolicies = [];

      // Iterate through all users
      usersMap.forEach((userId, userData) {
        if (userData is Map && userData['policies'] != null) {
          Map<dynamic, dynamic> policiesMap = userData['policies'];

          // Iterate through all policies for this user
          policiesMap.forEach((policyId, policyData) {
            Map<String, dynamic> policy = Map<String, dynamic>.from(policyData);
            policy['policyKey'] = policyId;
            policy['userId'] = userId;
            allPolicies.add(policy);
          });
        }
      });

      // Sort by createdAt (newest first)
      allPolicies.sort((a, b) {
        int timeA = a['createdAt'] ?? 0;
        int timeB = b['createdAt'] ?? 0;
        return timeB.compareTo(timeA);
      });

      print('✅ Found ${allPolicies.length} total policies');
      return allPolicies;
    } catch (e) {
      print('❌ Error fetching all policies: $e');
      throw Exception('Failed to fetch all policies: $e');
    }
  }

  /// Get statistics for admin dashboard
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      List<Map<String, dynamic>> allPolicies =
          await getAllPoliciesFromAllUsers();

      int totalPolicies = allPolicies.length;
      int activePolicies = allPolicies
          .where((p) => p['status'] == 'Active')
          .length;
      int pendingPolicies = allPolicies
          .where((p) => p['status'] == 'Pending')
          .length;

      // Calculate total premium
      int totalPremium = 0;
      for (var policy in allPolicies) {
        if (policy['status'] == 'Active') {
          String premium = policy['premium'] ?? '₹0';
          String numberOnly = premium.replaceAll(RegExp(r'[^0-9]'), '');
          if (numberOnly.isNotEmpty) {
            totalPremium += int.parse(numberOnly);
          }
        }
      }

      // Get unique users count
      Set<String> uniqueUsers = allPolicies
          .map((p) => p['userId'].toString())
          .toSet();

      return {
        'totalPolicies': totalPolicies,
        'activePolicies': activePolicies,
        'pendingPolicies': pendingPolicies,
        'totalPremium': totalPremium,
        'totalUsers': uniqueUsers.length,
      };
    } catch (e) {
      return {
        'totalPolicies': 0,
        'activePolicies': 0,
        'pendingPolicies': 0,
        'totalPremium': 0,
        'totalUsers': 0,
      };
    }
  }

  /// Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      DatabaseEvent event = await _database.child('users').once();

      if (event.snapshot.value == null) {
        return [];
      }

      Map<dynamic, dynamic> usersMap =
          event.snapshot.value as Map<dynamic, dynamic>;

      List<Map<String, dynamic>> users = [];

      usersMap.forEach((userId, userData) {
        if (userData is Map) {
          int policiesCount = 0;
          if (userData['policies'] != null) {
            policiesCount = (userData['policies'] as Map).length;
          }

          users.add({
            'userId': userId,
            'policiesCount': policiesCount,
            'surveyData': userData['surveyData'],
          });
        }
      });

      return users;
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// Update policy status (admin action)
  Future<void> updatePolicyStatus({
    required String userId,
    required String policyId,
    required String status,
  }) async {
    try {
      await _database
          .child('users')
          .child(userId)
          .child('policies')
          .child(policyId)
          .update({'status': status, 'lastUpdated': ServerValue.timestamp});

      print('✅ Policy status updated to: $status');
    } catch (e) {
      throw Exception('Failed to update policy status: $e');
    }
  }

  /// Delete policy (admin action)
  Future<void> deletePolicy({
    required String userId,
    required String policyId,
  }) async {
    try {
      await _database
          .child('users')
          .child(userId)
          .child('policies')
          .child(policyId)
          .remove();

      print('✅ Policy deleted successfully');
    } catch (e) {
      throw Exception('Failed to delete policy: $e');
    }
  }

  /// Format timestamp to readable date
  String formatTimestamp(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  /// Format date only
  String formatDate(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Search policies by policy number or name
  List<Map<String, dynamic>> searchPolicies(
    List<Map<String, dynamic>> policies,
    String query,
  ) {
    if (query.isEmpty) return policies;

    String lowerQuery = query.toLowerCase();

    return policies.where((policy) {
      String policyName = (policy['policyName'] ?? '').toString().toLowerCase();
      String policyNumber = (policy['policyNumber'] ?? '')
          .toString()
          .toLowerCase();
      String userId = (policy['userId'] ?? '').toString().toLowerCase();

      return policyName.contains(lowerQuery) ||
          policyNumber.contains(lowerQuery) ||
          userId.contains(lowerQuery);
    }).toList();
  }

  /// Filter policies by status
  List<Map<String, dynamic>> filterByStatus(
    List<Map<String, dynamic>> policies,
    String? status,
  ) {
    if (status == null || status == 'All') return policies;

    return policies.where((policy) => policy['status'] == status).toList();
  }

  /// Get policy type distribution
  Map<String, int> getPolicyTypeDistribution(
    List<Map<String, dynamic>> policies,
  ) {
    Map<String, int> distribution = {};

    for (var policy in policies) {
      String policyName = policy['policyName'] ?? 'Unknown';
      distribution[policyName] = (distribution[policyName] ?? 0) + 1;
    }

    return distribution;
  }

  /// Export policies to CSV format (as string)
  String exportPoliciesToCSV(List<Map<String, dynamic>> policies) {
    StringBuffer csv = StringBuffer();

    // Headers
    csv.writeln(
      'Policy ID,User ID,Policy Name,Policy Number,Premium,Status,Start Date,Created At',
    );

    // Data rows
    for (var policy in policies) {
      csv.writeln(
        [
          policy['policyKey'] ?? '',
          policy['userId'] ?? '',
          policy['policyName'] ?? '',
          policy['policyNumber'] ?? '',
          policy['premium'] ?? '',
          policy['status'] ?? '',
          policy['startDate'] ?? '',
          formatTimestamp(policy['createdAt'] ?? 0),
        ].join(','),
      );
    }

    return csv.toString();
  }
}
