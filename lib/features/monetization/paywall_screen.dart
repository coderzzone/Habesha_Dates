import 'package:flutter/material.dart';
import 'telebirr_payment_screen.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({
    super.key,
    this.reason = 'Upgrade to continue using premium features.',
  });

  final String reason;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  static const Color gold = Color(0xFFD4AF35);
  static const Color dark = Color(0xFF0A0A0A);
  static const Color card = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Unlock Features', style: TextStyle(color: gold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.reason,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          _section('Manual Payment (Telebirr)'),
          _tile(
            'Pay with Telebirr',
            'Send ETB 300 to 0969526295 and screenshot to @yafnad',
            () => _payWithTelebirr(),
          ),
          const SizedBox(height: 8),
          const Text(
            'After payment, send your Telebirr screenshot to @yafnad for verification.',
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Future<void> _payWithTelebirr() async {
    final success = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const TelebirrPaymentScreen(amount: 300.0), // Use double literal
      ),
    );
    if (success == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(color: gold, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _tile(String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60)),
        trailing: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(backgroundColor: gold),
          child: const Text('Choose', style: TextStyle(color: Colors.black)),
        ),
      ),
    );
  }
}
