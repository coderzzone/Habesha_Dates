import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';

class ProfileViewScreen extends StatelessWidget {
  const ProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "Profile not found",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String rawImageUrl = userData['profileImageUrl'] ?? "";
          final String displayImageUrl = rawImageUrl.isNotEmpty
              ? "$rawImageUrl?tr=w-800"
              : "";

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
                backgroundColor: AppColors.darkBg,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      displayImageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: displayImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Container(color: AppColors.surface),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.person, size: 100),
                            )
                          : Container(
                              color: AppColors.surface,
                              child: const Icon(
                                Icons.person,
                                size: 100,
                                color: Colors.white10,
                              ),
                            ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, AppColors.darkBg],
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 10.0,
                  ),
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
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      isVerified
                                          ? Icons.verified
                                          : Icons.gpp_maybe,
                                      color: isVerified
                                          ? Colors.blue
                                          : Colors.white24,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isVerified
                                          ? "Fayda Verified"
                                          : "Not Verified",
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: isVerified
                                            ? Colors.blue.shade300
                                            : Colors.white24,
                                        fontWeight: isVerified
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _buildActionCircle(
                            context,
                            Icons.edit,
                            () => context.push('/profile_edit'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),
                      // Stats Row
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('follows')
                            .where('followerId', isEqualTo: currentUserId)
                            .snapshots(),
                        builder: (context, followingSnap) {
                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('follows')
                                .where('followingId', isEqualTo: currentUserId)
                                .snapshots(),
                            builder: (context, followersSnap) {
                              final followingCount =
                                  followingSnap.hasData ? followingSnap.data!.docs.length : 0;
                              final followersCount =
                                  followersSnap.hasData ? followersSnap.data!.docs.length : 0;

                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatColumn("Following", followingCount,
                                        () => context.push('/following')),
                                    Container(width: 1, height: 30, color: Colors.white10),
                                    _buildStatColumn("Followers", followersCount,
                                        () => context.push('/following')),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 25),
                      _buildSectionTitle(context, "PROFESSION"),
                      _buildDetailRow(context, Icons.work_outline, jobTitle),

                      const SizedBox(height: 25),
                      _buildSectionTitle(context, "ABOUT ME"),
                      Text(
                        userData['bio'] ?? "No bio added yet.",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 32),
                      _buildSectionTitle(context, "ESSENTIALS"),
                      const SizedBox(height: 16),

                      // DYNAMIC CHIP GRID
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildChip(Icons.height, height),
                          _buildChip(Icons.church, religion),
                          _buildChip(Icons.school, education),
                          _buildChip(Icons.smoking_rooms, smoking),
                          _buildChip(
                            Icons.flag_outlined,
                            userData['heritage'] ?? "Heritage",
                          ),
                        ],
                      ),

                      const SizedBox(height: 60),
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              "Joined 2026",
                              style: TextStyle(
                                color: Colors.white24,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                                if (context.mounted) {
                                  context.go('/');
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              child: const Text("Log Out"),
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.gold,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 22),
        const SizedBox(width: 12),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildChip(IconData icon, String label) {
    bool isPlaceholder = label.contains("Add");
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaceholder
              ? Colors.white10
              : AppColors.gold.withValues(alpha: 0.25),
        ),
        boxShadow: isPlaceholder ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isPlaceholder ? Colors.white24 : AppColors.gold,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: isPlaceholder ? Colors.white24 : Colors.white,
              fontSize: 14,
              fontWeight: isPlaceholder ? FontWeight.normal : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCircle(BuildContext context, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.gold.withValues(alpha: 0.15),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.1),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.gold, size: 26),
      ),
    );
  }

  Widget _buildStatColumn(String label, int count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
