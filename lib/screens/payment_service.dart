import 'dart:async';
import 'dart:math';
import 'payment_models.dart';

class PaymentService {
  // Demo payment processing - Static UI showcase
  // No real backend calls, just realistic UI flow

  Future<PaymentResponse> processPayment(PaymentRequest request) async {
    // Simulate realistic payment processing steps
    await Future.delayed(const Duration(milliseconds: 800));

    // Simulate connecting to payment gateway
    await Future.delayed(const Duration(milliseconds: 1200));

    // Always succeed for demo purposes
    final transactionId = _generateTransactionId(request.method);

    return PaymentResponse.success(
      transactionId: transactionId,
      method: request.method,
      amount: request.amount,
    );
  }

  String _generateTransactionId(PaymentMethod method) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);

    String prefix;
    switch (method) {
      case PaymentMethod.upi:
        prefix = 'UPI';
        break;
      case PaymentMethod.card:
        prefix = 'CARD';
        break;
      case PaymentMethod.netBanking:
        prefix = 'NB';
        break;
      case PaymentMethod.autopay:
        prefix = 'AUTO';
        break;
    }

    return '$prefix${timestamp}${random.toString().padLeft(4, '0')}';
  }

  // Verify payment status - Demo always shows completed
  Future<PaymentStatus> verifyPayment(String transactionId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return PaymentStatus.completed;
  }

  // Get payment history - Demo data
  Future<List<PolicyPayment>> getPaymentHistory(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  // Setup autopay mandate - Demo always succeeds
  Future<bool> setupAutopay({
    required String accountNumber,
    required String ifscCode,
    required String accountHolder,
    required double maxAmount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return true;
  }

  // Cancel autopay mandate - Demo always succeeds
  Future<bool> cancelAutopay(String mandateId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return true;
  }

  // Initiate refund - Demo always succeeds
  Future<bool> initiateRefund({
    required String transactionId,
    required double amount,
    required String reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return true;
  }

  // Validate UPI ID
  Future<bool> validateUpiId(String upiId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Basic validation
    final regex = RegExp(r'^[\w.-]+@[\w.-]+$');
    return regex.hasMatch(upiId);
  }

  // Validate card
  Future<Map<String, dynamic>> validateCard({
    required String cardNumber,
    required String expiryDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Luhn algorithm for card number validation
    bool isValidCardNumber = _luhnCheck(cardNumber.replaceAll(' ', ''));

    // Expiry validation
    bool isValidExpiry = _validateExpiry(expiryDate);

    String? cardType = _getCardType(cardNumber);

    return {
      'valid': isValidCardNumber && isValidExpiry,
      'card_type': cardType,
      'is_valid_number': isValidCardNumber,
      'is_valid_expiry': isValidExpiry,
    };
  }

  bool _luhnCheck(String cardNumber) {
    if (cardNumber.length != 16) return false;

    int sum = 0;
    bool alternate = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  bool _validateExpiry(String expiry) {
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(expiry)) return false;

    final parts = expiry.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse('20${parts[1]}');

    if (month < 1 || month > 12) return false;

    final now = DateTime.now();
    final expiryDate = DateTime(year, month);

    return expiryDate.isAfter(now);
  }

  String? _getCardType(String cardNumber) {
    final number = cardNumber.replaceAll(' ', '');

    if (number.startsWith('4')) {
      return 'Visa';
    } else if (number.startsWith(RegExp(r'5[1-5]'))) {
      return 'Mastercard';
    } else if (number.startsWith(RegExp(r'6(?:011|5)'))) {
      return 'RuPay';
    } else if (number.startsWith(RegExp(r'3[47]'))) {
      return 'American Express';
    }

    return null;
  }

  // Get available banks for net banking
  List<String> getAvailableBanks() {
    return [
      'State Bank of India',
      'HDFC Bank',
      'ICICI Bank',
      'Axis Bank',
      'Kotak Mahindra Bank',
      'Punjab National Bank',
      'Bank of Baroda',
      'Canara Bank',
      'Union Bank of India',
      'Bank of India',
      'IDBI Bank',
      'Yes Bank',
      'IndusInd Bank',
    ];
  }

  // Calculate processing fee (if any)
  double calculateProcessingFee({
    required PaymentMethod method,
    required double amount,
  }) {
    switch (method) {
      case PaymentMethod.upi:
        return 0; // No fee for UPI
      case PaymentMethod.card:
        return amount * 0.02; // 2% for cards
      case PaymentMethod.netBanking:
        return 10; // Flat ₹10 for net banking
      case PaymentMethod.autopay:
        return 0; // No fee for autopay
    }
  }
}

// Demo Repository - Static data only, no persistence needed for showcase
class PaymentRepository {
  // Demo: Store payment in memory only
  Future<bool> savePayment(PolicyPayment payment) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  // Demo: Return empty list
  Future<List<PolicyPayment>> getAllPayments() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  // Demo: Return null
  Future<PolicyPayment?> getPaymentByTransactionId(String transactionId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return null;
  }

  // Demo: Return empty list
  Future<List<PolicyPayment>> getPaymentsByPolicyId(String policyId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  // Demo: Always succeed
  Future<bool> updatePaymentStatus({
    required String transactionId,
    required PaymentStatus status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  // Demo: Always succeed
  Future<bool> deletePayment(String transactionId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }
}
