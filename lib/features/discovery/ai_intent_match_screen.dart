import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';

class AiIntentMatchScreen extends StatefulWidget {
  const AiIntentMatchScreen({super.key});

  @override
  State<AiIntentMatchScreen> createState() => _AiIntentMatchScreenState();
}

class _AiIntentMatchScreenState extends State<AiIntentMatchScreen> with SingleTickerProviderStateMixin {
  final List<String> intents = const ['Marriage', 'Long-term', 'Friendship'];
  String selectedIntent = 'Marriage';
  bool _loading = false;
  Map<String, dynamic>? _match;
  int _score = 0;
  List<String> _analysis = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _findMatch() async {
    if (_uid.isEmpty) return;
    setState(() {
      _loading = true;
      _match = null;
      _analysis = [];
    });

    try {
      final meDoc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      final me = meDoc.data() ?? <String, dynamic>{};

      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('users')
          .where('intent', isEqualTo: selectedIntent)
          .limit(20)
          .get();

      if (snap.docs.isEmpty) {
        snap = await FirebaseFirestore.instance.collection('users').limit(20).get();
      }

      int best = -1;
      Map<String, dynamic>? bestUser;
      List<String> bestAnalysis = [];

      for (final doc in snap.docs) {
        if (doc.id == _uid) continue;
        final u = doc.data() as Map<String, dynamic>;
        final result = _calculateCompatibility(me, u, selectedIntent);
        
        if (result.score > best) {
          best = result.score;
          bestUser = {...u, 'uid': doc.id};
          bestAnalysis = result.analysis;
        }
      }

      await Future.delayed(const Duration(seconds: 2)); // Simulate AI thinking time

      if (mounted) {
        if (bestUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No AI match found right now.')));
        } else {
          setState(() {
            _score = best.clamp(65, 99);
            _match = bestUser;
            _analysis = bestAnalysis;
          });
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  _MatchResult _calculateCompatibility(Map<String, dynamic> me, Map<String, dynamic> other, String intent) {
    int score = 50;
    List<String> analysis = ["Habesha heritage match"];

    if ((other['intent'] ?? '') == intent) {
      score += 20;
      analysis.add("Mutual dating intent: $intent");
    }
    if ((other['religion'] ?? '') == (me['religion'] ?? '')) {
      score += 15;
      analysis.add("Shared spiritual values (${me['religion']})");
    }
    if ((other['heritage'] ?? '') == (me['heritage'] ?? '')) {
      score += 10;
      analysis.add("Deep cultural connection (${me['heritage']})");
    }

    final myAge = me['age'] is int ? me['age'] as int : 25;
    final theirAge = other['age'] is int ? other['age'] as int : 25;
    final diff = (myAge - theirAge).abs();
    if (diff < 5) {
      score += 10;
      analysis.add("Ideal age compatibility");
    }

    return _MatchResult(score, analysis);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("AI Matchmaker", style: Theme.of(context).appBarTheme.titleTextStyle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          const Text(
            "Our AI analyzes your cultural heritage, spiritual values, and dating intent to find your most compatible Habesha partner.",
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          _buildIntentSelector(),
          const SizedBox(height: 30),
          _buildActionButton(),
          const SizedBox(height: 40),
          if (_loading) _buildLoadingAnimation(),
          if (_match != null && !_loading) _buildMatchCard(),
        ],
      ),
    );
  }

  Widget _buildIntentSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("I am looking for:", style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: intents.map((intent) {
            bool selected = selectedIntent == intent;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => selectedIntent = intent),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.gold : AppColors.surface,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: selected ? AppColors.gold : Colors.white10),
                  ),
                  child: Center(
                    child: Text(intent, style: TextStyle(color: selected ? Colors.black : Colors.white, fontWeight: selected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      height: 55,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _findMatch,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 8,
          shadowColor: AppColors.gold.withValues(alpha: 0.3),
        ),
        child: const Text("ANALALYZE COMPATIBILITY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildLoadingAnimation() {
    return Center(
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.gold, AppColors.gold.withValues(alpha: 0.5), Colors.transparent]),
                boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 10)],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 50),
            ),
          ),
          const SizedBox(height: 30),
          const Text("AI analyzing data points...", style: TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text("Comparing heritage, values & intent", style: TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildMatchCard() {
    final m = _match!;
    return Column(
      children: [
        const Text("COMPATIBILITY SCORE", style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 12),
        Text("$_score%", style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white10),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: CachedNetworkImageProvider(m['profileImageUrl'] ?? ""),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${m['name'] ?? 'User'}, ${m['age'] ?? '??'}", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text("${m['heritage'] ?? 'Habesha'} • ${m['religion'] ?? 'Values'}", style: const TextStyle(color: AppColors.gold, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: Colors.white10),
              ),
              const Text("AI INSIGHTS", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              ..._analysis.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                    const SizedBox(width: 10),
                    Text(item, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              )),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => context.push('/profile_details/${m['uid']}'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("VIEW FULL PROFILE", style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MatchResult {
  final int score;
  final List<String> analysis;
  _MatchResult(this.score, this.analysis);
}
