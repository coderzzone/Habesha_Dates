class PaymentConfig {
  // Set this to your backend base URL that securely talks to Chapa using secret key.
  // Example: https://api.yourdomain.com
  static const String backendBaseUrl = String.fromEnvironment(
    'PAYMENT_BACKEND_BASE_URL',
    defaultValue: 'http://10.0.2.2:8787',
  );

  static bool get isConfigured => backendBaseUrl.isNotEmpty;
}
