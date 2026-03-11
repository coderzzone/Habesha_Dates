import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'payment_screen.dart';

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

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _buy(String sku, String label, int amountEtb) async {
    if (_uid.isEmpty) return;
    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            PaymentScreen(sku: sku, title: label, amountEtb: amountEtb),
      ),
    );
    if (paid == true && mounted) {
      Navigator.pop(context, true);
    }
  }

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
          _section('Pay-as-you-go Points'),
          _tile(
            '10 Points - 100 ETB',
            '1 connection = 1 point',
            () => _buy('points_10', '10 points', 100),
          ),
          _tile(
            '25 Points - 225 ETB',
            'Best seller',
            () => _buy('points_25', '25 points', 225),
          ),
          _tile(
            '50 Points - 400 ETB',
            'Highest value',
            () => _buy('points_50', '50 points', 400),
          ),
          const SizedBox(height: 14),
          _section('Subscriptions'),
          _tile(
            'Silver Match - 300 ETB / month',
            '5 free connections/month, unlimited messaging, see likes',
            () => _buy('silver_monthly', 'Silver Match', 300),
          ),
          _tile(
            'Gold Prime - 600 ETB / month',
            '15 free connections, boost, AI icebreakers, verified badge',
            () => _buy('gold_monthly', 'Gold Prime', 600),
          ),
          _tile(
            'Quarterly Gold - 1,600 ETB / quarter',
            '15% discount vs monthly',
            () => _buy('gold_quarterly', 'Quarterly Gold', 1600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Payment provider: Chapa.',
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
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
