import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LikedYouScreen extends StatelessWidget {
  const LikedYouScreen({super.key});

  static const Color habeshaGold = Color(0xFFD4AF35);
  static const Color backgroundDark = Color(0xFF0A0A0A);
  
  // Logic to determine if we should blur (you can link this to user.isPremium later)
  final bool isPremium = false; 

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("LIKES YOU", style: TextStyle(color: habeshaGold, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('likes')
            .where('to', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final likes = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              childAspectRatio: 0.7, 
              crossAxisSpacing: 15, 
              mainAxisSpacing: 15
            ),
            itemCount: likes.length,
            itemBuilder: (context, index) {
              final fromId = likes[index]['from'];
              return _buildBlurredUserCard(fromId);
            },
          );
        },
      ),
    );
  }

  Widget _buildBlurredUserCard(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snap) {
        if (!snap.hasData) return Container(decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)));
        final user = snap.data!.data() as Map<String, dynamic>;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // 1. The Image
              Positioned.fill(
                child: Image.network(user['profileImageUrl'] ?? "", fit: BoxFit.cover),
              ),
              
              // 2. The Blur Effect (Conditional)
              if (!isPremium)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.black.withOpacity(0.3)),
                  ),
                ),

              // 3. The Info Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPremium ? user['name'] : "Someone new",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        if (!isPremium)
                          const Text("Upgrade to see", style: TextStyle(color: habeshaGold, fontSize: 10)),
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