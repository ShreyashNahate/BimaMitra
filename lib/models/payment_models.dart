// TODO Implement this library.
enum PaymentMethod { upi, card, netBanking, autopay }

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.card:
        return 'Debit/Credit Card';
      case PaymentMethod.netBanking:
        return 'Net Banking';
      case PaymentMethod.autopay:
        return 'Autopay';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.upi:
        return '💳';
      case PaymentMethod.card:
        return '💳';
      case PaymentMethod.netBanking:
        return '🏦';
      case PaymentMethod.autopay:
        return '🔄';
    }
  }
}

class PaymentRequest {
  final PaymentMethod method;
  final double amount;
  final String policyId;

  // UPI
  final String? upiId;

  // Card
  final String? cardNumber;
  final String? cardHolder;
  final String? expiryDate;
  final String? cvv;

  // Net Banking
  final String? bankName;

  // Autopay
  final String? accountNumber;
  final String? ifscCode;
  final String? accountHolder;

  PaymentRequest({
    required this.method,
    required this.amount,
    required this.policyId,
    this.upiId,
    this.cardNumber,
    this.cardHolder,
    this.expiryDate,
    this.cvv,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.accountHolder,
  });

  Map<String, dynamic> toJson() {
    return {
      'method': method.displayName,
      'amount': amount,
      'policy_id': policyId,
      'upi_id': upiId,
      'card_number': cardNumber != null
          ? '**** **** **** ${cardNumber!.substring(cardNumber!.length - 4)}'
          : null,
      'card_holder': cardHolder,
      'expiry_date': expiryDate,
      'bank_name': bankName,
      'account_number': accountNumber != null
          ? '****${accountNumber!.substring(accountNumber!.length - 4)}'
          : null,
      'ifsc_code': ifscCode,
      'account_holder': accountHolder,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

class PaymentResponse {
  final bool success;
  final String? transactionId;
  final String? message;
  final DateTime timestamp;
  final PaymentMethod? method;
  final double? amount;

  PaymentResponse({
    required this.success,
    this.transactionId,
    this.message,
    required this.timestamp,
    this.method,
    this.amount,
  });

  factory PaymentResponse.success({
    required String transactionId,
    required PaymentMethod method,
    required double amount,
  }) {
    return PaymentResponse(
      success: true,
      transactionId: transactionId,
      message: 'Payment completed successfully',
      timestamp: DateTime.now(),
      method: method,
      amount: amount,
    );
  }

  factory PaymentResponse.failure({required String message}) {
    return PaymentResponse(
      success: false,
      message: message,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'transaction_id': transactionId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'method': method?.displayName,
      'amount': amount,
    };
  }
}

class PolicyPayment {
  final String policyId;
  final String policyName;
  final double premium;
  final PaymentMethod method;
  final String transactionId;
  final DateTime paymentDate;
  final PaymentStatus status;

  PolicyPayment({
    required this.policyId,
    required this.policyName,
    required this.premium,
    required this.method,
    required this.transactionId,
    required this.paymentDate,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'policy_id': policyId,
      'policy_name': policyName,
      'premium': premium,
      'method': method.displayName,
      'transaction_id': transactionId,
      'payment_date': paymentDate.toIso8601String(),
      'status': status.name,
    };
  }

  factory PolicyPayment.fromJson(Map<String, dynamic> json) {
    return PolicyPayment(
      policyId: json['policy_id'],
      policyName: json['policy_name'],
      premium: json['premium'],
      method: PaymentMethod.values.firstWhere(
        (m) => m.displayName == json['method'],
        orElse: () => PaymentMethod.upi,
      ),
      transactionId: json['transaction_id'],
      paymentDate: DateTime.parse(json['payment_date']),
      status: PaymentStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
    );
  }
}

enum PaymentStatus { pending, processing, completed, failed, refunded }

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
}
