import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Generate unique user ID (in production, use Firebase Auth UID)
  String _userId = "user_${DateTime.now().millisecondsSinceEpoch}";

  void setUserId(String userId) {
    _userId = userId;
  }

  String getUserId() => _userId;

  /// Save a new policy to Firebase
  Future<String> savePolicy({
    required String policyName,
    required String policyNumber,
    required String premium,
    required String startDate,
    required String status,
    required Map<String, dynamic> surveyData,
    String? aadharImageUrl,
    String? location,
  }) async {
    try {
      // Generate unique policy ID
      String policyId = "policy_${DateTime.now().millisecondsSinceEpoch}";

      Map<String, dynamic> policyData = {
        'policyId': policyId,
        'policyName': policyName,
        'policyNumber': policyNumber,
        'premium': premium,
        'startDate': startDate,
        'status': status,
        'createdAt': ServerValue.timestamp,
        'surveyData': surveyData,
        'aadharImageUrl': aadharImageUrl ?? '',
        'location': location ?? '',
      };

      // Save to Firebase
      await _database
          .child('users')
          .child(_userId)
          .child('policies')
          .child(policyId)
          .set(policyData);

      return policyId;
    } catch (e) {
      throw Exception('Failed to save policy: $e');
    }
  }

  /// Get all policies for current user
  Future<List<Map<String, dynamic>>> getAllPolicies() async {
    try {
      DatabaseEvent event = await _database
          .child('users')
          .child(_userId)
          .child('policies')
          .once();

      if (event.snapshot.value == null) {
        return [];
      }

      Map<dynamic, dynamic> policiesMap =
          event.snapshot.value as Map<dynamic, dynamic>;

      List<Map<String, dynamic>> policies = [];

      policiesMap.forEach((key, value) {
        Map<String, dynamic> policy = Map<String, dynamic>.from(value);
        policy['key'] = key;
        policies.add(policy);
      });

      // Sort by createdAt (newest first)
      policies.sort((a, b) {
        int timeA = a['createdAt'] ?? 0;
        int timeB = b['createdAt'] ?? 0;
        return timeB.compareTo(timeA);
      });

      return policies;
    } catch (e) {
      throw Exception('Failed to fetch policies: $e');
    }
  }

  /// Get a single policy by ID
  Future<Map<String, dynamic>?> getPolicy(String policyId) async {
    try {
      DatabaseEvent event = await _database
          .child('users')
          .child(_userId)
          .child('policies')
          .child(policyId)
          .once();

      if (event.snapshot.value == null) {
        return null;
      }

      Map<String, dynamic> policy = Map<String, dynamic>.from(
        event.snapshot.value as Map,
      );
      policy['key'] = policyId;

      return policy;
    } catch (e) {
      throw Exception('Failed to fetch policy: $e');
    }
  }

  /// Update policy status
  Future<void> updatePolicyStatus(String policyId, String status) async {
    try {
      await _database
          .child('users')
          .child(_userId)
          .child('policies')
          .child(policyId)
          .update({'status': status});
    } catch (e) {
      throw Exception('Failed to update policy status: $e');
    }
  }

  /// Delete a policy
  Future<void> deletePolicy(String policyId) async {
    try {
      await _database
          .child('users')
          .child(_userId)
          .child('policies')
          .child(policyId)
          .remove();
    } catch (e) {
      throw Exception('Failed to delete policy: $e');
    }
  }

  /// Get active policies count
  Future<int> getActivePoliciesCount() async {
    try {
      List<Map<String, dynamic>> policies = await getAllPolicies();
      return policies.where((p) => p['status'] == 'Active').length;
    } catch (e) {
      return 0;
    }
  }

  /// Get total premium amount
  Future<String> getTotalPremiumAmount() async {
    try {
      List<Map<String, dynamic>> policies = await getAllPolicies();

      int total = 0;
      for (var policy in policies) {
        if (policy['status'] == 'Active') {
          String premium = policy['premium'] ?? '₹0';
          // Extract number from premium string (e.g., "₹12" -> 12)
          String numberOnly = premium.replaceAll(RegExp(r'[^0-9]'), '');
          if (numberOnly.isNotEmpty) {
            total += int.parse(numberOnly);
          }
        }
      }

      return '₹$total';
    } catch (e) {
      return '₹0';
    }
  }

  /// Save user survey data
  Future<void> saveSurveyData({
    required String occupation,
    required String age,
    required String income,
    required String dependents,
    required String healthConditions,
  }) async {
    try {
      Map<String, dynamic> surveyData = {
        'occupation': occupation,
        'age': age,
        'income': income,
        'dependents': dependents,
        'healthConditions': healthConditions,
        'completedAt': ServerValue.timestamp,
      };

      await _database
          .child('users')
          .child(_userId)
          .child('surveyData')
          .set(surveyData);
    } catch (e) {
      throw Exception('Failed to save survey data: $e');
    }
  }

  /// Get user survey data
  Future<Map<String, dynamic>?> getSurveyData() async {
    try {
      DatabaseEvent event = await _database
          .child('users')
          .child(_userId)
          .child('surveyData')
          .once();

      if (event.snapshot.value == null) {
        return null;
      }

      return Map<String, dynamic>.from(event.snapshot.value as Map);
    } catch (e) {
      return null;
    }
  }

  /// Listen to policy updates (real-time)
  Stream<List<Map<String, dynamic>>> watchPolicies() {
    return _database
        .child('users')
        .child(_userId)
        .child('policies')
        .onValue
        .map((event) {
          if (event.snapshot.value == null) {
            return <Map<String, dynamic>>[];
          }

          Map<dynamic, dynamic> policiesMap =
              event.snapshot.value as Map<dynamic, dynamic>;

          List<Map<String, dynamic>> policies = [];

          policiesMap.forEach((key, value) {
            Map<String, dynamic> policy = Map<String, dynamic>.from(value);
            policy['key'] = key;
            policies.add(policy);
          });

          // Sort by createdAt (newest first)
          policies.sort((a, b) {
            int timeA = a['createdAt'] ?? 0;
            int timeB = b['createdAt'] ?? 0;
            return timeB.compareTo(timeA);
          });

          return policies;
        });
  }

  /// Format timestamp to readable date
  String formatTimestamp(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd MMM yyyy').format(date);
  }
}
