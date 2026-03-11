import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AiIntentMatchScreen extends StatefulWidget {
  const AiIntentMatchScreen({super.key});

  @override
  State<AiIntentMatchScreen> createState() => _AiIntentMatchScreenState();
}

class _AiIntentMatchScreenState extends State<AiIntentMatchScreen> {
  static const Color gold = Color(0xFFD4AF35);
  static const Color dark = Color(0xFF0A0A0A);
  static const Color card = Color(0xFF1A1A1A);

  final List<String> intents = const ['Marriage', 'Long-term', 'Friendship'];
  String selectedIntent = 'Marriage';
  bool _loading = false;
  Map<String, dynamic>? _match;
  int _score = 0;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _findMatch() async {
    if (_uid.isEmpty) return;
    setState(() => _loading = true);
    try {
      final meDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .get();
      final me = meDoc.data() ?? <String, dynamic>{};

      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('users')
          .where('intent', isEqualTo: selectedIntent)
          .limit(20)
          .get();
      if (snap.docs.isEmpty) {
        snap = await FirebaseFirestore.instance
            .collection('users')
            .limit(20)
            .get();
      }

      int best = -1;
      Map<String, dynamic>? bestUser;
      String? bestId;
      for (final doc in snap.docs) {
        if (doc.id == _uid) continue;
        final u = doc.data() as Map<String, dynamic>;
        final score = _compatibilityScore(me, u, selectedIntent);
        if (score > best) {
          best = score;
          bestUser = {...u, 'uid': doc.id};
          bestId = doc.id;
        }
      }
      if (!mounted) return;

      if (bestUser == null || bestId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No AI match found right now. Try later.'),
          ),
        );
      } else {
        setState(() {
          _score = best.clamp(60, 99);
          _match = bestUser;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _compatibilityScore(
    Map<String, dynamic> me,
    Map<String, dynamic> other,
    String intent,
  ) {
    int score = 50;
    if ((other['intent'] ?? '') == intent) score += 20;
    if ((other['religion'] ?? '') == (me['religion'] ?? '')) score += 12;
    if ((other['heritage'] ?? '') == (me['heritage'] ?? '')) score += 8;
    final myAge = me['age'] is int
        ? me['age'] as int
        : int.tryParse('${me['age']}') ?? 25;
    final theirAge = other['age'] is int
        ? other['age'] as int
        : int.tryParse('${other['age']}') ?? 25;
    final diff = (myAge - theirAge).abs();
    score += (10 - diff).clamp(0, 10);
    return score;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('AI Matchmaker', style: TextStyle(color: gold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choose your intent and let AI find your strongest match.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            children: intents.map((intent) {
              final selected = selectedIntent == intent;
              return ChoiceChip(
                label: Text(intent),
                selected: selected,
                onSelected: (_) => setState(() => selectedIntent = intent),
                selectedColor: gold,
                backgroundColor: card,
                labelStyle: TextStyle(
                  color: selected ? Colors.black : Colors.white,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _findMatch,
              style: ElevatedButton.styleFrom(backgroundColor: gold),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      'Find AI Match',
                      style: TextStyle(color: Colors.black),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          if (_match != null) _matchCard(context),
        ],
      ),
    );
  }

  Widget _matchCard(BuildContext context) {
    final m = _match!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_score% compatibility',
            style: const TextStyle(color: gold, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${m['name'] ?? 'User'}, ${m['age'] ?? ''}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${m['intent'] ?? selectedIntent} • ${m['heritage'] ?? 'Habesha'}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/profile_details/${m['uid']}'),
              child: const Text('View Match Profile'),
            ),
          ),
        ],
      ),
    );
  }
}
