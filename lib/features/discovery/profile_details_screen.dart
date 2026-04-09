import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

class ProfileDetailsScreen extends StatefulWidget {
  final String userId;
  const ProfileDetailsScreen({super.key, required this.userId});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  static const Color habeshaGold = Color(0xFFD4AF35);
  static const Color backgroundDark = Color(0xFF0A0A0A);

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? "";

  Future<void> _toggleFollow(bool isFollowing) async {
    if (currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to follow users.")),
      );
      return;
    }

    final followId = "${currentUserId}_${widget.userId}";
    try {
      if (isFollowing) {
        await FirebaseFirestore.instance.collection('follows').doc(followId).delete();
      } else {
        await FirebaseFirestore.instance.collection('follows').doc(followId).set({
          'followerId': currentUserId,
          'followingId': widget.userId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        await _notifyUser(
          toUserId: widget.userId,
          type: 'follow',
          data: {
            'message': 'started following you',
          },
        );
      }
    } catch (e) {
      debugPrint("Follow Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _ensureChatExists(String otherUserId) async {
    List<String> ids = [currentUserId, otherUserId]..sort();
    String chatId = ids.join("_");
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'users': ids,
      'timestamp': FieldValue.serverTimestamp(),
      'lastMessage': "It's a match! Say hello.",
    }, SetOptions(merge: true));
  }

  Future<void> _notifyUser({
    required String toUserId,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    if (currentUserId.isEmpty || toUserId.isEmpty) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(toUserId).get();
      final userData = userDoc.data() ?? {};
      if (userData['notificationsEnabled'] == false) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(toUserId)
          .collection('notifications')
          .add({
        'to': toUserId,
        'from': currentUserId,
        'type': type,
        'data': data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Notification error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black38,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
          ),
        ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: habeshaGold),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: widget.userId,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(
                          data['profileImageUrl'] ?? '',
                        ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    "${data['name'] ?? 'Anonymous'}, ${data['age'] ?? '??'}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                if (data['isVerified'] == true) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.verified, color: Colors.blue, size: 28),
                                ],
                              ],
                            ),
                          ),
                          _buildFollowButton(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${data['heritage'] ?? 'Habesha'} • ${data['religion'] ?? 'General'}",
                        style: const TextStyle(
                          color: habeshaGold,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Divider(color: Colors.white12, height: 40),
                      const Text(
                        "About Me",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        data['bio'] ?? "No bio provided yet.",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 100),
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

  Widget _buildFollowButton() {
    if (currentUserId == widget.userId) return const SizedBox.shrink();

    // Check my follow status
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('follows')
          .doc("${currentUserId}_${widget.userId}")
          .snapshots(),
      builder: (context, myFollowSnap) {
        final bool isFollowing = myFollowSnap.hasData && myFollowSnap.data!.exists;

        // Check if they follow me back
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('follows')
              .doc("${widget.userId}_$currentUserId")
              .snapshots(),
          builder: (context, theirFollowSnap) {
            final bool isFollowedBy =
                theirFollowSnap.hasData && theirFollowSnap.data!.exists;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFollowing && isFollowedBy) ...[
                  IconButton(
                    onPressed: () {
                      List<String> ids = [currentUserId, widget.userId]..sort();
                      String chatId = ids.join("_");
                      _ensureChatExists(widget.userId).then((_) {
                        context.push('/chat_room/$chatId?name=Chat');
                      });
                    },
                    icon: const Icon(Icons.forum_outlined, color: habeshaGold),
                    tooltip: "Message",
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton(
                  onPressed: () => _toggleFollow(isFollowing),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing ? Colors.white10 : habeshaGold,
                    foregroundColor: isFollowing ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: isFollowing
                          ? const BorderSide(color: Colors.white24)
                          : BorderSide.none,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                  child: Text(
                    isFollowing ? "Following" : "Follow",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
