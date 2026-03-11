import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/payment_config.dart';

class CheckoutInitResult {
  const CheckoutInitResult({required this.checkoutUrl, required this.txRef});

  final String checkoutUrl;
  final String txRef;
}

class CheckoutVerifyResult {
  const CheckoutVerifyResult({
    required this.success,
    required this.message,
    this.txRef,
    this.transactionId,
  });

  final bool success;
  final String message;
  final String? txRef;
  final String? transactionId;
}

class ChapaPaymentService {
  const ChapaPaymentService();

  Future<CheckoutInitResult> initializeCheckout({
    required String uid,
    required String email,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String sku,
    required int amountEtb,
  }) async {
    if (!PaymentConfig.isConfigured) {
      throw StateError(
        'Payment backend is not configured. Set PAYMENT_BACKEND_BASE_URL.',
      );
    }

    final uri = Uri.parse(
      '${PaymentConfig.backendBaseUrl}/payments/chapa/initialize',
    );
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'uid': uid,
            'email': email,
            'firstName': firstName,
            'lastName': lastName,
            'phoneNumber': phoneNumber,
            'sku': sku,
            'amount': amountEtb,
            'currency': 'ETB',
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('Initialize checkout failed: ${res.body}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final checkoutUrl = json['checkoutUrl'] as String?;
    final txRef = json['txRef'] as String?;
    if (checkoutUrl == null || txRef == null) {
      throw StateError('Invalid checkout response from backend.');
    }
    return CheckoutInitResult(checkoutUrl: checkoutUrl, txRef: txRef);
  }

  Future<CheckoutVerifyResult> verifyCheckout({
    required String txRef,
    required String uid,
    required String sku,
  }) async {
    if (!PaymentConfig.isConfigured) {
      return const CheckoutVerifyResult(
        success: false,
        message: 'Payment backend is not configured.',
      );
    }

    final uri = Uri.parse(
      '${PaymentConfig.backendBaseUrl}/payments/chapa/verify',
    );
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'txRef': txRef, 'uid': uid, 'sku': sku}),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      return CheckoutVerifyResult(
        success: false,
        message: 'Verify failed: ${res.body}',
      );
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return CheckoutVerifyResult(
      success: json['success'] == true,
      message: (json['message'] ?? 'Verification complete').toString(),
      txRef: (json['txRef'] ?? txRef).toString(),
      transactionId: json['transactionId']?.toString(),
    );
  }
}
