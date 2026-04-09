import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/services/monetization_service.dart';
import '../monetization/paywall_screen.dart';

class LikedYouScreen extends StatefulWidget {
  const LikedYouScreen({super.key});

  @override
  State<LikedYouScreen> createState() => _LikedYouScreenState();
}

class _LikedYouScreenState extends State<LikedYouScreen> {
  static const Color habeshaGold = Color(0xFFD4AF35);
  static const Color backgroundDark = Color(0xFF0A0A0A);

  final MonetizationService _monetizationService = MonetizationService();
  bool _isPremium = false;

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  void _checkPremiumStatus() {
    _monetizationService.monetizationStream.listen((snapshot) {
      if (!mounted || !snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;
      setState(() {
        _isPremium = data['isPremium'] ?? false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "LIKES YOU",
          style: TextStyle(color: habeshaGold, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('likes')
                .where('to', isEqualTo: currentUserId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final likes = snapshot.data!.docs;

              if (likes.isEmpty) {
                return const Center(
                  child: Text(
                    "No likes yet. Keep swiping!",
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: likes.length,
                itemBuilder: (context, index) {
                  final fromId = likes[index]['from'];
                  return _buildUserCard(fromId);
                },
              );
            },
          ),
          if (!_isPremium) _buildPaywallOverlay(),
        ],
      ),
    );
  }

  Widget _buildPaywallOverlay() {
    return Positioned.fill(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, color: habeshaGold, size: 60),
                    const SizedBox(height: 20),
                    const Text(
                      "See Who Liked You!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "This is a premium feature. Upgrade to reveal everyone who expressed interest in you.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaywallScreen(
                              reason: 'Unlock Likes You to see your admirers.',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: habeshaGold,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                      child: const Text(
                        "Upgrade Now",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(20),
            ),
          );
        }
        final user = snap.data!.data() as Map<String, dynamic>;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  user['profileImageUrl'] ?? "",
                  fit: BoxFit.cover,
                ),
              ),
              if (!_isPremium)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isPremium ? user['name'] : "Someone new",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_isPremium)
                          const Text(
                            "Tap to reveal",
                            style: TextStyle(color: habeshaGold, fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
