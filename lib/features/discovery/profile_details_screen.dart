import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileDetailsScreen extends StatelessWidget {
  final String userId;
  const ProfileDetailsScreen({super.key, required this.userId});

  static const Color habeshaGold = Color(0xFFD4AF35);
  static const Color backgroundDark = Color(0xFF0A0A0A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      // Transparent AppBar to show image behind it
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: CircleAvatar(
          backgroundColor: Colors.black38,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: habeshaGold));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image Header
                Hero(
                  tag: userId, // Match this with the discovery card for a smooth transition
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(data['profileImageUrl'] ?? ''),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${data['name'] ?? 'Anonymous'}, ${data['age'] ?? '??'}",
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${data['heritage'] ?? 'Habesha'} • ${data['religion'] ?? 'General'}",
                        style: const TextStyle(color: habeshaGold, fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const Divider(color: Colors.white12, height: 40),
                      const Text(
                        "About Me",
                        style: TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        data['bio'] ?? "No bio provided yet.",
                        style: const TextStyle(color: Colors.white54, fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 100), // Space for floating buttons
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}