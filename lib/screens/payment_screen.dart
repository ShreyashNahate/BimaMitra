import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'payment_models.dart';
import 'payment_service.dart';
import 'success_policy_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String policyName;
  final String premium;
  final String policyId;
  final Map<String, dynamic>? kycData;

  const PaymentScreen({
    Key? key,
    required this.policyName,
    required this.premium,
    required this.policyId,
    this.kycData,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.upi;
  bool _isProcessing = false;

  // UPI Controllers
  final TextEditingController _upiIdController = TextEditingController();

  // Card Controllers
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  // Net Banking
  String? _selectedBank;

  // Autopay Controllers
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _accountHolderController =
      TextEditingController();
  bool _autopayConsent = false;

  final PaymentService _paymentService = PaymentService();

  @override
  void dispose() {
    _upiIdController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  // Helper method to parse premium amount
  double _parsePremiumAmount(String premium) {
    // Remove ₹ symbol, /year, /month, spaces, and commas
    String cleanedPremium = premium
        .replaceAll('₹', '')
        .replaceAll('/year', '')
        .replaceAll('/month', '')
        .replaceAll(',', '')
        .trim();

    return double.parse(cleanedPremium);
  }

  Future<void> _processPayment() async {
    if (!_validatePaymentDetails()) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Show realistic processing steps
      await _showProcessingSteps();

      PaymentRequest request;
      double amount = _parsePremiumAmount(widget.premium);

      switch (_selectedMethod) {
        case PaymentMethod.upi:
          request = PaymentRequest(
            method: PaymentMethod.upi,
            amount: amount,
            policyId: widget.policyId,
            upiId: _upiIdController.text.trim(),
          );
          break;

        case PaymentMethod.card:
          request = PaymentRequest(
            method: PaymentMethod.card,
            amount: amount,
            policyId: widget.policyId,
            cardNumber: _cardNumberController.text.replaceAll(' ', ''),
            cardHolder: _cardHolderController.text.trim(),
            expiryDate: _expiryController.text.trim(),
            cvv: _cvvController.text.trim(),
          );
          break;

        case PaymentMethod.netBanking:
          request = PaymentRequest(
            method: PaymentMethod.netBanking,
            amount: amount,
            policyId: widget.policyId,
            bankName: _selectedBank,
          );
          break;

        case PaymentMethod.autopay:
          request = PaymentRequest(
            method: PaymentMethod.autopay,
            amount: amount,
            policyId: widget.policyId,
            accountNumber: _accountNumberController.text.trim(),
            ifscCode: _ifscController.text.trim().toUpperCase(),
            accountHolder: _accountHolderController.text.trim(),
          );
          break;
      }

      final result = await _paymentService.processPayment(request);

      if (result.success) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => SuccessPolicyScreen(
                policyName: widget.policyName,
                premium: widget.premium,
                policyId: widget.policyId,
                paymentMethod: _selectedMethod.displayName,
                transactionId: result.transactionId!,
                policyStartDate: DateTime.now(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      _showErrorDialog('An error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showProcessingSteps() async {
    // Simulate realistic payment gateway steps
    if (_selectedMethod == PaymentMethod.upi) {
      await Future.delayed(const Duration(milliseconds: 600));
    } else if (_selectedMethod == PaymentMethod.card) {
      await Future.delayed(const Duration(milliseconds: 1000));
    } else if (_selectedMethod == PaymentMethod.netBanking) {
      await Future.delayed(const Duration(milliseconds: 800));
    } else if (_selectedMethod == PaymentMethod.autopay) {
      await Future.delayed(const Duration(milliseconds: 1200));
    }
  }

  bool _validatePaymentDetails() {
    String errorMessage = '';

    switch (_selectedMethod) {
      case PaymentMethod.upi:
        if (_upiIdController.text.trim().isEmpty) {
          errorMessage = 'Please enter UPI ID';
        } else if (!_isValidUPI(_upiIdController.text.trim())) {
          errorMessage = 'Please enter a valid UPI ID (e.g., name@bank)';
        }
        break;

      case PaymentMethod.card:
        if (_cardNumberController.text.replaceAll(' ', '').length != 16) {
          errorMessage = 'Please enter a valid 16-digit card number';
        } else if (_cardHolderController.text.trim().isEmpty) {
          errorMessage = 'Please enter card holder name';
        } else if (!_isValidExpiry(_expiryController.text.trim())) {
          errorMessage = 'Please enter valid expiry (MM/YY)';
        } else if (_cvvController.text.trim().length != 3) {
          errorMessage = 'Please enter valid 3-digit CVV';
        }
        break;

      case PaymentMethod.netBanking:
        if (_selectedBank == null) {
          errorMessage = 'Please select a bank';
        }
        break;

      case PaymentMethod.autopay:
        if (_accountNumberController.text.trim().isEmpty) {
          errorMessage = 'Please enter account number';
        } else if (!_isValidIFSC(_ifscController.text.trim())) {
          errorMessage = 'Please enter valid IFSC code';
        } else if (_accountHolderController.text.trim().isEmpty) {
          errorMessage = 'Please enter account holder name';
        } else if (!_autopayConsent) {
          errorMessage = 'Please provide consent for autopay mandate';
        }
        break;
    }

    if (errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
      return false;
    }

    return true;
  }

  bool _isValidUPI(String upi) {
    return RegExp(r'^[\w.-]+@[\w.-]+$').hasMatch(upi);
  }

  bool _isValidExpiry(String expiry) {
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(expiry)) return false;
    final parts = expiry.split('/');
    final month = int.tryParse(parts[0]);
    return month != null && month >= 1 && month <= 12;
  }

  bool _isValidIFSC(String ifsc) {
    return RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc.toUpperCase());
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getProcessingMessage() {
    switch (_selectedMethod) {
      case PaymentMethod.upi:
        return 'Processing UPI Payment';
      case PaymentMethod.card:
        return 'Verifying Card Details';
      case PaymentMethod.netBanking:
        return 'Connecting to Bank';
      case PaymentMethod.autopay:
        return 'Setting up Auto-Pay';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Color(0xFF2563EB),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildPolicyHeader(),
                _buildPaymentMethodSelector(),
                _buildPaymentForm(),
                const SizedBox(height: 100),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(strokeWidth: 4),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _getProcessingMessage(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please wait...',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildPaymentButton(),
    );
  }

  Widget _buildPolicyHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Policy Details',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            widget.policyName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Premium Amount',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                widget.premium,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          _buildPaymentMethodTile(
            PaymentMethod.upi,
            Icons.account_balance_wallet,
            'UPI',
            'Pay using UPI ID',
          ),
          const Divider(height: 1),
          _buildPaymentMethodTile(
            PaymentMethod.card,
            Icons.credit_card,
            'Debit/Credit Card',
            'Visa, Mastercard, RuPay',
          ),
          const Divider(height: 1),
          _buildPaymentMethodTile(
            PaymentMethod.netBanking,
            Icons.account_balance,
            'Net Banking',
            'Pay via your bank account',
          ),
          const Divider(height: 1),
          _buildPaymentMethodTile(
            PaymentMethod.autopay,
            Icons.autorenew,
            'Autopay (Mandate)',
            'Auto-debit for renewals',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(
    PaymentMethod method,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isSelected = _selectedMethod == method;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Radio<PaymentMethod>(
        value: method,
        groupValue: _selectedMethod,
        onChanged: (value) {
          setState(() => _selectedMethod = value!);
        },
      ),
      onTap: () {
        setState(() => _selectedMethod = method);
      },
    );
  }

  Widget _buildPaymentForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _getFormForSelectedMethod(),
    );
  }

  Widget _getFormForSelectedMethod() {
    switch (_selectedMethod) {
      case PaymentMethod.upi:
        return _buildUPIForm();
      case PaymentMethod.card:
        return _buildCardForm();
      case PaymentMethod.netBanking:
        return _buildNetBankingForm();
      case PaymentMethod.autopay:
        return _buildAutopayForm();
    }
  }

  Widget _buildUPIForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter UPI ID',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _upiIdController,
          decoration: InputDecoration(
            hintText: 'example@upi',
            prefixIcon: const Icon(Icons.account_balance_wallet),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Enter your UPI ID (e.g., yourname@paytm)',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Card Details',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cardNumberController,
          decoration: InputDecoration(
            labelText: 'Card Number',
            hintText: '1234 5678 9012 3456',
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            _CardNumberInputFormatter(),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cardHolderController,
          decoration: InputDecoration(
            labelText: 'Card Holder Name',
            hintText: 'JOHN DOE',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _expiryController,
                decoration: InputDecoration(
                  labelText: 'Expiry',
                  hintText: 'MM/YY',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _ExpiryDateInputFormatter(),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _cvvController,
                decoration: InputDecoration(
                  labelText: 'CVV',
                  hintText: '123',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNetBankingForm() {
    final banks = [
      'State Bank of India',
      'HDFC Bank',
      'ICICI Bank',
      'Axis Bank',
      'Kotak Mahindra Bank',
      'Punjab National Bank',
      'Bank of Baroda',
      'Canara Bank',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Your Bank',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedBank,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.account_balance),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          hint: const Text('Choose your bank'),
          items: banks.map((bank) {
            return DropdownMenuItem(value: bank, child: Text(bank));
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedBank = value);
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'You will be redirected to your bank\'s secure login page',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAutopayForm() {
    String premiumAmount = widget.premium
        .replaceAll('₹', '')
        .replaceAll('/year', '')
        .replaceAll('/month', '')
        .trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bank Account Details',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _accountNumberController,
          decoration: InputDecoration(
            labelText: 'Account Number',
            hintText: 'Enter account number',
            prefixIcon: const Icon(Icons.account_balance),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ifscController,
          decoration: InputDecoration(
            labelText: 'IFSC Code',
            hintText: 'SBIN0001234',
            prefixIcon: const Icon(Icons.code),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
            LengthLimitingTextInputFormatter(11),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _accountHolderController,
          decoration: InputDecoration(
            labelText: 'Account Holder Name',
            hintText: 'As per bank records',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.amber.shade900,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Autopay Mandate',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'By enabling autopay, you authorize automatic deduction of ₹$premiumAmount for policy renewals.',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _autopayConsent,
          onChanged: (value) {
            setState(() => _autopayConsent = value ?? false);
          },
          title: const Text(
            'I authorize the automatic debit mandate',
            style: TextStyle(fontSize: 14),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildPaymentButton() {
    String premiumAmount = widget.premium
        .replaceAll('/year', '')
        .replaceAll('/month', '')
        .trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Pay $premiumAmount',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// Input formatters
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length && i < 4; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
