import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileViewScreen extends StatelessWidget {
  const ProfileViewScreen({super.key});

  static const Color habeshaGold = Color(0xFFD4AF35);
  static const Color backgroundDark = Color(0xFF0A0A0A);
  static const Color surfaceGrey = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: backgroundDark,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: habeshaGold));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("Profile not found", style: TextStyle(color: Colors.white)),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String rawImageUrl = userData['profileImageUrl'] ?? "";
          final String displayImageUrl = rawImageUrl.isNotEmpty ? "$rawImageUrl?tr=w-800" : "";
          
          // Get the new detailed fields
          final bool isVerified = userData['isVerified'] ?? false;
          final String religion = userData['religion'] ?? "Add Religion";
          final String education = userData['education'] ?? "Add Education";
          final String height = userData['height'] ?? "Add Height";
          final String smoking = userData['smoking'] ?? "Add Habit";
          final String jobTitle = userData['jobTitle'] ?? "Professional";

          return CustomScrollView(
            slivers: [
              // HEADER WITH IMAGE
              SliverAppBar(
                expandedHeight: 500,
                backgroundColor: backgroundDark,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      displayImageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: displayImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: surfaceGrey),
                              errorWidget: (context, url, error) => const Icon(Icons.person, size: 100),
                            )
                          : Container(
                              color: surfaceGrey,
                              child: const Icon(Icons.person, size: 100, color: Colors.white10),
                            ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, backgroundDark],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // PROFILE CONTENT
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Edit Button Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${userData['name'] ?? 'Guest'}, ${userData['age'] ?? '??'}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      isVerified ? Icons.verified : Icons.gpp_maybe,
                                      color: isVerified ? Colors.blue : Colors.white24,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isVerified ? "Fayda Verified" : "Not Verified",
                                      style: TextStyle(
                                        color: isVerified ? Colors.blue.shade300 : Colors.white24,
                                        fontSize: 14,
                                        fontWeight: isVerified ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _buildActionCircle(Icons.edit, () => context.push('/profile_edit')),
                        ],
                      ),
                      
                      const SizedBox(height: 25),
                      _buildSectionTitle("PROFESSION"),
                      _buildDetailRow(Icons.work_outline, jobTitle),

                      const SizedBox(height: 25),
                      _buildSectionTitle("ABOUT ME"),
                      Text(
                        userData['bio'] ?? "No bio added yet.",
                        style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                      ),

                      const SizedBox(height: 30),
                      _buildSectionTitle("ESSENTIALS"),
                      const SizedBox(height: 12),
                      
                      // DYNAMIC CHIP GRID
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildChip(Icons.height, height),
                          _buildChip(Icons.church, religion),
                          _buildChip(Icons.school, education),
                          _buildChip(Icons.smoking_rooms, smoking),
                          _buildChip(Icons.flag_outlined, userData['heritage'] ?? "Heritage"),
                        ],
                      ),

                      const SizedBox(height: 50),
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              "Joined 2026",
                              style: TextStyle(color: Colors.white24, fontSize: 12),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () => FirebaseAuth.instance.signOut().then((_) => context.go('/')),
                              child: const Text("Log Out", style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: habeshaGold,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }

  Widget _buildChip(IconData icon, String label) {
    bool isPlaceholder = label.contains("Add");
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPlaceholder ? Colors.white10 : habeshaGold.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isPlaceholder ? Colors.white24 : habeshaGold, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isPlaceholder ? Colors.white24 : Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCircle(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: habeshaGold.withOpacity(0.1),
          border: Border.all(color: habeshaGold.withOpacity(0.5)),
        ),
        child: Icon(icon, color: habeshaGold, size: 24),
      ),
    );
  }
}