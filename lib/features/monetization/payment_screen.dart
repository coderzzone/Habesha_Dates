import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/payment_config.dart';
import '../../core/services/chapa_payment_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    required this.sku,
    required this.title,
    required this.amountEtb,
    super.key,
  });

  final String sku;
  final String title;
  final int amountEtb;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const Color gold = Color(0xFFD4AF35);

  final ChapaPaymentService _chapaService = const ChapaPaymentService();

  bool _loading = false;
  String? _txRef;
  String _status = 'Ready to initialize payment.';

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _startPayment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _loading = true;
      _status = 'Initializing Chapa checkout...';
    });

    try {
      final init = await _chapaService.initializeCheckout(
        uid: user.uid,
        email: user.email ?? 'habesha.payments@gmail.com',
        firstName: user.displayName?.split(' ').first ?? 'Habesha',
        lastName: user.displayName?.split(' ').skip(1).join(' ') ?? 'User',
        phoneNumber: user.phoneNumber ?? '0911111111',
        sku: widget.sku,
        amountEtb: widget.amountEtb,
      );
      _txRef = init.txRef;

      final uri = Uri.parse(init.checkoutUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        setState(() => _status = 'Could not open Chapa checkout page.');
      } else {
        setState(
          () => _status = 'Checkout opened. Complete payment then tap Verify.',
        );
      }
    } catch (e) {
      setState(() => _status = 'Initialize failed: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _verifyPayment() async {
    if (_uid.isEmpty || _txRef == null) return;
    setState(() {
      _loading = true;
      _status = 'Verifying payment...';
    });
    try {
      final verify = await _chapaService.verifyCheckout(
        txRef: _txRef!,
        uid: _uid,
        sku: widget.sku,
      );
      if (!verify.success) {
        setState(() => _status = verify.message);
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment verified and entitlement applied.'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _status = 'Verify failed: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Payment', style: TextStyle(color: gold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.amountEtb} ETB',
              style: const TextStyle(
                color: gold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            Text(_status, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text(
              'Backend: ${PaymentConfig.backendBaseUrl}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            if (_txRef != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                'tx_ref: $_txRef',
                style: const TextStyle(color: Colors.white54),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _startPayment,
                style: ElevatedButton.styleFrom(backgroundColor: gold),
                child: const Text(
                  'Pay with Chapa',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _loading || _txRef == null ? null : _verifyPayment,
                child: const Text('I completed payment, Verify now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
