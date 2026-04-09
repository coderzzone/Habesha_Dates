import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text("Network"),
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: "Following"),
            Tab(text: "Followers"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(isFollowingTab: true),
          _buildUserList(isFollowingTab: false),
        ],
      ),
    );
  }

  Widget _buildUserList({required bool isFollowingTab}) {
    final queryField = isFollowingTab ? 'followerId' : 'followingId';
    final targetField = isFollowingTab ? 'followingId' : 'followerId';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('follows')
          .where(queryField, isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isFollowingTab ? Icons.person_add_outlined : Icons.people_outline,
                  size: 64,
                  color: Colors.white12,
                ),
                const SizedBox(height: 16),
                Text(
                  isFollowingTab ? "You aren't following anyone yet" : "No followers yet",
                  style: const TextStyle(color: Colors.white38),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final followData = docs[index].data() as Map<String, dynamic>;
            final String targetId = followData[targetField];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(targetId).get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData || !userSnap.data!.exists) {
                  return const SizedBox.shrink();
                }

                final user = userSnap.data!.data() as Map<String, dynamic>;
                return InkWell(
                  onTap: () => context.push('/profile_details/$targetId'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(user['profileImageUrl'] ?? ""),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['name'] ?? "Unknown",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${user['age'] ?? '??'} • ${user['heritage'] ?? 'Habesha'}",
                                style: const TextStyle(color: Colors.white38, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        if (isFollowingTab)
                          TextButton(
                            onPressed: () => _unfollow(targetId),
                            child: const Text("Unfollow", style: TextStyle(color: Colors.redAccent)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _unfollow(String targetId) async {
    final followId = "${currentUserId}_$targetId";
    await FirebaseFirestore.instance.collection('follows').doc(followId).delete();
  }
}
